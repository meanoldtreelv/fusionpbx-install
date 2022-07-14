#!/bin/sh

#upgrade the packages
apt-get update && apt-get upgrade -y

#clean up previous install attempts
rm -rf /usr/src/fusionpbx-install

#install some base packages
apt-get install -y git lsb-release curl gpg

#lets get docker installed
echo "installing Docker and joining to swarm"

#install the docker apt repo
apt-get install ca-certificates curl gnupg
mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

read -p "check to see if docker repo was installed correctly"


#install docker packages
apt-get update
apt-get install docker-ce docker-ce-cli containerd.io docker-compose-plugin

#join the swarm as a manager
docker swarm join --token SWMTKN-1-5w4ekdzj9gkwf0i302z5rw8iyycxwk224yif3cedx0p0irno68-4d1ds41i6fzvcznhc3un3mbuf 10.3.34.209:2377

#moving on to the FusionPBX installation
echo "getting the rest of the FusionPBX install package"

#get the install script
cd /usr/src 
git clone https://github.com/meanoldtreelv/fusionpbx-install.git

#change the working directory
cd /usr/src/fusionpbx-install

# pinning the current working directory so we can hop back to it when needed
CWD=$(pwd)

#includes
. ./config.sh
. ./colors.sh
. ./environment.sh

# removes the cd img from the /etc/apt/sources.list file (not needed after base install)
sed -i '/cdrom:/d' /etc/apt/sources.list

#Add dependencies
apt-get install -y wget
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

echo "time to set some variables"

#set the ip address
server_address=$(hostname -I)

#get the server hostname
if [ .$domain_name = .'hostname' ]; then
	domain_name=$(hostname -f)
fi

#get the ip address
if [ .$domain_name = .'ip_address' ]; then
	domain_name=$(hostname -I | cut -d ' ' -f1)
fi



read -p "Prerequisites installed, press [Enter] to proceed with installation."
clear

#IPTables

#send a message
echo "Configuring IPTables"

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
echo "Installing FusionPBX"

#install dependencies
apt-get install -y vim git dbus haveged ssl-cert qrencode
apt-get install -y ghostscript libtiff5-dev libtiff-tools at

#pause to verify installation
read -p "FusionPBX dependencies installed, check for errors."

#get the branch
if [ .$system_branch = .'master' ]; then
	echo "Using master"
	branch=""
