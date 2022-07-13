#!/bin/sh

# pinning the current working directory so we can hop back to it when needed
CWD=$(pwd)

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
#send a message
verbose "configuring the web server"


#enable fusionpbx nginx config
cp nginx/fusionpbx /etc/nginx/sites-available/fusionpbx

#prepare socket name
sed -i /etc/nginx/sites-available/fusionpbx -e 's#unix:.*;#unix:/var/run/php/php7.4-fpm.sock;#g'

ln -s /etc/nginx/sites-available/fusionpbx /etc/nginx/sites-enabled/fusionpbx

#self signed certificate
ln -s /etc/ssl/private/ssl-cert-snakeoil.key /etc/ssl/private/nginx.key
ln -s /etc/ssl/certs/ssl-cert-snakeoil.pem /etc/ssl/certs/nginx.crt

#remove the default site
rm /etc/nginx/sites-enabled/default

#add the letsencrypt directory
if [ .$letsencrypt_folder = .true ]; then
        mkdir -p /var/www/letsencrypt/
fi

#flush systemd cache
systemctl daemon-reload

#restart nginx
service nginx restart

read -p "web server configured, check for errors."

#FreeSWITCH

verbose " beginning source install of FreeSWITCH"

# apt dependency installation
apt install -y autoconf automake devscripts g++ git-core libncurses5-dev libtool make libjpeg-dev
apt install -y pkg-config flac  libgdbm-dev libdb-dev gettext sudo equivs mlocate git dpkg-dev libpq-dev
apt install -y liblua5.2-dev libtiff5-dev libperl-dev libcurl4-openssl-dev libsqlite3-dev libpcre3-dev
apt install -y devscripts libspeexdsp-dev libspeex-dev libldns-dev libedit-dev libopus-dev libmemcached-dev
apt install -y libshout3-dev libmpg123-dev libmp3lame-dev yasm nasm libsndfile1-dev libuv1-dev libvpx-dev
apt install -y libvpx6 swig4.0
apt install -y sqlite3
apt install -y cmake uuid-dev

read -p "check the logs and make sure that nothing had issues installing"
clear

# Start of the source builds, lots of checks here

verbose "building libks"
# libks
cd /usr/src
git clone https://github.com/signalwire/libks.git libks
cd libks
cmake .
make
make install
# libks C includes
export C_INCLUDE_PATH=/usr/include/libks

read -p "libks installed, check for build errors."
clear

verbose "building Sofia"
# sofia-sip
cd /usr/src
#git clone https://github.com/freeswitch/sofia-sip.git sofia-sip
wget https://github.com/freeswitch/sofia-sip/archive/refs/tags/v$sofia_version.zip
unzip v$sofia_version.zip
rm -R sofia-sip
mv sofia-sip-$sofia_version sofia-sip
cd sofia-sip
sh autogen.sh
./configure
make
make install

read -p "Sofia installed, check for build errors."
clear

verbose "building SpanDSP"
# spandsp
cd /usr/src
git clone https://github.com/freeswitch/spandsp.git spandsp
cd spandsp
sh autogen.sh
./configure
make
make install
ldconfig

read -p "SpanDSP installed, check for build errors."
clear

echo "Using FreeSWITCH version $switch_version"
cd /usr/src
wget http://files.freeswitch.org/freeswitch-releases/freeswitch-$switch_version.-release.zip
unzip freeswitch-$switch_version.-release.zip
rm -R freeswitch
mv freeswitch-$switch_version.-release freeswitch
cd /usr/src/freeswitch


#apply patch
patch -u /usr/src/freeswitch/src/mod/databases/mod_pgsql/mod_pgsql.c -i /usr/src/fusionpbx-install.sh/debian/resources/switch/source/mod_pgsql.patch


# enable required modules
sed -i /usr/src/freeswitch/modules.conf -e s:'#applications/mod_av:formats/mod_av:'
sed -i /usr/src/freeswitch/modules.conf -e s:'#applications/mod_callcenter:applications/mod_callcenter:'
sed -i /usr/src/freeswitch/modules.conf -e s:'#applications/mod_cidlookup:applications/mod_cidlookup:'
sed -i /usr/src/freeswitch/modules.conf -e s:'#applications/mod_memcache:applications/mod_memcache:'
sed -i /usr/src/freeswitch/modules.conf -e s:'#applications/mod_nibblebill:applications/mod_nibblebill:'
sed -i /usr/src/freeswitch/modules.conf -e s:'#applications/mod_curl:applications/mod_curl:'
sed -i /usr/src/freeswitch/modules.conf -e s:'#formats/mod_shout:formats/mod_shout:'
sed -i /usr/src/freeswitch/modules.conf -e s:'#formats/mod_pgsql:formats/mod_pgsql:'
sed -i /usr/src/freeswitch/modules.conf -e s:'#say/mod_say_es:say/mod_say_es:'
sed -i /usr/src/freeswitch/modules.conf -e s:'#say/mod_say_fr:say/mod_say_fr:'

#disable module or install dependency libks to compile signalwire
sed -i /usr/src/freeswitch/modules.conf -e s:'applications/mod_signalwire:#applications/mod_signalwire:'
sed -i /usr/src/freeswitch/modules.conf -e s:'endpoints/mod_skinny:#endpoints/mod_skinny:'
sed -i /usr/src/freeswitch/modules.conf -e s:'endpoints/mod_verto:#endpoints/mod_verto:'

# prepare the build
./configure -C --enable-portable-binary --disable-dependency-tracking --prefix=/usr --localstatedir=/var --sysconfdir=/etc --with-openssl --enable-core-pgsql-support

# compile and install
make
make install
make sounds-install moh-install
make hd-sounds-install hd-moh-install
make cd-sounds-install cd-moh-install

#move the music into music/default directory
mkdir -p /usr/share/freeswitch/sounds/music/default
mv /usr/share/freeswitch/sounds/music/*000 /usr/share/freeswitch/sounds/music/default

read -p "FreeSWITCH installation completem check for errors."

#return to the executing directory
cd $CWD
clear

#Fail2ban
resources/fail2ban.sh

#Postgres
resources/postgresql.sh

#set the ip address
server_address=$(hostname -I)

#add the database schema, user and groups
resources/finish.sh
