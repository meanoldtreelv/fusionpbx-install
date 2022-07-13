#!/bin/sh

#move to script directory so all relative paths work
cd "$(dirname "$0")"

#includes
. ./config.sh
. ./colors.sh
. ./environment.sh

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
