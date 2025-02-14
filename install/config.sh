
# FusionPBX Settings
domain_name=ip_address                      # hostname, ip_address or a custom value
system_username=admin                       # default username admin                    
system_branch=master                        # master, stable

# FreeSWITCH Settings
switch_branch=stable                        # master, stable
switch_source=true                          # true (source compile) or false (binary package)
switch_package=false                        # true (binary package) or false (source compile)
switch_version=1.10.7                       # which source code to download, only for source
switch_tls=true                             # true or false
switch_token=                               # Get the auth token from https://signalwire.com
                                            # Signup or Login -> Profile -> Personal Auth Token
# Sofia-Sip Settings
sofia_version=1.13.7                        # release-version for sofia-sip to use

# Database Settings
database_password=random                    # random or a custom value (safe characters A-Z, a-z, 0-9)
database_backup=false   					# true or false
database_postgres_password=adminpassword    # postgres user password for distributed database
database_cluster_init=false					# initialize the database cluster, create users and tables               

# General Settings
php_version=7.4                             # PHP version 7.1, 7.3, 7.4
letsencrypt_folder=true                     # true or false

#relocated settings
server_address=$(hostname -I)
domain_name=$(hostname -I | cut -d ' ' -f1)
