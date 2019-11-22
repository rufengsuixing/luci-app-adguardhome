module("luci.controller.AdGuardHome",package.seeall)
function index()
if not nixio.fs.access("/etc/config/AdGuardHome")then
return
end
	entry({"admin","services","AdGuardHome"},firstchild(),_("AdGuard Home"),30).dependent=true
	entry({"admin","services","AdGuardHome","general"},cbi("AdGuardHome"),_("Base Setting"),1)
    entry({"admin","services","AdGuardHome","log"},form("AdGuardHomelog"),_("Log"),2)
    entry({"admin","services","AdGuardHome","status"},call("act_status")).leaf=true
end 

function act_status()
  local e={}
  e.running=luci.sys.call("pgrep -f AdGuardHome/AdGuardHome >/dev/null")==0
  luci.http.prepare_content("application/json")
  luci.http.write_json(e)
end