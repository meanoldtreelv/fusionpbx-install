#!/bin/bash


echo "Node Build Menu"
PS3='Please enter your choice: '
options=("Edit config" "Docker Install & Join" "Option 2" "Option 3" "Quit")
select opt in "${options[@]}"
do
    case $opt in
        "Edit config")
            nano /usr/src/fusionpbx-install/install/config.sh
            ;;
		"Install All Dependencies")
            . ./install/dependencies.sh
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