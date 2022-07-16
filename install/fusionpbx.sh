#!/bin/bash

source /usr/src/fusionpbx-install/install/config.sh

echo "add the cache directory"
mkdir -p /var/cache/fusionpbx
chown -R www-data:www-data /var/cache/fusionpbx

echo "get the source code"
git clone https://github.com/fusionpbx/fusionpbx.git /var/www/fusionpbx
chown -R www-data:www-data /var/www/fusionpbx

#PHP
#send a message
echo "Configuring PHP"
#update config if source is being used
php_ini_file='/etc/php/7.4/fpm/php.ini'

echo "update some values in php.ini"
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

#restart the php service
systemctl daemon-reload
systemctl restart php7.4-fpm

echo "configuring the web server"

#enable fusionpbx nginx config

cp ./nginx/fusionpbx /etc/nginx/sites-available/fusionpbx

#prepare socket name
sed -i /etc/nginx/sites-available/fusionpbx -e 's#unix:.*;#unix:/var/run/php/php7.4-fpm.sock;#g'
ln -s /etc/nginx/sites-available/fusionpbx /etc/nginx/sites-enabled/fusionpbx

#self signed certificate
ln -s /etc/ssl/private/ssl-cert-snakeoil.key /etc/ssl/private/nginx.key
ln -s /etc/ssl/certs/ssl-cert-snakeoil.pem /etc/ssl/certs/nginx.crt

#remove the default site
rm /etc/nginx/sites-enabled/default

#add the letsencrypt directory if needed
if [ .$letsencrypt_folder = .true ]; then
        mkdir -p /var/www/letsencrypt/
fi

#flush systemd cache
systemctl daemon-reload

#restart nginx
systemctl restart nginx