else
	system_major=$(git ls-remote --heads https://github.com/fusionpbx/fusionpbx.git | cut -d/ -f 3 | grep -P '^\d+\.\d+' | sort | tail -n 1 | cut -d. -f1)
	system_minor=$(git ls-remote --tags https://github.com/fusionpbx/fusionpbx.git $system_major.* | cut -d/ -f3 |  grep -P '^\d+\.\d+' | sort | tail -n 1 | cut -d. -f2)
	system_version=$system_major.$system_minor
	echo "Using version $system_version"
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
echo "Configuring PHP"

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
echo "configuring the web server"


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

echo " beginning source install of FreeSWITCH"

# apt dependency installation
apt install -y autoconf automake devscripts g++ git-core libncurses5-dev libtool make libjpeg-dev
apt install -y pkg-config flac  libgdbm-dev libdb-dev gettext equivs mlocate git dpkg-dev libpq-dev
apt install -y liblua5.2-dev libtiff5-dev libperl-dev libcurl4-openssl-dev libsqlite3-dev libpcre3-dev
apt install -y devscripts libspeexdsp-dev libspeex-dev libldns-dev libedit-dev libopus-dev libmemcached-dev
apt install -y libshout3-dev libmpg123-dev libmp3lame-dev yasm nasm libsndfile1-dev libuv1-dev libvpx-dev
apt install -y libvpx6 swig4.0
apt install -y sqlite3
apt install -y cmake uuid-dev

read -p "check the logs and make sure that nothing had issues installing"
clear

# Start of the source builds, lots of checks here

echo "building libks"
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

echo "building Sofia"
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

echo "building SpanDSP"
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
echo "Installing Fail2ban"
apt-get install -y fail2ban

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
/usr/sbin/service fail2ban restart

read -p "Fail2ban installed, check for errors."
clear 

#Postgres
#installing postgresql client
apt-get install -y postgresql-client

#create random passwords if flag is set
if [ .$database_password = .'random' ]; then
	database_password=$(dd if=/dev/urandom bs=1 count=20 2>/dev/null | base64 | sed 's/[=\+//]//g')
fi




if [ ."$database_cluster_init" = ."true" ] ; then
	# set the main postgres password
	export PGPASSWORD=adminpassword
	#move to /tmp to prevent a red herring error when running sudo with psql
	cd /tmp
	# add the databases, users and grant permissions to them
	psql -U postgres -h 127.0.0.1 -e -c "CREATE DATABASE fusionpbx;";
	psql -U postgres -h 127.0.0.1 -e -c "CREATE DATABASE freeswitch;";
	psql -U postgres -h 127.0.0.1 -e -c "CREATE ROLE fusionpbx WITH SUPERUSER LOGIN PASSWORD '$database_password';"
	psql -U postgres -h 127.0.0.1 -e -c "CREATE ROLE freeswitch WITH SUPERUSER LOGIN PASSWORD '$database_password';"
	psql -U postgres -h 127.0.0.1 -e -c "GRANT ALL PRIVILEGES ON DATABASE fusionpbx to fusionpbx;"
	psql -U postgres -h 127.0.0.1 -e -c "GRANT ALL PRIVILEGES ON DATABASE freeswitch to fusionpbx;"
	psql -U postgres -h 127.0.0.1 -e -c "GRANT ALL PRIVILEGES ON DATABASE freeswitch to freeswitch;"
	read -p "database initialized, check for errors"
	#add the database schema
	cd /var/www/fusionpbx && php /var/www/fusionpbx/core/upgrade/upgrade_schema.php > /dev/null 2>&1
	#set the default postgres password
	export PGPASSWORD=$database_password
	# jump back to script directory
	cd $CWD
fi

read -p "Postgres setup complete, check for additional errors"
clear

echo "time to set some more variables"
#set the domain_uuid
domain_uuid=$(/usr/bin/php /var/www/fusionpbx/resources/uuid.php);
#set the database user
database_username=fusionpbx




#install the database backup
echo "setting up backup"
cp backup/fusionpbx-backup /etc/cron.daily
cp backup/fusionpbx-maintenance /etc/cron.daily
chmod 755 /etc/cron.daily/fusionpbx-backup
chmod 755 /etc/cron.daily/fusionpbx-maintenance
sed -i "s/zzz/$database_password/g" /etc/cron.daily/fusionpbx-backup
sed -i "s/zzz/$database_password/g" /etc/cron.daily/fusionpbx-maintenance

#add the config.php
echo "setting up config.php"
mkdir -p /etc/fusionpbx
chown -R www-data:www-data /etc/fusionpbx
cp fusionpbx/config.php /etc/fusionpbx
sed -i /etc/fusionpbx/config.php -e s:"{database_host}:$database_host:"
sed -i /etc/fusionpbx/config.php -e s:'{database_username}:fusionpbx:'
sed -i /etc/fusionpbx/config.php -e s:"{database_password}:$database_password:"

#add the domain for this server to the database
psql --host=$database_host --port=$database_port --username=$database_username -c "insert into v_domains (domain_uuid, domain_name, domain_enabled) values('$domain_uuid', '$domain_name', 'true');"

#set app defaults
cd /var/www/fusionpbx && php /var/www/fusionpbx/core/upgrade/upgrade_domains.php

#add the new FusionPBX admin user
user_uuid=$(/usr/bin/php /var/www/fusionpbx/resources/uuid.php);
user_salt=$(/usr/bin/php /var/www/fusionpbx/resources/uuid.php);
user_name=$system_username
if [ .$system_password = .'random' ]; then
	user_password=$(dd if=/dev/urandom bs=1 count=20 2>/dev/null | base64 | sed 's/[=\+//]//g')
else
	user_password=$system_password
fi
password_hash=$(php -r "echo md5('$user_salt$user_password');");
psql --host=$database_host --port=$database_port --username=$database_username -t -c "insert into v_users (user_uuid, domain_uuid, username, password, salt, user_enabled) values('$user_uuid', '$domain_uuid', '$user_name', '$password_hash', '$user_salt', 'true');"

#get the superadmin group_uuid
group_uuid=$(psql --host=$database_host --port=$database_port --username=$database_username -qtAX -c "select group_uuid from v_groups where group_name = 'superadmin';");

#add the new admin user to the superadmingroup
user_group_uuid=$(/usr/bin/php /var/www/fusionpbx/resources/uuid.php);
group_name=superadmin
psql --host=$database_host --port=$database_port --username=$database_username -c "insert into v_user_groups (user_group_uuid, domain_uuid, group_name, group_uuid, user_uuid) values('$user_group_uuid', '$domain_uuid', '$group_name', '$group_uuid', '$user_uuid');"

#update xml_cdr url, user and password
xml_cdr_username=$(dd if=/dev/urandom bs=1 count=20 2>/dev/null | base64 | sed 's/[=\+//]//g')
xml_cdr_password=$(dd if=/dev/urandom bs=1 count=20 2>/dev/null | base64 | sed 's/[=\+//]//g')
sed -i /etc/freeswitch/autoload_configs/xml_cdr.conf.xml -e s:"{v_http_protocol}:http:"
sed -i /etc/freeswitch/autoload_configs/xml_cdr.conf.xml -e s:"{domain_name}:$database_host:"
sed -i /etc/freeswitch/autoload_configs/xml_cdr.conf.xml -e s:"{v_project_path}::"
sed -i /etc/freeswitch/autoload_configs/xml_cdr.conf.xml -e s:"{v_user}:$xml_cdr_username:"
sed -i /etc/freeswitch/autoload_configs/xml_cdr.conf.xml -e s:"{v_pass}:$xml_cdr_password:"

#set app defaults again
cd /var/www/fusionpbx && php /var/www/fusionpbx/core/upgrade/upgrade.php

#restart freeswitch
/bin/systemctl daemon-reload
/bin/systemctl restart freeswitch

#welcome message
echo ""
echo ""
echo "Installation Notes. "
echo ""
echo "   Please save the this information and reboot this system to complete the install. "
echo ""
echo "   Use a web browser to login."
echo "      domain name: https://$domain_name"
echo "      username: $user_name"
echo "      password: $user_password"
echo ""
echo "   The domain name in the browser is used by default as part of the authentication."
echo "   If you need to login to a different domain then use username@domain."
echo "      username: $user_name@$domain_name";
echo ""