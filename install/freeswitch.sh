#!/bin/bash

source /usr/src/fusionpbx-install/intsall/config.sh

cd /usr/src
echo "FreeSWITCH build menu"
PS3='Please enter your choice: '
options=("Build libks" "Build Sofia" "Build SpanDSP" "Build FreeSWITCH" "Quit")
select opt in "${options[@]}"
do
    case $opt in
		"Build libks")
			clear
            echo "building libks"
			# libks
			git clone https://github.com/signalwire/libks.git libks
			cd libks
			cmake .
			make
			make install
			# libks C includes
			export C_INCLUDE_PATH=/usr/include/libks
			#error check
			echo ""
			echo ""
			echo "Check build output for any installation errors"
			echo ""
			echo ""
			read -s -p "Press any key to resume ..."
			cd /usr/src
			;;
		"Build Sofia")
            clear
			echo "Building Sofia"
			# sofia-sip
			wget https://github.com/freeswitch/sofia-sip/archive/refs/tags/v$sofia_version.zip
			unzip v$sofia_version.zip
			rm -R sofia-sip
			mv sofia-sip-$sofia_version sofia-sip
			cd sofia-sip
			sh autogen.sh
			./configure
			make
			make install
			#error check
			echo ""
			echo ""
			echo "Check build output for any installation errors"
			echo ""
			echo ""
			read -s -p "Press any key to resume ..."
			cd /usr/src
			;;
		"Build SpanDSP")
			clear
            bash ./install/docker-install.shgit clone https://github.com/freeswitch/spandsp.git spandsp
			cd spandsp
			sh autogen.sh
			./configure
			make
			make install
			ldconfig
			#error check
			echo ""
			echo ""
			echo "Check build output for any installation errors"
			echo ""
			echo ""
			read -s -p "Press any key to resume ..."
			cd /usr/src
				;;
        "Build FreeSWITCH")
            clear
			echo "Using FreeSWITCH version $switch_version"
			wget http://files.freeswitch.org/freeswitch-releases/freeswitch-$switch_version.-release.zip
			unzip freeswitch-$switch_version.-release.zip
			rm -R freeswitch
			mv freeswitch-$switch_version.-release freeswitch
			cd /usr/src/freeswitch
			#error check
			echo ""
			echo ""
			echo "Check if download was successful"
			echo ""
			echo ""
			read -s -p "Press any key to resume ..."
			#apply patch
			patch -u /usr/src/freeswitch/src/mod/databases/mod_pgsql/mod_pgsql.c -i /usr/src/fusionpbx-install.sh/debian/resources
			#error check
			echo ""
			echo ""
			echo "Check if patch threw any errors"
			echo ""
			echo ""
			read -s -p "Press any key to resume ..."
			echo "Toggle some modules."
			# enable required modules
			sed -i /usr/src/freeswitch/modules.conf -e s:'#applications/mod_av:formats/mod_av:'
			sed -i /usr/src/freeswitch/modules.conf -e s:'#applications/mod_callcenter:applications/mod_callcenter:'
			sed -i /usr/src/freeswitch/modules.conf -e s:'#applications/mod_cidlookup:applications/mod_cidlookup:'
			sed -i /usr/src/freeswitch/modules.conf -e s:'#applications/mod_memcache:applications/mod_memcache:'
			sed -i /usr/src/freeswitch/modules.conf -e s:'#applications/mod_nibblebill:applications/mod_nibblebill:'
			sed -i /usr/src/freeswitch/modules.conf -e s:'#applications/mod_curl:applications/mod_curl:'
			sed -i /usr/src/freeswitch/modules.conf -e s:'#formats/mod_shout:formats/mod_shout:'
			sed -i /usr/src/freeswitch/modules.conf -e s:'#formats/mod_pgsql:formats/mod_pgsql:'
			sed -i /usr/src/freeswitch/modules.conf -e s:'#say/mod_say_es:say/mod_say_es:'
			sed -i /usr/src/freeswitch/modules.conf -e s:'#say/mod_say_fr:say/mod_say_fr:'
			#disable module or install dependency libks to compile signalwire
			sed -i /usr/src/freeswitch/modules.conf -e s:'applications/mod_signalwire:#applications/mod_signalwire:'
			sed -i /usr/src/freeswitch/modules.conf -e s:'endpoints/mod_skinny:#endpoints/mod_skinny:'
			sed -i /usr/src/freeswitch/modules.conf -e s:'endpoints/mod_verto:#endpoints/mod_verto:'	
			# prepare the build
			./configure -C --enable-portable-binary --disable-dependency-tracking --prefix=/usr --localstatedir=/var --sysconfdir=/etc --with-openssl --enable-core-pgsql-support
			# compile and install
			make
			make install
			#error check
			echo ""
			echo ""
			echo "Freeswitch Core Installation complete, check for errors."
			echo ""
			echo ""
			read -s -p "Press any key to resume ..."
			echo "installing sounds"
			make sounds-install moh-install
			make hd-sounds-install hd-moh-install
			make cd-sounds-install cd-moh-install
			#move the music into music/default directory
			mkdir -p /usr/share/freeswitch/sounds/music/default
			mv /usr/share/freeswitch/sounds/music/*000 /usr/share/freeswitch/sounds/music/default
            #error check
			echo ""
			echo ""
			echo "Freeswitch Sounds Installation complete, check for errors."
			echo ""
			echo ""
			read -s -p "Press any key to resume ..."
			cd /usr/src
			;;
        "Quit")
            break
            ;;
        *) echo "invalid option $REPLY";;
    esac
done