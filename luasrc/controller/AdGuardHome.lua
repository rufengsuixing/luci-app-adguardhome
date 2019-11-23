module("luci.controller.AdGuardHome",package.seeall)
io     = require "io"
fs=require"nixio.fs"
function index()
if not fs.access("/etc/config/AdGuardHome")then
return
end
	entry({"admin","services","AdGuardHome"},firstchild(),_("AdGuard Home"),30).dependent=true
	entry({"admin","services","AdGuardHome","general"},cbi("AdGuardHome"),_("Base Setting"),1)
    entry({"admin","services","AdGuardHome","log"},form("AdGuardHomelog"),_("Log"),2)
    entry({"admin","services","AdGuardHome","status"},call("act_status")).leaf=true
	entry({"admin", "services", "AdGuardHome", "check"}, call("check_update"))
	entry({"admin", "services", "AdGuardHome", "doupdate"}, call("do_update"))
end 

function act_status()
  local e={}
  e.running=luci.sys.call("pgrep -f AdGuardHome >/dev/null")==0
  luci.http.prepare_content("application/json")
  luci.http.write_json(e)
end
function do_update()
luci.sys.exec("sh /usr/share/AdGuardHome/update_core.sh &")
luci.http.prepare_content("application/json")
luci.http.write('')
end
function check_update()
luci.http.prepare_content("text/plain; charset=utf-8")
if fs.access("/var/run/update_core") then
	a=luci.sys.exec("sed -i -e '{w /tmp/tmp.txt' -e 'd}' /tmp/AdGuardHome_update.log && cat /tmp/tmp.txt && rm /tmp/tmp.txt") 
	luci.http.write(a)
else
	if fs.access("/tmp/AdGuardHome_update.log") then
		a=luci.sys.exec("cat /tmp/AdGuardHome_update.log && rm /tmp/AdGuardHome_update.log")
		if (a~="") then
			luci.http.write(a)
		else
			luci.http.write("tingzhitongbu")
		end
	else
		luci.http.write("tingzhitongbu")
	end
end
end