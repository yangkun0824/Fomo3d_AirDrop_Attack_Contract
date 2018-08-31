# Fomo3d AirDrop Attack Contract

Fomo3d空投攻击合约管理器

根据空投漏洞来获取ETH

这是一个合约管理器，调用此合约完成对类似FOMO3d游戏的空投攻击。

参考了安比实验室的文章实现  

https://mp.weixin.qq.com/s/YBG8YyPwh374HbGWcUKTdQ

## 合约结构

主管理合约  

Fomo3dAirDropManageContract

子合约 （需要部署合约完成后，不断调用主管理合约的 addChild方法进行创建 ） 

Fomo3dAirDropChildContract

空投攻击合约 （攻击完成后销毁）  

Fomo3dAirDropAttackContract


## 使用帮助

1. 部署管理合约

2. 调用addChild方法子合约

3. 调用管理合约的checkAndAttack方法。


## Contact Author

如有任何问题，请联系我，我创建了一个技术讨论群，欢迎加入

微信: yangkun0824  

Email: yangkun0824@gmail.com
