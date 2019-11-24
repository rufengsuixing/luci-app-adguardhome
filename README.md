# luci-app-adguardhome
复杂的adguardhome的openwrt的luci界面

 - 可以管理网页端口
 - luci更新核心版本
 - dns重定向
 - 自定义bin path（支持tmp，每次重启时下载bin）
 - 自定义config path
 - 自定义work path
 - 自定义log path
 - gfwlist 定义上游dns服务器
 - 修改网页登陆密码
#### 已知问题：
 - db数据库不支持放在比较特别的文件系统上比如 overlay data-stk-oo，请修改workdir，本软件如果检测到overlay会自动重定向到tmp，将会导致重启丢失dns数据库
 
#### 项目已经基本稳定，有bug欢迎主动反馈
