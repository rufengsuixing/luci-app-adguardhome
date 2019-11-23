require("luci.sys")
require("luci.util")
local fs=require"nixio.fs"
local uci=require"luci.model.uci".cursor()

local configpath=uci:get("AdGuardHome","AdGuardHome","configpath")
if (configpath==nil) then
configpath="/etc/AdGuardHome.yaml"
end
local binpath=uci:get("AdGuardHome","AdGuardHome","binpath")
if (binpath==nil) then
binpath="/usr/bin/AdGuardHome/AdGuardHome"
end
local httpport=luci.sys.exec("awk '/bind_port:/{printf($2)}' "..configpath.." 2>nul")
if (httpport=="") then
httpport=uci:get("AdGuardHome","AdGuardHome","httpport")
end
mp = Map("AdGuardHome", translate("AdGuard Home"))
mp.description = translate("免费和开源，功能强大的全网络广告和跟踪程序拦截DNS服务器")
mp:section(SimpleSection).template  = "AdGuardHome/AdGuardHome_status"

s = mp:section(TypedSection, "AdGuardHome")
s.anonymous=true
s.addremove=false
---- enable
o = s:option(Flag, "enabled", translate("启用广告屏蔽"))
o.default = 0
o.rmempty = false
---- httport
o =s:option(Value,"httpport",translate("网页管理端口(覆盖配置)"))
o.placeholder=3000
o.default=3000
o.datatype="port"
o.rmempty=false
o.description = translate("<input type=\"button\" style=\"width:180px;border-color:Teal; text-align:center;font-weight:bold;color:Green;\" value=\"AdGuardHome Web:"..httpport.."\" onclick=\"window.open('http://'+window.location.hostname+':"..httpport.."/')\"/>")
---- update warning not safe
if fs.access(configpath) then
	e=luci.sys.exec(binpath.." -c "..configpath.." --check-config 2>&1")
	e=string.match(e,'(v%d+\.%d+\.%d+)')
	if (e==nil) then
	e="not found bin"
	end
else
	if fs.access(binpath) then
		maybev=uci:get("AdGuardHome","AdGuardHome","version")
		if (maybev==nil) then
			e=""
		else
			e="not find config"..maybev
		end
	else
		e="not found bin and config"
	end
end

o=s:option(Button,"restart",translate("手动更新"))
o.inputtitle=translate("更新核心版本")
o.template = "AdGuardHome/AdGuardHome_check"
o.description=string.format(translate("目前运行主程序版本").."<strong><font color=\"green\">: %s </font></strong>",e)

---- port warning not safe
local port=luci.sys.exec("awk '/  port:/{printf($2)}' "..configpath.." 2>nul")
if (port=="") then
port="?"
end
---- Redirect
o = s:option(ListValue, "redirect", port..translate("Redirect"), translate("AdGuardHome redirect mode"))
o.placeholder = "none"
o:value("none", translate("none"))
o:value("dnsmasq-upstream", translate("Run as dnsmasq upstream server"))
o:value("redirect", translate("Redirect 53 port to AdGuardHome"))
o.default     = "none"
o.rempty      = false
---- bin path
o = s:option(Value, "binpath", translate("Bin Path"), translate("AdGuardHome Bin path if no bin will auto download"))
o.default     = "/usr/bin/AdGuardHome/AdGuardHome"
o.datatype    = "string"
o.rempty      = false
---- config path
o = s:option(Value, "configpath", translate("Config Path"), translate("AdGuardHome config path"))
o.default     = "/etc/AdGuardHome.yaml"
o.datatype    = "string"
o.rempty      = false
---- work dir
o = s:option(Value, "workdir", translate("Work dir"), translate("AdGuardHome work dir"))
o.default     = "/usr/bin/AdGuardHome"
o.datatype    = "string"
o.rempty      = false
---- log file
o = s:option(Value, "logfile", translate("Log File"), translate("AdGuardHome runtime Log file if 'syslog': write to system log;if empty no log"))
o.default     = ""
o.datatype    = "string"
o.rempty      = false
---- debug
o = s:option(Flag, "verbose", translate("verbose debug"))
o.default = 0
o.rmempty = false

local apply = luci.http.formvalue("cbi.apply")
 if apply then
     io.popen("/etc/init.d/AdGuardHome reload")
end

return mp
