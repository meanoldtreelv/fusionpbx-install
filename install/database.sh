#!/bin/bash

source /usr/src/fusionpbx-install/install/config.sh

#create random passwords if flag is set
if [ .$database_password = .'random' ]; then
	database_password=$(dd if=/dev/urandom bs=1 count=20 2>/dev/null | base64 | sed 's/[=\+//]//g')
fi

# set the main postgres password
export PGPASSWORD=$database_postgres_password
echo "PGPASSWORD is now $PGPASSWORD"
#move to /tmp to prevent a red herring error when running sudo with psql
cd /tmp
# add the databases, users and grant permissions to them
psql -U postgres -h 127.0.0.1 -af /usr/src/fusionpbx-install/intall/init.sql
#update the new users with secure passwords
psql -U postgres -h 127.0.0.1 -ac "ALTER USER fusionpbx WITH PASSWORD $database_password;"
psql -U postgres -h 127.0.0.1 -ac "ALTER USER freeswitch WITH PASSWORD $database_password;"
#add the database schema
cd /var/www/fusionpbx
php /var/www/fusionpbx/core/upgrade/upgrade_schema.php > /dev/null 2>&1
#set the default postgres password for future users
export PGPASSWORD=$database_password
echo "PGPASSWORD is now $PGPASSWORD"
# jump back to script directory
cd /usr/src/fusionpbx-install/
