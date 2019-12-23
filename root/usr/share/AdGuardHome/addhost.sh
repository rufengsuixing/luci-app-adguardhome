#!/bin/sh
[ "$1" == "del" ] && sed -i '/programaddstart/,/programaddend/d' /etc/hosts && exit 0
/usr/bin/awk 'BEGIN{
while ((getline < "/tmp/dhcp.leases") > 0)
{
    a[$2]=$4;
}
while (("ip -6 neighbor show | grep -v fe80" | getline) > 0)
{
    if (a[$5]) {print $1" "a[$5] >"/tmp/tmphost"; }
}}'
echo "#programaddend" >>/tmp/tmphost
grep programaddstart /etc/hosts
if [ "$?" == "0" ]; then
	sed -i '/programaddstart/,/programaddend/c\#programaddstart' /etc/hosts
	sed -i '/programaddstart/'r/tmp/tmphost /etc/hosts
else
	echo "#programaddstart" >>/etc/hosts
	cat /tmp/tmphost >> /etc/hosts
fi
rm /tmp/tmphost