#!/bin/sh

. /lib/functions.sh

rulefile=/var/anti.firewall.user

anti_poison_run()
{
echo "iptables -N protectdns" >> $rulefile.tmp 

for ip in $(cat /etc/config/anti-poison)
do
	# ip转为HEX格式
	hexip=$(printf '%02X' ${ip//./ }; echo)
	# 防返回错误IP的投毒
	echo "iptables -I protectdns -m string --algo bm --hex-string \"|$hexip|\" --from 60 --to 500  -j DROP" >> $rulefile.tmp 
done

# 防返回空地址的投毒
echo "iptables -I protectdns -m u32 --u32 \"4 & 0x1FFF = 0 && 0 >> 22 & 0x3C @ 8 & 0x8000 = 0x8000 && 0 >> 22 & 0x3C @ 14 = 0\" -j DROP" >> $rulefile.tmp

# DNS查询都要经过protectdns链
echo "iptables -I INPUT ! -i lo -p udp --sport 53 -j protectdns" >> $rulefile.tmp
echo "iptables -I FORWARD -p udp --sport 53 -j protectdns" >> $rulefile.tmp

if [[ -s $rulefile ]] ; then
        grep -Fvf $rulefile $rulefile.tmp > $rulefile.action
        cat $rulefile.action >> $rulefile
else
        cp $rulefile.tmp $rulefile
        cp $rulefile.tmp $rulefile.action
fi

. $rulefile.action
rm $rulefile.tmp
rm $rulefile.action
}

anti_poison_stop()
{
iptables -D INPUT ! -i lo -p udp --sport 53 -j protectdns 2>/dev/null
iptables -D FORWARD -p udp --sport 53 -j protectdns 2>/dev/null
iptables -F protectdns 2>/dev/null
iptables -X protectdns 2>/dev/null
rm $rulefile
}
