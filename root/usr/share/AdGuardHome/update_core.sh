#!/bin/bash
PATH="/usr/sbin:/usr/bin:/sbin:/bin"
binpath=$(uci get AdGuardHome.AdGuardHome.binpath)
if [ -z "$binpath" ]; then
uci get AdGuardHome.AdGuardHome.binpath="/tmp/AdGuardHome/AdGuardHome"
binpath="/tmp/AdGuardHome/AdGuardHome"
fi
mkdir -p ${binpath%/*}
configpath=$(uci get AdGuardHome.AdGuardHome.configpath)
if [ -z "$configpath" ]; then
uci get AdGuardHome.AdGuardHome.configpath="/etc/AdGuardHome.yaml"
configpath="/etc/AdGuardHome.yaml"
fi
mkdir -p ${configpath%/*}
upx=$(uci get AdGuardHome.AdGuardHome.upx)

check_if_already_running(){
	running_tasks="$(ps |grep "AdGuardHome" |grep "update_core" |grep -v "grep" |awk '{print $1}' |wc -l)"
	[ "${running_tasks}" -gt "2" ] && echo -e "\nA task is already running." >>/tmp/AdGuardHome_update.log && exit 2
}

clean_log(){
	echo "" > /tmp/AdGuardHome_update.log
}

check_latest_version(){
	latest_ver="$(wget -O- https://api.github.com/repos/AdguardTeam/AdGuardHome/releases/latest 2>/dev/null|grep -E 'tag_name' |grep -E 'v[0-9.]+' -o 2>/dev/null)"
	[ -z "${latest_ver}" ] && echo -e "\nFailed to check latest version, please try again later." >>/tmp/AdGuardHome_update.log && exit 1
	if [ -f "$configpath" ]; then
	now_ver="$($binpath -c $configpath --check-config 2>&1| grep -E 'v[0-9.]+' -o)"
	else
	if [ -f "$binpath" ]; then
	now_ver=$(uci get AdGuardHome.AdGuardHome.version)
	fi
	fi
	if [ "${latest_ver}"x != "${now_ver}"x ]; then
		clean_log
		echo -e "Local version: ${now_ver}., cloud version: ${latest_ver}." >>/tmp/AdGuardHome_update.log
		doupdate_core
	else
			echo -e "\nLocal version: ${now_ver}, cloud version: ${latest_ver}." >>/tmp/AdGuardHome_update.log
			echo -e "You're already using the latest version." >>/tmp/AdGuardHome_update.log
			uci set AdGuardHome.AdGuardHome.version="${latest_ver}"
			uci commit AdGuardHome
			exit 3
	fi
}
doupx(){
	case $Archt in
	"i386")
	Arch="i386"
	;;
	"i686")
	Arch="i386"
	echo -e "i686 use $Arch may have bug" >>/tmp/AdGuardHome_update.log
	;;
	"x86")
	Arch="amd64"
	;;
	"mipsel")
	Arch="mipsel"
	;;
	"mips64el")
	Arch="mips64el"
	Arch="mipsel"
	echo -e "mips64el use $Arch may have bug" >>/tmp/AdGuardHome_update.log
	;;
	"mips")
	Arch="mips"
	;;
	"mips64")
	Arch="mips64"
	Arch="mips"
	echo -e "mips64 use $Arch may have bug" >>/tmp/AdGuardHome_update.log
	;;
	"arm")
	Arch="arm"
	;;
	"armeb")
	Arch="armeb"
	;;
	"aarch64")
	Arch="arm64"
	;;
	"powerpc")
	Arch="powerpc"
	;;
	"powerpc64")
	Arch="powerpc64"
	;;
	*)
	echo -e "error not support $Archt" >>/tmp/AdGuardHome_update.log
	exit 1
	;;
	esac
	upx_latest_ver="$(wget -O- https://api.github.com/repos/upx/upx/releases/latest 2>/dev/null|grep -E 'tag_name' |grep -E '[0-9.]+' -o 2>/dev/null)"
	wget-ssl --no-check-certificate -t 1 -T 10 -O  /tmp/upx-${upx_latest_ver}-${Arch}_linux.tar.xz "https://github.com/upx/upx/releases/download/v${upx_latest_ver}/upx-${upx_latest_ver}-${Arch}_linux.tar.xz"  >/dev/null 2>&1
	#tar xvJf
	which xz || (opkg update && opkg install xz) || exit 1
	mkdir -p /tmp/upx-${upx_latest_ver}-${Arch}_linux
	xz -d -c /tmp/upx-${upx_latest_ver}-${Arch}_linux.tar.xz| tar -x -C "/tmp" >/dev/null 2>&1
	rm /tmp/upx-${upx_latest_ver}-${Arch}_linux.tar.xz
}
doupdate_core(){
	echo -e "Updating core..." >>/tmp/AdGuardHome_update.log
	mkdir -p "/tmp/AdGuardHome/update" >/dev/null 2>&1
	rm -rf /tmp/AdGuardHome/update/* >/dev/null 2>&1
	Archt="$(opkg info kernel | grep Architecture | awk -F "[ _]" '{print($2)}')"
	case $Archt in
	"i386")
	Arch="386"
	;;
	"i686")
	Arch="386"
	;;
	"x86")
	Arch="amd64"
	;;
	"mipsel")
	Arch="mipsle"
	;;
	"mips64el")
	Arch="mips64le"
	Arch="mipsle"
	echo -e "mips64el use $Arch may have bug" >>/tmp/AdGuardHome_update.log
	;;
	"mips")
	Arch="mips"
	;;
	"mips64")
	Arch="mips64"
	Arch="mips"
	echo -e "mips64 use $Arch may have bug" >>/tmp/AdGuardHome_update.log
	;;
	"arm")
	Arch="arm"
	;;
	"aarch64")
	Arch="arm64"
	;;
	"powerpc")
	Arch="ppc"
	echo -e "error not support $Archt" >>/tmp/AdGuardHome_update.log
	exit 1
	;;
	"powerpc64")
	Arch="ppc64"
	echo -e "error not support $Archt" >>/tmp/AdGuardHome_update.log
	exit 1
	;;
	*)
	echo -e "error not support $Archt" >>/tmp/AdGuardHome_update.log
	
	exit 1
	;;
	esac
	echo -e "start download ${latest_ver}/AdGuardHome_linux_${Arch}.tar.gz" >>/tmp/AdGuardHome_update.log
	wget-ssl --no-check-certificate -t 1 -T 10 -O  /tmp/AdGuardHome/update/AdGuardHome_linux_${Arch}.tar.gz "https://github.com/AdguardTeam/AdGuardHome/releases/download/${latest_ver}/AdGuardHome_linux_${Arch}.tar.gz"  >/dev/null 2>&1
	tar -zxf "/tmp/AdGuardHome/update/AdGuardHome_linux_${Arch}.tar.gz" -C "/tmp/AdGuardHome/update/" >/dev/null 2>&1
	if [ ! -e "/tmp/AdGuardHome/update/AdGuardHome" ]; then
		echo -e "Failed to download core." >>/tmp/AdGuardHome_update.log
		rm -rf "/tmp/AdGuardHome/update" >/dev/null 2>&1
		exit 1
	else 
		echo -e "download success start copy" >>/tmp/AdGuardHome_update.log
		if [ "$upx"x == "1"x ]; then
		echo -e "start upx may take a log time" >>/tmp/AdGuardHome_update.log
		doupx
        #maybe need chmod
		/tmp/upx-${upx_latest_ver}-${Arch}_linux/upx -9  /tmp/AdGuardHome/update/AdGuardHome/AdGuardHome
		rm -rf /tmp/upx-${upx_latest_ver}-${Arch}_linux
		fi
		echo -e "start copy" >>/tmp/AdGuardHome_update.log
		/etc/init.d/AdGuardHome stop
		rm "$binpath"
		mv -f /tmp/AdGuardHome/update/AdGuardHome/AdGuardHome "$binpath"
		if [ "$?" == "1" ]; then
			echo "mv failed maybe not enough space please use upx or change bin to /tmp/AdGuardHome" >>/tmp/AdGuardHome_update.log
			exit 1
		fi
		/etc/init.d/AdGuardHome restart
	fi
	rm -rf "/tmp/AdGuardHome/update" >/dev/null 2>&1
	echo -e "Succeeded in updating core." >>/tmp/AdGuardHome_update.log
	uci set AdGuardHome.AdGuardHome.version="${latest_ver}"
	uci commit AdGuardHome
	echo -e "Local version: ${now_ver}, cloud version: ${latest_ver}.\n" >>/tmp/AdGuardHome_update.log
}

main(){
	check_if_already_running
	check_latest_version
}
	main
