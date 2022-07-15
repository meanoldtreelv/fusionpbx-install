#!/bin/bash
#install dependencies from apt to make configuration cleaner, can be run more than once to check for errors
apt-get update && apt-get upgrade -y
apt-get install -y wget
apt-get install -y systemd
apt-get install -y systemd-sysv
apt-get install -y ca-certificates
apt-get install -y dialog
apt-get install -y nano
apt-get install -y net-tools
#patch in snmp/snmpd
apt-get install -y snmpd
echo "rocommunity public" > /etc/snmp/snmpd.conf
service snmpd restart
apt-get install -y sngrep
apt-get install -y vim git dbus haveged ssl-cert qrencode
apt-get install -y ghostscript libtiff5-dev libtiff-tools at
apt-get install -y nginx
apt-get install -y php7.4 php7.4-cli php7.4-dev php7.4-fpm php7.4-pgsql php7.4-sqlite3 php7.4-odbc php7.4-curl php7.4-imap php7.4-xml php7.4-gd php7.4-mbstring
apt-get install -y unzip
apt-get install -y autoconf automake devscripts g++ git-core libncurses5-dev libtool make libjpeg-dev
apt-get install -y pkg-config flac  libgdbm-dev libdb-dev gettext equivs mlocate git dpkg-dev libpq-dev
apt-get install -y liblua5.2-dev libtiff5-dev libperl-dev libcurl4-openssl-dev libsqlite3-dev libpcre3-dev
apt-get install -y devscripts libspeexdsp-dev libspeex-dev libldns-dev libedit-dev libopus-dev libmemcached-dev
apt-get install -y libshout3-dev libmpg123-dev libmp3lame-dev yasm nasm libsndfile1-dev libuv1-dev libvpx-dev
apt-get install -y libvpx6 swig4.0
apt-get install -y sqlite3
apt-get install -y cmake uuid-dev
apt-get install -y read
