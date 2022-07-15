#!/bin/bash


echo "Node Build Menu"
PS3='Please enter your choice: '
options=("test read" "Edit config" "Docker Install & Join" "Option 2" "Option 3" "Quit")
select opt in "${options[@]}"
do
    case $opt in
        "test read")
			clear
			read -s -p "Press any key to resume ..."
			clear
			;;
		"Edit config")
            clear
			nano /usr/src/fusionpbx-install/install/config.sh
            clear
			;;
		"Install All Dependencies")
            clear
			. ./install/dependencies.sh
            clear
			. ./install/dependencies.sh
			echo ""
			echo ""
			echo "Check apt-get output for any installation errors"
			echo ""
			echo ""
			read -s -p "Press any key to resume ..."
			;;
		"Docker Install & Join")
            . ./install/docker-install.sh
            ;;
        "Option 2")
            echo "you chose choice 2"
            ;;
        "Option 3")
            echo "you chose choice $REPLY which is $opt"
            ;;
        "Quit")
            break
            ;;
        *) echo "invalid option $REPLY";;
    esac
done