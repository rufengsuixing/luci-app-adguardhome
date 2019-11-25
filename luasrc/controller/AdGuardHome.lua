module("luci.controller.AdGuardHome",package.seeall)
nixio=require"nixio"
function index()
if not nixio.fs.access("/etc/config/AdGuardHome")then
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
nixio.fs.writefile("/var/run/lucilogpos","0")
nixio.fs.writefile("/tmp/AdGuardHome_update.log","")
luci.sys.exec("(touch /var/run/update_core ; sh /usr/share/AdGuardHome/update_core.sh ;rm /var/run/update_core) &")
luci.http.prepare_content("application/json")
luci.http.write('')
end
function check_update()
	luci.http.prepare_content("text/plain; charset=utf-8")
	fdp=tonumber(nixio.fs.readfile("/var/run/lucilogpos"))
	f=io.open("/tmp/AdGuardHome_update.log", "r+")
	f:seek("set",fdp)
	a=f:read(8192)
	if (a==nil) then
	a=""
	end
	fdp=f:seek()
	nixio.fs.writefile("/var/run/lucilogpos",tostring(fdp))
	f:close()
if nixio.fs.access("/var/run/update_core") then
	luci.http.write(a)
else
	luci.http.write(a.."\0")
end
end