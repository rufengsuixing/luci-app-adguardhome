#!/bin/bash
PATH="/usr/sbin:/usr/bin:/sbin:/bin"
touch /var/run/update_core
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

check_if_already_running(){
	running_tasks="$(ps |grep "AdGuardHome" |grep "update_core" |grep -v "grep" |awk '{print $1}' |wc -l)"
	[ "${running_tasks}" -gt "2" ] && echo -e "\nA task is already running." >>/tmp/AdGuardHome_update.log && rm /var/run/update_core && exit 2
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
			rm /var/run/update_core
			exit 3
	fi
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
	"x86")
	Arch="amd64"
	;;
	"mipsel")
	Arch="mipsle"
	;;
	"mips")
	Arch="mips"
	;;
	"arm")
	Arch="arm"
	;;
	"ram64")
	Arch="arm64"
	;;
	"aarch64")
	Arch="arm64"
	;;
	*)
	echo -e "error not support $Archt" >>/tmp/AdGuardHome_update.log
	rm /var/run/update_core
	exit 1
	;;
	esac
	wget-ssl --no-check-certificate -t 1 -T 10 -O  /tmp/AdGuardHome/update/AdGuardHome_linux_${Arch}.tar.gz "https://github.com/AdguardTeam/AdGuardHome/releases/download/${latest_ver}/AdGuardHome_linux_${Arch}.tar.gz"  >/dev/null 2>&1
	tar -zxf "/tmp/AdGuardHome/update/AdGuardHome_linux_${Arch}.tar.gz" -C "/tmp/AdGuardHome/update/" >/dev/null 2>&1
	
	if [ ! -e "/tmp/AdGuardHome/update/AdGuardHome" ]; then
		echo -e "Failed to download core." >>/tmp/AdGuardHome_update.log
		rm -rf "/tmp/AdGuardHome/update" >/dev/null 2>&1
		rm /var/run/update_core
		exit 1
	else
		if [ "$(uci get AdGuardHome.AdGuardHome.lessspace)"x != "1"x ]; then
		cp -f /tmp/AdGuardHome/update/AdGuardHome/AdGuardHome "$binpath"
			if [ "$?" == "1" ]; then
				echo cp failed maybe not enough space try to kill and cp
				/etc/init.d/AdGuardHome stop
				cp -f /tmp/AdGuardHome/update/AdGuardHome/AdGuardHome "$binpath"
				if [ "$?" == "0" ]; then
					uci set AdGuardHome.AdGuardHome.lessspace="1"
				else
					echo "cp failed" >>/tmp/AdGuardHome_update.log
					rm /var/run/update_core
					exit 1
				fi
			fi
		else
		    /etc/init.d/AdGuardHome stop
			cp -f /tmp/AdGuardHome/update/AdGuardHome/AdGuardHome "$binpath"
			if [ "$?" != "0" ]; then
				echo "cp failed" >>/tmp/AdGuardHome_update.log
				rm /var/run/update_core
				exit 1
			fi
		fi
		[ "${luci_update}" == "y" ] && touch "/tmp/AdGuardHome/update_successfully"
		/etc/init.d/AdGuardHome restart
	fi
	rm -rf "/tmp/AdGuardHome/update" >/dev/null 2>&1
	echo -e "Succeeded in updating core." >>/tmp/AdGuardHome_update.log
	uci set AdGuardHome.AdGuardHome.version="${latest_ver}"
	echo -e "Local version: ${now_ver}, cloud version: ${latest_ver}.\n" >>/tmp/AdGuardHome_update.log
	rm /var/run/update_core
}

main(){
	check_if_already_running
	check_latest_version
}
	main
