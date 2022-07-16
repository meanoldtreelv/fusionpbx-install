#!/bin/sh
#
# installation bootstrap script 
#
#clean up previous install attempts
rm -rf /usr/src/fusionpbx-install
#remove the cdrom from apt sources
sed -i '/cdrom:/d' /etc/apt/sources.list
#grab the base packages
apt-get update
apt-get upgrade
apt-get install -y git lsb-release nano
# cloning the repo so that we have things on disk
cd /usr/src
git clone https://github.com/meanoldtreelv/fusionpbx-install.git
source /usr/src/fusionpbx-install/installmenu.sh
