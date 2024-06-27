
# 核心流程

1. 捆绑、处理用户操作
![bundle-seq](/image/account-abstraction/bundle-seq.svg)   
![ep-handleop-account](/image/account-abstraction/ep-handleop-account.webp)     
![bundle-handlerop](/image/account-abstraction/bundle-handlerop.png)  

* 创建AA账户
![ep-handleop-deploy-contract](/image/account-abstraction/ep-handleop-deploy-contract.webp)  


* PayMaster  
![bundle-seq-pm](/image/account-abstraction/bundle-seq-pm.svg)   
![ep-handleop-paymaster](/image/account-abstraction/ep-handleop-paymaster.webp)  
![bundle-handlerop-pm](/image/account-abstraction/bundle-handlerop-pm.png)    

* 多签操作处理
![ep-handleaggeratedop](/image/account-abstraction/ep-handleaggeratedop.webp)   



# design

* BaseAccount：基础账户，提供校验OP；
* BasePaymaster：PayMaster校验op，depoist及质押，解押，提现等操作；
* NonceManager：账户nonce管理；
* StakeManager：账户deposit（pay gas）和stak（bundler）管理；
* SenderCreator：创建账户合约；
* EntryPoint：提供账户nonce，deposit（pay gas）和stak（bundler）管理；支持核心handleOps和handleAggregatedOps操作；

## EntryPoint
* 批量处理OP的两个方法为handleOps和handleAggregatedOps，handleAggregatedOps支持对batch op的聚合签名；

> handleOps核心执行步骤；
1. 校验所有OP的预付gas信息，并解析校验数据，确保聚合地址及时间没有问题（包含账户和paymaster支付两种形式）；
2. 执行所有OP；在执行的过程中，非EntryPoint内部错误PostOpMode.postOpReverte（opSucceeded：执行成功，opReverted：实际执行revert），需要返还支付预付金
3. 待处理完所有UserOperation，补偿消耗的gas费给Bundler；

**handleAggregatedOps执行的核心逻辑和handleOps一样，只不过，增加了批量op的签名检查；**

## Paymaster

> TokenPaymaster：基于oracle和swap实现；关键功能如下：
1. validatePaymasterUserOp：将所需要支付的gas等价的token从OP发送者转账到paymaster；
2. postOp：更新token价格，如果由于gas预付资金不足，发送者需要补足gas预发金，充盈的情况下，退还多余预付金；最后如果Paymaster预付金不足，则需要将token转换原生币，deposit到EntryPoint；


## Aggregator
1. BLSSignatureAggregator：基于BLS账户的签名与签名验证聚合器；








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


