// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.23;

/* solhint-disable not-rely-on-time */

import "./IOracle.sol";

/// @title Helper functions for dealing with various forms of price feed oracles. 处理不同喂价Oracles
/// @notice Maintains a price cache and updates the current price if needed. 维持当前价格，如果需要，则更新
/// In the best case scenario we have a direct oracle from the token to the native asset. 最好的方法，我们有一个直接token到本地资产的oracle
/// Also support tokens that have no direct price oracle to the native asset. 同时也支持没有直接token到本地资产的oracle；
/// Sometimes oracles provide the price in the opposite direction of what we need in the moment. 有时候，oracle提供我们相反的方向
abstract contract OracleHelper {

    event TokenPriceUpdated(uint256 currentPrice, uint256 previousPrice, uint256 cachedPriceTimestamp);

    uint256 private constant PRICE_DENOMINATOR = 1e26;

    struct OracleHelperConfig {

        /// @notice The price cache will be returned without even fetching the oracles for this number of seconds 价格缓存时间
        uint48 cacheTimeToLive;

        /// @notice The maximum acceptable age of the price oracle round 预言机价格最大age
        uint48 maxOracleRoundAge;

        /// @notice The Oracle contract used to fetch the latest token prices 价格token oralce
        IOracle tokenOracle;

        /// @notice The Oracle contract used to fetch the latest native asset prices. Only needed if tokenToNativeOracle flag is not set.
        /// 本地oracle
        IOracle nativeOracle;

        /// @notice If 'true' we will fetch price directly from tokenOracle
        /// @notice If 'false' we will use nativeOracle to establish a token price through a shared third currency
        bool tokenToNativeOracle;

        /// @notice 'false' if price is bridging-asset-per-token (or native-asset-per-token), 'true' if price is tokens-per-bridging-asset
        bool tokenOracleReverse;

        /// @notice 'false' if price is bridging-asset-per-native-asset, 'true' if price is native-asset-per-bridging-asset
        bool nativeOracleReverse;

        /// @notice The price update threshold percentage from PRICE_DENOMINATOR that triggers a price update (1e26 = 100%) 价格更新百分比
        uint256 priceUpdateThreshold;

    }

    /// @notice The cached token price from the Oracle, always in (native-asset-per-token) * PRICE_DENOMINATOR format 缓冲价格
    uint256 public cachedPrice;

    /// @notice The timestamp of a block when the cached price was updated 缓存价格时间戳
    uint48 public cachedPriceTimestamp;

    OracleHelperConfig private oracleHelperConfig;

    /// @notice The "10^(tokenOracle.decimals)" value used for the price calculation
    uint128 private tokenOracleDecimalPower;

    /// @notice The "10^(nativeOracle.decimals)" value used for the price calculation
    uint128 private nativeOracleDecimalPower;

    constructor (
        OracleHelperConfig memory _oracleHelperConfig
    ) {
        cachedPrice = type(uint256).max; // initialize the storage slot to invalid value
        _setOracleConfiguration(
            _oracleHelperConfig
        );
    }

    function _setOracleConfiguration(
        OracleHelperConfig memory _oracleHelperConfig
    ) private {
        oracleHelperConfig = _oracleHelperConfig;
        require(_oracleHelperConfig.priceUpdateThreshold <= PRICE_DENOMINATOR, "TPM: update threshold too high");
        tokenOracleDecimalPower = uint128(10 ** oracleHelperConfig.tokenOracle.decimals());
        if (oracleHelperConfig.tokenToNativeOracle) {
            require(address(oracleHelperConfig.nativeOracle) == address(0), "TPM: native oracle must be zero");
            nativeOracleDecimalPower = 1;
        } else {
            nativeOracleDecimalPower = uint128(10 ** oracleHelperConfig.nativeOracle.decimals());
        }
    }

    /// @notice Updates the token price by fetching the latest price from the Oracle. 更新价格
    /// @param force true to force cache update, even if called after short time or the change is lower than the update threshold.
    /// @return newPrice the new cached token price
    function updateCachedPrice(bool force) public returns (uint256) {
        uint256 cacheTimeToLive = oracleHelperConfig.cacheTimeToLive;
        uint256 cacheAge = block.timestamp - cachedPriceTimestamp;
        if (!force && cacheAge <= cacheTimeToLive) {
            return cachedPrice;
        }
        uint256 priceUpdateThreshold = oracleHelperConfig.priceUpdateThreshold;
        IOracle tokenOracle = oracleHelperConfig.tokenOracle;
        IOracle nativeOracle = oracleHelperConfig.nativeOracle;

        uint256 _cachedPrice = cachedPrice;
        //抓取token价格
        uint256 tokenPrice = fetchPrice(tokenOracle);
        uint256 nativeAssetPrice = 1;
        // If the 'TokenOracle' returns the price in the native asset units there is no need to fetch native asset price
        // 如果token oracle 返回的为以原生代币资产单元对应的价格，则不需要抓取原生资产价格；
        if (!oracleHelperConfig.tokenToNativeOracle) {
            nativeAssetPrice = fetchPrice(nativeOracle);
        }
        uint256 newPrice = calculatePrice(
            tokenPrice,
            nativeAssetPrice,
            oracleHelperConfig.tokenOracleReverse,
            oracleHelperConfig.nativeOracleReverse
        );
        uint256 priceRatio = PRICE_DENOMINATOR * newPrice / _cachedPrice;
        bool updateRequired = force ||
            priceRatio > PRICE_DENOMINATOR + priceUpdateThreshold ||
            priceRatio < PRICE_DENOMINATOR - priceUpdateThreshold;
        if (!updateRequired) {
            return _cachedPrice;
        }
        cachedPrice = newPrice;
        cachedPriceTimestamp = uint48(block.timestamp);
        emit TokenPriceUpdated(newPrice, _cachedPrice, cachedPriceTimestamp);
        return newPrice;
    }

    /**
     * Calculate the effective price of the selected token denominated in native asset.
     * 计算有效价格
     * @param tokenPrice - the price of the token relative to a native asset or a bridging asset like the U.S. dollar.
     * @param nativeAssetPrice - the price of the native asset relative to a bridging asset or 1 if no bridging needed.
     * @param tokenOracleReverse - flag indicating direction of the "tokenPrice".
     * @param nativeOracleReverse - flag indicating direction of the "nativeAssetPrice".
     * @return the native-asset-per-token price multiplied by the PRICE_DENOMINATOR constant.
     */
    function calculatePrice(
        uint256 tokenPrice,
        uint256 nativeAssetPrice,
        bool tokenOracleReverse,
        bool nativeOracleReverse
    ) private view returns (uint256){
        // tokenPrice is normalized as bridging-asset-per-token
        if (tokenOracleReverse) {
            // inverting tokenPrice that was tokens-per-bridging-asset (or tokens-per-native-asset)
            tokenPrice = PRICE_DENOMINATOR * tokenOracleDecimalPower / tokenPrice;
        } else {
            // tokenPrice already bridging-asset-per-token (or native-asset-per-token)
            tokenPrice = PRICE_DENOMINATOR * tokenPrice / tokenOracleDecimalPower;
        }

        if (nativeOracleReverse) {
            // multiplying by nativeAssetPrice that is native-asset-per-bridging-asset
            // => result = (bridging-asset / token) * (native-asset / bridging-asset) = native-asset / token
            return nativeAssetPrice * tokenPrice / nativeOracleDecimalPower;
        } else {
            // dividing by nativeAssetPrice that is bridging-asset-per-native-asset
            // => result = (bridging-asset / token) / (bridging-asset / native-asset) = native-asset / token
            return tokenPrice * nativeOracleDecimalPower / nativeAssetPrice;
        }
    }

    /// @notice Fetches the latest price from the given Oracle. 抓取最近oracle的价格；
    /// @dev This function is used to get the latest price from the tokenOracle or nativeOracle.
    /// @param _oracle The Oracle contract to fetch the price from.
    /// @return price The latest price fetched from the Oracle.
    function fetchPrice(IOracle _oracle) internal view returns (uint256 price) {
        (uint80 roundId, int256 answer,, uint256 updatedAt, uint80 answeredInRound) = _oracle.latestRoundData();
        require(answer > 0, "TPM: Chainlink price <= 0");
        require(updatedAt >= block.timestamp - oracleHelperConfig.maxOracleRoundAge, "TPM: Incomplete round");
        require(answeredInRound >= roundId, "TPM: Stale price");
        price = uint256(answer);
    }
}
