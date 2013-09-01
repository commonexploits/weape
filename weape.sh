#!/usr/bin/env bash
# wEAPe - Wireless EAP Extractor
# Daniel Compton
# 08/2013
# Daniel Compton
# www.commonexploits.com
# contact@commexploits.com
# Twitter = @commonexploits
# Tested on Bactrack 5 & Kali Nessus version 4 & 5


# Script begins
#===============================================================================

VERSION="0.2" 

clear
echo ""
echo -e "\e[00;32m#############################################################\e[00m"
echo ""
echo -e "	wEAPe Wireless EAP Extractor $VERSION "
echo ""
echo -e "	EAP Domain Username Extractor"
echo ""
echo -e "\e[00;32m#############################################################\e[00m"
echo ""

#Dependency checking

#Check for tshark
which tshark>/dev/null
if [ $? -eq 0 ]
        then
                echo ""
else
                echo ""
       		echo -e "\e[01;31m[!]\e[00m Unable to find the required Tshark program, install and try again"
        exit 1
fi


#Check for Airmon-ng
which airmon-ng >/dev/null
if [ $? -eq 0 ]
        then
                echo ""
else
                echo ""
        echo -e "\e[01;31m[!]\e[00m Unable to find the required Airmon-NG program, install and try again"
        exit 1
fi

#Dependency checking

#Check for Airodump-NG
which airodump-ng >/dev/null
if [ $? -eq 0 ]
        then
                echo ""
else
                echo ""
        echo -e "\e[01;31m[!]\e[00m Unable to find the required Airodump-ng program, install and try again"
        exit 1
fi


#Check for screen
which screen >/dev/null
if [ $? -eq 0 ]
        then
                echo ""
else
                echo ""
        echo -e "\e[01;31m[!]\e[00m Unable to find the required Screen program, install and try again"
        exit 1
fi

echo -e "\e[01;33m[-]\e[00m In order to extract EAP packets you will need to associate (not authenticate) with the access point of interest"
echo ""
echo -e "\e[01;33m[-]\e[00m Your wireless network card must support packet injection."
echo ""
sleep 3
echo -e "\e[01;32m[-]\e[00m Now checking your wireless card..."
echo ""
# fix for occasional RFKILL errors
rfkill unblock all >/dev/null

# check for wifi mon interface
MONCHK=$(airmon-ng |grep -i "mon" |wc -l)
if [ "$MONCHK" = 0 ]
	then
	echo ""
	echo -e "\e[01;31m[!]\e[00m Unable to find any wireless interfaces in monitor mode."
	echo ""
	echo -e "\e[01;32m[-]\e[00m The following interfaces exist:"
	echo "--------------------------------------------------------"
	airmon-ng
        echo -e "\e[1;31m------------------------------------------------------------------------------------------------------------------\e[00m"
        echo -e "\e[01;31m[?]\e[00m Enter the interface you would like to put into monitor mode and press ENTER. i.e wlan0"
        echo -e "\e[1;31m------------------------------------------------------------------------------------------------------------------\e[00m"
	echo ""
	read WLANTMP
	echo ""
	echo -e "\e[01;32m[-]\e[00m Now attempting to put your adaptor "$WLANTMP" into monitor mode...please wait"
	echo ""
	sleep 2
	airmon-ng stop "$WLANTMP" >/dev/null
	sleep 3
	airmon-ng start "$WLANTMP" >/dev/null
	echo ""
	echo -e "\e[01;33m[-]\e[00m If an "SIOCSIFFLAGS:" error was displayed against "$WLANTMP", then you card/driver is not compatable"
	echo ""
	echo -e "\e[01;32m[-]\e[00m Press Enter to continue if you did not see the "SIOCSIFFLAGS" error."
	echo ""
	read ENTERKEY
	sleep 3
	airmon-ng |grep -i "mon" >/dev/null
		if [ $? = 0 ]
			then
				MADEMON=$(airmon-ng |grep -i "mon" |awk '{print $1}')
				echo -e "\e[01;32m[+]\e[00m Success, created "$MADEMON" interface in monitor mode."
				echo ""
				MONINT="$MADEMON"
		else
			echo ""
			echo -e "\e[01;31m[!]\e[00m Unable to create a monitor interface, script will exit."
			echo ""
			echo -e "\e[01;31m[!]\e[00m Your card or driver may not be compatable. Fix and run the script again"
			echo ""
			exit 1
		fi

