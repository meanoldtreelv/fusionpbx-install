#!/bin/sh

#upgrade the packages
apt-get update && apt-get upgrade -y

#install packages
apt-get install -y git lsb-release

#get the install script
cd /usr/src && git clone https://github.com/meanoldtreelv/fusionpbx-install.sh.git

#change the working directory
cd /usr/src/fusionpbx-install.sh/debian

#includes
. ./resources/config.sh
. ./resources/colors.sh
. ./resources/environment.sh

# removes the cd img from the /etc/apt/sources.list file (not needed after base install)
sed -i '/cdrom:/d' /etc/apt/sources.list

#Update to latest packages
verbose "Update installed packages"
apt-get update && apt-get upgrade -y

#Add dependencies
apt-get install -y wget
apt-get install -y lsb-release
apt-get install -y systemd
apt-get install -y systemd-sysv
apt-get install -y ca-certificates
apt-get install -y dialog
apt-get install -y nano
apt-get install -y net-tools

#SNMP
apt-get install -y snmpd
echo "rocommunity public" > /etc/snmp/snmpd.conf
service snmpd restart

read -p "Prerequisites installed, press [Enter] to proceed with installation."
clear

#IPTables
resources/iptables.sh
read -p "IPTables installation complete, check output for any errors."
clear

#sngrep
resources/sngrep.sh


#FusionPBX
resources/fusionpbx.sh

#PHP
resources/php.sh

#NGINX web server
resources/nginx.sh

#FreeSWITCH
resources/switch.sh

#Fail2ban
resources/fail2ban.sh

#Postgres
resources/postgresql.sh

#set the ip address
server_address=$(hostname -I)

#add the database schema, user and groups
resources/finish.sh
