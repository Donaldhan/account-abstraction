
# 引言

![bundle-seq](/image/bundle-seq.svg)   
![ep-handleop-account](/image/ep-handleop-account.webp)     
![bundle-handlerop](/image/bundle-handlerop.png)  

  
![bundle-seq-pm](/image/bundle-seq-pm.svg)   
![ep-handleop-paymaster](/image/ep-handleop-paymaster.webp)  
![bundle-handlerop-pm](/image/bundle-handlerop-pm.png)  

![ep-handleop-deploy-contract](/image/ep-handleop-deploy-contract.webp)
![ep-handleaggeratedop](/image/ep-handleaggeratedop.webp)   

AA好处
1. 社交恢复；私钥丢失，AA账号升级找回账号；
2. gas代付；

# Account abstraction工作流程

![account-abstraction-framework](/image/account-abstraction-framework.png)     


## 概念
* UserOperation: 用户发送的操作：主要包含 “sender”, “to”, “calldata”, “maxFeePerGas”, “maxPriorityFee”, “signature”, “nonce”，“signature”等， 签名协议不定义，有具体的account实现定义，比如EOA用户AA账户签名一般为EDSA，多签AA账户签名，具体以多签机制实现为准，比如BLS等；
* Sender（Account contract）：发送OP的AA账户，可以为EOA绑定的AA账户，也可以是多签账户；
* AccountFactory：创建AA账户的工厂合约
* UserOperation  MemPool：higher-level内存池系统，用户提交的操作，先发送到内存池；
* EntryPoint：执行bundler捆绑的UserOperation；Bundlers/Clients白名单支持EntryPoint；
* Bundler：为处理UserOperation的节点（区块 builder），创建一个有效的EntryPoint.handleOps() 交易，并在他有效之前添加到区块；实现的途径可以两种形式，一种为Bundler自己是区块builder，另外一种是bundler使用区块构建基础设施，比如mev-boost或者 PBS (proposer-builder separation)；
* Paymaster：赞助交易gas合约；
* Aggregator：聚合签名合约，Bundlers/Clients白名单支持aggregators；
* EntryPointSimulations：在Bunlers打包UserOperation和处理UserOperations之前，模拟校验UserOperation和模拟处理UserOperations


## 核心流程



# 合约

<!-- 合约架构图 -->

* BaseAccount：基础账户，提供校验OP；
* BasePaymaster：PayMaster校验op，depoist及质押，解押，提现等操作；
* NonceManager：账户nonce管理；
* StakeManager：账户deposit（pay gas）和stak（bundler）管理；
* SenderCreator：创建账户合约；
* EntryPoint：提供账户nonce，deposit（pay gas）和stak（bundler）管理；支持核心handleOps和handleAggregatedOps操作；

## EntryPoint
* 批量处理OP的两个方法为handleOps和handleAggregatedOps，handleAggregatedOps处理批量聚合签名op；

> handleOps核心执行步骤；
1. 校验所有OP的预付gas信息，并解析校验数据，确保聚合地址及时间没有问题（包含账户和paymaster支付两种形式）；
2. 执行所有OP；在执行的过程中，如果执行revert，则调用payMaster#postOp方法， 并将剩余的gas deposit到EntryPoint；
3. 补偿所有OP执行的gas fee给Bundler的收益地址；

**handleAggregatedOps执行的核心逻辑和handleOps一样，只不过，增加了批量op的签名检查；**

### EntryPointSimulations
* 提供模拟校验UserOperation和模拟处理UserOperations操作，在Bunlers打包UserOperation和处理UserOperations之前，

## Paymaster

1. TokenPaymaster：基于oracle和swap的paymaster
* validatePaymasterUserOp：校验paymaster OP，计算交易需要的token数量，并转账到paymaster；
* postOp：执行post任务，比如更新token价格，退还剩余的token，如果由于gas不足revert，超过preGas的，需要补足gas；如果需要则将token swap为weth，并提现，质押到EP；

## Aggregator
1. BLSSignatureAggregator：基于BLS账户的签名与签名验证聚合器；

**为什么需要聚合签名，减少验证的gas，不用将由打包的UserOperation的签名全部验证一遍，只需要验证最终的聚合签名即可**


TODO 质押信息，为什么要质押？？？


# 总结




# refer
[safe wallet](https://safe.global/wallet) 
[smart-account-overview](https://docs.safe.global/advanced/smart-account-overview)   
[safe-smart-account](https://github.com/Donaldhan/safe-smart-account)  
[ownbit-multisig-contracts](https://github.com/Donaldhan/ownbit-multisig-contracts)    
[account-abstraction](https://github.com/Donaldhan/account-abstraction) 
[]() 
[]() 



[ERC 4337: account abstraction without Ethereum protocol changes](https://medium.com/infinitism/erc-4337-account-abstraction-without-ethereum-protocol-changes-d75c9d94dc4a)    
[eip-4337](https://github.com/ethereum/EIPs/blob/e4519f1e182e5ec49d99022532b54369e8b293e9/EIPS/eip-4337.md)      
[eip-4337](https://eips.ethereum.org/EIPS/eip-4337)    
[EIP-2938: Account Abstraction ](https://eips.ethereum.org/EIPS/eip-2938)     
[EIP-3074: AUTH and AUTHCALL opcodes ](https://eips.ethereum.org/EIPS/eip-3074) 


[ERC 4337 | Account Abstraction 中文詳解](https://medium.com/@alan890104/erc-4337-account-abstraction-37535ff5fe24)  
[分析EIP-4337：以太坊最强账户抽象提案](https://learnblockchain.cn/article/5768)   
[理解账户抽象#1 - 从头设计智能合约钱包](https://learnblockchain.cn/article/5426)   
[理解账户抽象 #2：使用Paymaster赞助交易](https://learnblockchain.cn/article/5432)     
[理解账户抽象 #3 - 钱包创建](https://learnblockchain.cn/article/5442)    
[理解账户抽象 #4：聚合签名](https://learnblockchain.cn/article/5483)   
[解读 EigenLayer 中使用的 BLS 聚合签名](https://learnblockchain.cn/article/7855)    
[BLS签名实现阈值签名的流程](https://learnblockchain.cn/2019/08/29/bls)     
[Schnorr 和 BLS 算法详解丨区块链技术课程 #4](https://learnblockchain.cn/article/8364)     


[EIP-4337](https://www.notion.so/plancker/EIP-4337-0baad80755eb498c81d4651ccb527eb2)       
[深入剖析 Ownbit 和 Gnosis 多签](https://learnblockchain.cn/article/1902)      
[多签钱包的工作原理与使用方式](https://learnblockchain.cn/article/4077)    
[]()    
[]()    
[]()    


