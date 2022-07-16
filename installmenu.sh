#!/bin/bash


cd /usr/src/fusionpbx-install/
clear
echo "Node Build Menu"
PS3='Please enter your choice: '
options=("Edit config" "Docker Install & Join" "Install IPTables" "Install FusionPBX Base" "Freeswitch Install Menu" "Set Up Database" "Install Database and set up users" "Quit")
select opt in "${options[@]}"
do
    case $opt in
		"Edit config")
            clear
			nano /usr/src/fusionpbx-install/install/config.sh
			;;
		"Install All Dependencies")
            clear
			bash ./install/dependencies.sh
            clear
			bash ./install/dependencies.sh
			echo ""
			echo ""
			echo "Check apt-get output for any installation errors"
			echo ""
			echo ""
			read -s -p "Press any key to resume ..."
			;;
		"Docker Install & Join")
			clear
            bash ./install/docker-install.sh
			echo "iptables installation complete"
			read -s -p "Press any key to resume ..."
            ;;
        "Install IPTables")
            clear
			bash ./install/iptables.sh
			echo "iptables installation complete"
			read -s -p "Press any key to resume ..."
            ;;
		"Install FusionPBX Base")
            clear
			bash ./install/fusionpbx.sh
			echo "FusionPBX base installation complete"
			read -s -p "Press any key to resume ..."
            ;;
        "Freeswitch Install Menu")
            clear
			bash ./install/freeswitch.sh
            ;;
		"Set Up Database")
            clear
			bash ./install/database.sh
			echo "database setup complete complete"
			read -s -p "Press any key to resume ..."
            ;;
		"Install Database and set up users")
            clear
			bash ./install/build.sh
			break
            ;;
        "Quit")
            break
            ;;
        *) echo "invalid option $REPLY";;
    esac
done