#!/bin/bash
#
# MusicBox startup script
#
# This script is executed by /etc/rc.local
#
`echo "performance" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor`

#set user vars
CONFIG_FILE=/boot/config/settings.ini
NAME="MusicBox"
DEFAULT_ROOT_PASSWORD="musicbox"

echo "************************"
echo "Initializing MusicBox..."
echo "************************"

# import ini parser
. /opt/musicbox/read_ini.sh

# convert windows ini to unix
dos2unix -n $CONFIG_FILE /tmp/settings.ini > /dev/null 2>&1 || true

#declare $INI before reading ini https://github.com/rudimeier/bash_ini_parser/issues/2
unset INI
declare -A INI

# ini vars to mopidy settings
read_ini /tmp/settings.ini

rm /tmp/settings.ini > /dev/null 2>&1 || true

INI_READ=true

REBOOT=0

#include code from setsound script
. /opt/musicbox/setsound.sh

if [ "$INI__musicbox__resize_once" == "1" ]
then
    #set resize_once=false in ini file
    sed -i -e "/^\[musicbox\]/,/^\[.*\]/ s|^\(resize_once[ \t]*=[ \t]*\).*$|\1false\r|" $CONFIG_FILE
    echo "Performing resize..."
    sh /opt/musicbox/resizefs.sh -y
    REBOOT=1
fi

#get name of device and trim
HOSTNM=`< file /etc/hostname | tr -cd "[:alnum:]"`
#get name in ini and trim
CLEAN_NAME=$(echo $INI__network__name | tr -cd "[:alnum:]")
#max 9 characters (max netbios length = 15, + '.local')
CLEAN_NAME=$(echo $CLEAN_NAME | cut -c 1-9)

if [ "$CLEAN_NAME" == "" ]
then
    CLEAN_NAME="MusicBox"
fi

if [ "$CLEAN_NAME" != "$HOSTNM" ]
then
    #if devicename is not the same as ini, change and reboot<-->
    echo "Changing system name to $CLEAN_NAME..."
    echo "$CLEAN_NAME" > /etc/hostname
    echo "127.0.0.1       localhost $CLEAN_NAME" > /etc/hosts
    REBOOT=1
fi

if [ "$REBOOT" == 1 ]
then
    reboot
    exit
fi

echo "MusicBox name is $CLEAN_NAME"

# do the change password stuff
if [ "$INI__musicbox__root_password" != "" -a "$INI__musicbox__root_password" != "$DEFAULT_ROOT_PASSWORD" ]
then
    echo "Setting root user password..."
    echo "root:$INI__musicbox__root_password" | chpasswd
    #remove password
    sed -i -e "/^\[musicbox\]/,/^\[.*\]/ s|^\(root_password[ \t]*=[ \t]*\).*$|\1\r|" $CONFIG_FILE
fi

#allow shutdown for all users
chmod u+s /sbin/shutdown

