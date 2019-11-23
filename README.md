# luci-app-adguardhome
复杂的adguardhome的openwrt的luci界面，仍待测试

 - 可以管理网页端口
 - luci更新核心版本
 - dns重定向
 - 自定义bin path
 - 自定义config path
 - 自定义work path
 - 自定义log path
已知问题：
潘多拉固件老旧，不支持shell 的 function，如要使用请安装后手动修改update_core.sh合并函数