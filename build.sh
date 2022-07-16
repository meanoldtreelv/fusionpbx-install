#!/bin/bash

source /usr/src/fusionpbx-install/install/config.sh



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
psql -U $database_username -h 127.0.0.1 -ac "insert into v_domains (domain_uuid, domain_name, domain_enabled) values('$domain_uuid', '$domain_name', 'true');"

#set app defaults
cd /var/www/fusionpbx && php /var/www/fusionpbx/core/upgrade/upgrade_domains.php

#add the new FusionPBX admin user
user_uuid=$(/usr/bin/php /var/www/fusionpbx/resources/uuid.php);
user_salt=$(/usr/bin/php /var/www/fusionpbx/resources/uuid.php);
user_name=$system_username
user_password=$(dd if=/dev/urandom bs=1 count=20 2>/dev/null | base64 | sed 's/[=\+//]//g')
password_hash=$(php -r "echo md5('$user_salt$user_password');");

psql -U $database_username -h 127.0.0.1 -ac  "insert into v_users (user_uuid, domain_uuid, username, password, salt, user_enabled) values('$user_uuid', '$domain_uuid', '$user_name', '$password_hash', '$user_salt', 'true');"

#get the superadmin group_uuid
group_uuid=$(psql -U $database_username -h 127.0.0.1 -qtAX -c "select group_uuid from v_groups where group_name = 'superadmin';");

#add the new admin user to the superadmingroup
user_group_uuid=$(/usr/bin/php /var/www/fusionpbx/resources/uuid.php);
group_name=superadmin
psql -U $database_username -h 127.0.0.1 -ac "insert into v_user_groups (user_group_uuid, domain_uuid, group_name, group_uuid, user_uuid) values('$user_group_uuid', '$domain_uuid', '$group_name', '$group_uuid', '$user_uuid');"

#update xml_cdr url, user and password
xml_cdr_username=$(dd if=/dev/urandom bs=1 count=20 2>/dev/null | base64 | sed 's/[=\+//]//g')
xml_cdr_password=$(dd if=/dev/urandom bs=1 count=20 2>/dev/null | base64 | sed 's/[=\+//]//g')
sed -i /etc/freeswitch/autoload_configs/xml_cdr.conf.xml -e s:"{v_http_protocol}:http:"
sed -i /etc/freeswitch/autoload_configs/xml_cdr.conf.xml -e s:"{domain_name}:$database_host:"
sed -i /etc/freeswitch/autoload_configs/xml_cdr.conf.xml -e s:"{v_project_path}::"
sed -i /etc/freeswitch/autoload_configs/xml_cdr.conf.xml -e s:"{v_user}:$xml_cdr_username:"
sed -i /etc/freeswitch/autoload_configs/xml_cdr.conf.xml -e s:"{v_pass}:$xml_cdr_password:"

#set app defaults again
cd /var/www/fusionpbx
php /var/www/fusionpbx/core/upgrade/upgrade.php

#restart freeswitch
systemctl daemon-reload
systemctl restart freeswitch

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