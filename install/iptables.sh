#!/bin/bash

#source /usr/src/fusionpbx-install/intall/config.sh

#send a message
echo "Configuring IPTables"

#defaults to nftables by default this enables iptables
apt-get install -y iptables
update-alternatives --set iptables /usr/sbin/iptables-legacy
update-alternatives --set ip6tables /usr/sbin/ip6tables-legacy

#lets add /usr/sbin to the path
export PATH=/usr/sbin:$PATH

#run iptables commands
iptables -A INPUT -i lo -j ACCEPT
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A INPUT -j DROP -p udp --dport 5060:5091 -m string --string "friendly-scanner" --algo bm --icase
iptables -A INPUT -j DROP -p tcp --dport 5060:5091 -m string --string "friendly-scanner" --algo bm --icase
iptables -A INPUT -j DROP -p udp --dport 5060:5091 -m string --string "sipcli/" --algo bm --icase
iptables -A INPUT -j DROP -p tcp --dport 5060:5091 -m string --string "sipcli/" --algo bm --icase
iptables -A INPUT -j DROP -p udp --dport 5060:5091 -m string --string "VaxSIPUserAgent/" --algo bm --icase
iptables -A INPUT -j DROP -p tcp --dport 5060:5091 -m string --string "VaxSIPUserAgent/" --algo bm --icase
iptables -A INPUT -j DROP -p udp --dport 5060:5091 -m string --string "pplsip" --algo bm --icase
iptables -A INPUT -j DROP -p tcp --dport 5060:5091 -m string --string "pplsip" --algo bm --icase
iptables -A INPUT -j DROP -p udp --dport 5060:5091 -m string --string "system " --algo bm --icase
iptables -A INPUT -j DROP -p tcp --dport 5060:5091 -m string --string "system " --algo bm --icase
iptables -A INPUT -j DROP -p udp --dport 5060:5091 -m string --string "exec." --algo bm --icase
iptables -A INPUT -j DROP -p tcp --dport 5060:5091 -m string --string "exec." --algo bm --icase
iptables -A INPUT -j DROP -p udp --dport 5060:5091 -m string --string "multipart/mixed;boundary" --algo bm --icase
iptables -A INPUT -j DROP -p tcp --dport 5060:5091 -m string --string "multipart/mixed;boundary" --algo bm --icase
iptables -A INPUT -p tcp --dport 22 -j ACCEPT
iptables -A INPUT -p tcp --dport 80 -j ACCEPT
iptables -A INPUT -p tcp --dport 443 -j ACCEPT
iptables -A INPUT -p tcp --dport 7443 -j ACCEPT
iptables -A INPUT -p tcp --dport 5060:5091 -j ACCEPT
iptables -A INPUT -p udp --dport 5060:5091 -j ACCEPT
iptables -A INPUT -p udp --dport 16384:32768 -j ACCEPT

# Adding docker input chain rules
iptables -A INPUT -p tcp --dport 2377 -j ACCEPT
iptables -A INPUT -p tcp --dport 7946 -j ACCEPT
iptables -A INPUT -p tcp --dport 8000 -j ACCEPT
iptables -A INPUT -p tcp --dport 9000 -j ACCEPT
iptables -A INPUT -p tcp --dport 9443 -j ACCEPT
iptables -A INPUT -p tcp --dport 7946 -j ACCEPT
iptables -A INPUT -p udp --dport 7946 -j ACCEPT
#end docker rules

iptables -A INPUT -p icmp --icmp-type echo-request -j ACCEPT
iptables -A INPUT -p udp --dport 1194 -j ACCEPT
iptables -t mangle -A OUTPUT -p udp -m udp --sport 16384:32768 -j DSCP --set-dscp 46
iptables -t mangle -A OUTPUT -p udp -m udp --sport 5060:5091 -j DSCP --set-dscp 26
iptables -t mangle -A OUTPUT -p tcp -m tcp --sport 5060:5091 -j DSCP --set-dscp 26
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT ACCEPT

#answer the questions for iptables persistent
echo "iptables-persistent iptables-persistent/autosave_v4 boolean true" | debconf-set-selections
echo "iptables-persistent iptables-persistent/autosave_v6 boolean true" | debconf-set-selections
apt-get install -y iptables-persistent

#Fail2ban
echo "Installing Fail2ban"
apt-get install -y fail2ban

#move to the correct directory
cd /usr/src/fusionpbx-install/install/

#move the filters
cp fail2ban/freeswitch.conf /etc/fail2ban/filter.d/freeswitch.conf
cp fail2ban/freeswitch-acl.conf /etc/fail2ban/filter.d/freeswitch-acl.conf
cp fail2ban/sip-auth-failure.conf /etc/fail2ban/filter.d/sip-auth-failure.conf
cp fail2ban/sip-auth-challenge.conf /etc/fail2ban/filter.d/sip-auth-challenge.conf
cp fail2ban/auth-challenge-ip.conf /etc/fail2ban/filter.d/auth-challenge-ip.conf
cp fail2ban/freeswitch-ip.conf /etc/fail2ban/filter.d/freeswitch-ip.conf
cp fail2ban/fusionpbx.conf /etc/fail2ban/filter.d/fusionpbx.conf
cp fail2ban/fusionpbx-mac.conf /etc/fail2ban/filter.d/fusionpbx-mac.conf
cp fail2ban/fusionpbx-404.conf /etc/fail2ban/filter.d/fusionpbx-404.conf
cp fail2ban/nginx-404.conf /etc/fail2ban/filter.d/nginx-404.conf
cp fail2ban/nginx-dos.conf /etc/fail2ban/filter.d/nginx-dos.conf
cp fail2ban/jail.local /etc/fail2ban/jail.local

#restart fail2ban
systemctl restart fail2ban