if [ "$INI__network__wifi_network" != "" ]
then
    #put wifi settings for wpa roaming
	#
	# If wifi_country is set then include a country=XX line
    if [ "$INI__network__wifi_country" != "" ]
    then
        WIFICOUNTRY="country=$INI__network__wifi_country"
    else
        WIFICOUNTRY=""
    fi
    if [ "$INI__network__wifi_password" != "" ]
    then
        password_length=${#INI__network__wifi_password}
        if [ $password_length -gt 63 ]
        then
            PSK="$INI__network__wifi_password"
        else
            PSK="\"$INI__network__wifi_password\""
        fi
        cat >/etc/wpa.conf <<EOF
            ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev
            update_config=1
            $WIFICOUNTRY
            network={
                ssid="$INI__network__wifi_network"
                psk=$PSK
                scan_ssid=1
            }
EOF
    else
        #if no password is given, set key_mgmt to NONE
        cat >/etc/wpa.conf <<EOF
            ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev
            update_config=1
            $WIFICOUNTRY
            network={
                ssid="$INI__network__wifi_network"
                key_mgmt=NONE
                scan_ssid=1
            }
EOF
    fi

    #enable wifi
#    ifdown wlan0
    ifup wlan0

    /etc/init.d/networking restart
fi

if [ "$INI__network__workgroup" != "" ]
then
    #change smb.conf workgroup value
    sed -i "s/workgroup = .*$/workgroup = $INI__network__workgroup/ig" /etc/samba/smb.conf
    #restart samba
    /etc/init.d/samba restart
fi

#redirect 6680 to 80
iptables -t nat -A PREROUTING -p tcp --dport 80 -j REDIRECT --to-port 6680 > /dev/null 2>&1 || true

#check networking, sleep for a while
MYIP=$(hostname -I)
LOOP_COUNT=0
LOOP_LIMIT=4
while [ "$MYIP" == "" -a "$INI__network__wait_for_network" != "0" ]
do
    LOOP_COUNT=$((LOOP_COUNT+1));
    if [ $LOOP_COUNT -gt $LOOP_LIMIT ]
    then
        echo "********************************************"
        echo "ERROR: Timeout waiting for network to start."
        echo "       Check your network settings"
        echo "********************************************"
        break;
    fi
    echo "Waiting for network ($LOOP_COUNT of $LOOP_LIMIT)..."
    echo
    /etc/init.d/networking restart
    sleep 30
    MYIP=$(hostname -I)
done

# start SSH if enabled
if [ "$INI__network__enable_ssh" == "1" ]
then
    #create private keys for dropbear if they don't exist
    if [ ! -f "/etc/dropbear/dropbear_dss_host_key" ]
    then
        echo "Create dss-key for dropbear..."
        dropbearkey -t dss -f /etc/dropbear/dropbear_dss_host_key
    fi
    if [ ! -f "/etc/dropbear/dropbear_rsa_host_key" ]
    then 
        echo "Create rsa-key for dropbear..."
        dropbearkey -t rsa -f /etc/dropbear/dropbear_rsa_host_key
    fi
    /etc/init.d/dropbear start
fi

# start upnp if enabled
if [ "$INI__musicbox__enable_upnp" == "1" ]
then
    /etc/init.d/upmpdcli start
    ln -s /etc/monit/monitrc.d/upmpdcli /etc/monit/conf.d/upmpdcli > /dev/null 2>&1 || true
else
    rm /etc/monit/conf.d/upmpdcli > /dev/null 2>&1 || true
fi

# start shairport if enabled
if [ "$INI__musicbox__enable_shairport" == "1" ]
then
    /etc/init.d/shairport-sync start
    ln -s /etc/monit/monitrc.d/shairport /etc/monit/conf.d/shairport > /dev/null 2>&1 || true
else
    rm /etc/monit/conf.d/shairport > /dev/null 2>&1 || true
fi

# start spotify connect if enabled
if [ "$INI__musicbox__enable_connect" == "1" ]
then
    if [ "$INI__spotify__username" != "" -a "$INI__spotify__password" != "" ]
    then
        USER="-u $INI__spotify__username"
        PASS="-p $INI__spotify__password"
    fi
    if [ "$INI__spotify__bitrate" != "" ]
    then
        BITRATE="-b $INI__spotify__bitrate"
    fi
    ONSTART="--onevent  /opt/musicbox/mpc_stop.sh"
    DEVICE_TYPE="--device-type speaker"
    echo DAEMON_ARGS=\"-n $CLEAN_NAME $USER $PASS $BITRATE $ONSTART $DEVICE_TYPE\" > /etc/default/librespot
    /etc/init.d/librespot start
    ln -s /etc/monit/monitrc.d/librespot /etc/monit/conf.d/librespot > /dev/null 2>&1 || true
else
    rm /etc/monit/conf.d/librespot > /dev/null 2>&1 || true
fi


service monit start

if [ "$INI__network__enable_firewall" != "1" ]
then
    iptables -P INPUT ACCEPT
    iptables -P OUTPUT ACCEPT
    iptables -P FORWARD ACCEPT
    iptables -F
    iptables -X
fi

if [ "$MYIP" != "" ]
then
    # set date/time
    ntpdate ntp.ubuntu.com > /dev/null 2>&1 || true

    #mount windows share
    if [ "$INI__network__mount_address" != "" ]
    then
        #mount samba share, readonly
        echo "Mounting Windows Network drive: $INI__network__mount_address ..."
        if [ "$INI__network__mount_user" != "" ]
        then
            SMB_CREDENTIALS=user=$INI__network__mount_user,password=$INI__network__mount_password
        else
            SMB_CREDENTIALS=guest
        fi
        if [ "$INI__network__mount_options" != "" ]
        then
            SMB_OPTIONS=,$INI__network__mount_options
        else
            SMB_OPTIONS=
        fi
        mount -t cifs -o ro,${SMB_CREDENTIALS}${SMB_OPTIONS} "$INI__network__mount_address" /music/Network/
    fi
fi

# scan local music files once
if [ "$INI__musicbox__scan_once" == "1" ]
then
    #set SCAN_ONCE = false
    sed -i -e "/^\[musicbox\]/,/^\[.*\]/ s|^\(scan_once[ \t]*=[ \t]*\).*$|\1false\r|" $CONFIG_FILE
fi

# scan local/networked music files if setting is true
if [ "$INI__musicbox__scan_always" == "1" -o "$INI__musicbox__scan_once" == "1" ]
then
    echo "Scanning music-files, please wait..."
    /etc/init.d/mopidy run local scan
    #if somehow mopidy is not killed ok. kill manually
    killall -9 mopidy > /dev/null 2>&1 || true
fi

# Set the default webclient
if [ "$INI__musicbox__webclient" != "" ]
then
    WEBCLIENT_FILE=/opt/musicbox/webclient/index.html
    if ! grep -q "/$INI__musicbox__webclient/" $WEBCLIENT_FILE ; then
        sed -i "s@/.*/index.html@/$INI__musicbox__webclient/index.html@" $WEBCLIENT_FILE
    fi
fi

#start mopidy
/etc/init.d/mopidy start

if [ "$INI__network__name" != "$CLEAN_NAME" -a "$INI__network__name" != "" ]
then
    echo "WARNING: The new name of your MusicBox, $INI__network__name, is not ok! It should be max. 9 alphanumerical characters."
fi

# Print the IP address
_IP=$(ip route get 8.8.8.8 | awk '{print $NF; exit}') || true
if [ "$_IP" ]; then
    echo "***********************************************************************************"
    echo "My IP address is $_IP"
    echo "Connect to me in your browser at http://$CLEAN_NAME.local or http://$_IP"
    echo "***********************************************************************************"
fi

# renice mopidy to 19, to have less stutter when playing tracks from spotify (at the start of a track)
renice 19 $(pgrep mopidy) > /dev/null

if [ "$INI__musicbox__autoplay" -a "$INI__musicbox__autoplaymaxwait" ]
then
    if ! [[ $INI__musicbox__autoplaymaxwait =~ ^[0-9]*+$ ]] ; then
        echo "WARNING: Value specified for 'autoplaymaxwait' is not a number, defaulting to 60"
        INI__musicbox__autoplaymaxwait=60
    fi
    echo "Waiting for Mopidy to accept connections..."
    waittime=0
    while ! nc -q 1 localhost 6600 </dev/null;
        do
            sleep 1;
            waittime=$((waittime+1));
            if [ $waittime -gt $INI__musicbox__autoplaymaxwait ]
                then
                    echo "WARNING: Timeout waiting for Mopidy to start, aborting"
                    break;
            fi
        done
    if [ $waittime -le $INI__musicbox__autoplaymaxwait ]
        then
            echo "Mopidy startup complete, playing $INI__musicbox__autoplay"
            mpc add "$INI__musicbox__autoplay"
            mpc play
    fi
fi

# start mpd-watchdog if enabled
if [ "$INI__musicbox__enable_mpd_watchdog" == "1" ]
then
    /etc/init.d/mpd-watchdog start
fi

# check and clean dirty bit of vfat partition if not safely removed
fsck /dev/mmcblk0p1 -v -a -w -p > /dev/null 2>&1 || true