elif [ "$MONCHK" = 1 ]
	then
	echo ""
	MONINT=$(airmon-ng |grep "mon" |awk '{print $1}')
	echo -e "\e[01;32m[+]\e[00m I found "$MONINT" interface, I will use that for the script."
	echo ""
else
	echo ""
	echo -e "\e[01;32m[-]\e[00m Multiple interfaces exist in monitor mode:"
        echo "-------------------------------------------------------------------"
	airmon-ng |grep -i "mon"
	echo ""
	echo -e "\e[1;31m------------------------------------------------------------------------------------------------------------------\e[00m"
        echo -e "\e[01;31m[?]\e[00m Enter the interface you would like to use and press ENTER. i.e mon0"
        echo -e "\e[1;31m------------------------------------------------------------------------------------------------------------------\e[00m"
        echo ""
	read MONINT
	echo ""
fi
sleep 3
clear
echo ""
echo -e "\e[01;33m[-]\e[00m You need to associate with the access point in question before any information can be extracted"
echo ""
echo -e "\e[01;33m[-]\e[00m Note: it should be access points that only have MGT within the AUTH column, which means it is using 802.1x"
echo ""
echo -e "\e[01;33m[-]\e[00m Also it should be an access point with traffic or is likely to have traffic. check under Data column"
echo ""
echo -e "\e[01;33m[-]\e[00m You will be presented a list all wireless networks. When you have identified the SSID of interest press CTRL C"
echo ""
echo -e "\e[01;32m[-]\e[00m Press ENTER to continue"
echo ""
read ENTERKEY
airodump-ng $MONINT

echo -e "\e[1;31m------------------------------------------------------------------------------------------------------------------\e[00m"
echo -e "\e[01;31m[?]\e[00m Please enter the BSSID from above for the access point of interest (not SSID) i.e '00:AE:x:x:x:x:x'"
echo -e "\e[1;31m------------------------------------------------------------------------------------------------------------------\e[00m"
echo ""
read BSSIDTMP
BSSID=$(echo "$BSSIDTMP"| sed -e 's/^[ \t]*//' |sed 's/[ \t]*$//')
echo -e "\e[1;31m---------------------------------------------------------------------------------------\e[00m"
echo -e "\e[01;31m[?]\e[00m Please enter the channel number of of the access point of interest i.e 6"
echo -e "\e[1;31m---------------------------------------------------------------------------------------\e[00m"
echo ""
read CHAN
echo ""
echo -e "\e[01;32m[-]\e[00m I will now run a background process to assoicate with this access point..."
echo ""
screen -d -m -S eappeap_dump airodump-ng -i $MONINT -c $CHAN --bssid $BSSID
echo ""
echo -e "\e[01;32m[-]\e[00m Now sniffing traffic looking for EAP packets.."
echo ""
echo -e "\e[01;33m[-]\e[00m Note this can take some time as it depends on finding EAP traffic and users authenticating."
echo ""
echo -e "\e[01;32m[-]\e[00m Leave script running and users will appear if they authenticate, CTRL C to cancel"
echo ""
echo -e "\e[01;32m-------------------------------------------------------------------------------------\e[00m"
echo -e "\e[01;32m[+]\e[00m Capturing Traffic, press CTRL C once you have seen sufficent usernames"
echo -e "\e[01;32m-------------------------------------------------------------------------------------\e[00m"
tshark -i "$MONINT" -R eap -V 2>&1 |grep "Identity: *[a-z]\|*[A-Z]\|*[0-9]"
echo ""
echo -e "\e[01;33m[-]\e[00m All airodump-ng processes are being stopped.."
echo ""
killall airodump-ng >/dev/null 2>&1
exit 0
# Script end
