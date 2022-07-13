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

#send a message
verbose "Configuring IPTables"

#defaults to nftables by default this enables iptables
apt-get install -y iptables
update-alternatives --set iptables /usr/sbin/iptables-legacy
update-alternatives --set ip6tables /usr/sbin/ip6tables-legacy



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
echo iptables-persistent iptables-persistent/autosave_v4 boolean true | debconf-set-selections
echo iptables-persistent iptables-persistent/autosave_v6 boolean true | debconf-set-selections
apt-get install -y iptables-persistent

read -p "IPTables installation complete, check output for any errors."
clear

#sngrep
apt-get install -y sngrep
read -p "sngrep installation complete, check output for any errors."
clear

#FusionPBX
#send a message
verbose "Installing FusionPBX"

#install dependencies
apt-get install -y vim git dbus haveged ssl-cert qrencode
apt-get install -y ghostscript libtiff5-dev libtiff-tools at

#pause to verify installation
read -p "FusionPBX dependencies installed, check for errors."

#get the branch
if [ .$system_branch = .'master' ]; then
	verbose "Using master"
	branch=""
else
	system_major=$(git ls-remote --heads https://github.com/fusionpbx/fusionpbx.git | cut -d/ -f 3 | grep -P '^\d+\.\d+' | sort | tail -n 1 | cut -d. -f1)
	system_minor=$(git ls-remote --tags https://github.com/fusionpbx/fusionpbx.git $system_major.* | cut -d/ -f3 |  grep -P '^\d+\.\d+' | sort | tail -n 1 | cut -d. -f2)
	system_version=$system_major.$system_minor
	verbose "Using version $system_version"
	branch="-b $system_version"
fi

#add the cache directory
mkdir -p /var/cache/fusionpbx
chown -R www-data:www-data /var/cache/fusionpbx

#get the source code
git clone $branch https://github.com/fusionpbx/fusionpbx.git /var/www/fusionpbx
chown -R www-data:www-data /var/www/fusionpbx

#PHP
#send a message
verbose "Configuring PHP"

#set php version
php_version=7.4


#install dependencies
apt-get install -y nginx
apt-get install -y php7.4 php7.4-cli php7.4-dev php7.4-fpm php7.4-pgsql php7.4-sqlite3 php7.4-odbc php7.4-curl php7.4-imap php7.4-xml php7.4-gd php7.4-mbstring


#update config if source is being used
php_ini_file='/etc/php/7.4/fpm/php.ini'

sed 's#post_max_size = .*#post_max_size = 80M#g' -i $php_ini_file
sed 's#upload_max_filesize = .*#upload_max_filesize = 80M#g' -i $php_ini_file
sed 's#;max_input_vars = .*#max_input_vars = 8000#g' -i $php_ini_file
sed 's#; max_input_vars = .*#max_input_vars = 8000#g' -i $php_ini_file

#install ioncube
apt-get install -y unzip
#get the ioncube 64 bit loader
wget --no-check-certificate https://downloads.ioncube.com/loader_downloads/ioncube_loaders_lin_x86-64.zip
#uncompress the file
unzip ioncube_loaders_lin_x86-64.zip
#remove the zip file
rm ioncube_loaders_lin_x86-64.zip
#copy the php extension .so into the php lib directory
cp ioncube/ioncube_loader_lin_7.4.so /usr/lib/php/20190902
#add the 00-ioncube.ini file
echo "zend_extension = /usr/lib/php/20190902/ioncube_loader_lin_7.4.so" > /etc/php/7.4/fpm/conf.d/00-ioncube.ini
echo "zend_extension = /usr/lib/php/20190902/ioncube_loader_lin_7.4.so" > /etc/php/7.4/cli/conf.d/00-ioncube.ini
#restart the service
service php7.4-fpm restart
#ioncube install complete

#restart php-fpm
systemctl daemon-reload
systemctl restart php7.4-fpm

read -p "PHP installation complete, check for errors."

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
