#!/bin/bash
#
# MusicBox startup script
#
# This script is executed by /etc/rc.local
#
`echo "performance" > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor`

#set user vars
MB_USER=musicbox
CONFIG_FILE=/boot/config/settings.ini
NAME="MusicBox"

SSH_STOP='/etc/init.d/dropbear stop'

# Define LSB log_* functions.
. /lib/lsb/init-functions

log_use_fancy_output

log_begin_msg "Initializing MusicBox..."

# import ini parser
. /opt/musicbox/read_ini.sh

# convert windows ini to unix
dos2unix -n $CONFIG_FILE /tmp/settings.ini > /dev/null 2>&1 || true

# ini vars to mopidy settings
read_ini /tmp/settings.ini

rm /tmp/settings.ini > /dev/null 2>&1 || true

INI_READ=true

REBOOT=0

if [ "$INI__musicbox__resize_once" == "1" ]
then
    #set resize_once=false in ini file
    sed -i -e "/^\[musicbox\]/,/^\[.*\]/ s|^\(resize_once[ \t]*=[ \t]*\).*$|\1false\r|" $CONFIG_FILE
    log_progress_msg "Initalizing resize..." "$NAME"
    sh /opt/musicbox/resizefs.sh -y
    REBOOT=1
fi

#get name of device and trim
HOSTNM=`cat /etc/hostname | tr -cd "[:alnum:]"`
#get name in ini and trim
CLEAN_NAME=$(echo $INI__network__name | tr -cd "[:alnum:]")
#max 9 caracters (max netbios length = 15, + '.local')
CLEAN_NAME=$(echo $CLEAN_NAME | cut -c 1-9)

if [ "$CLEAN_NAME" == "" ]
then
    CLEAN_NAME="MusicBox"
fi

if [ "$CLEAN_NAME" != "$HOSTNM" ]
then
    #if devicename is not the same as ini, change and reboot<-->
    echo "$CLEAN_NAME" > /etc/hostname
    echo "127.0.0.1       localhost $CLEAN_NAME" > /etc/hosts
    log_end_msg "Name of device set..." "$NAME"
    REBOOT=1
fi

if [ "$REBOOT" == 1 ]
then
    reboot
    exit
fi

log_progress_msg "MusicBox name is $CLEAN_NAME" "$NAME"

# do the change password stuff
if [ "$INI__musicbox__root_password" != "" ]
then
    log_progress_msg "Setting root user Password" "$NAME"
    echo "root:$INI__musicbox__root_password" | chpasswd
    #remove password
    sed -i -e "/^\[musicbox\]/,/^\[.*\]/ s|^\(root_password[ \t]*=[ \t]*\).*$|\1\r|" $CONFIG_FILE
fi

#allow shutdown for all users
chmod u+s /sbin/shutdown

if [ "$INI__network__wifi_network" != "" ]
then
    #put wifi settings for wpa roaming
cat >/etc/wpa.conf <<EOF
    ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev
    update_config=1
    network={
        ssid="$INI__network__wifi_network"
        psk="$INI__network__wifi_password"
        scan_ssid=1
    }
EOF

    #enable wifi
    ifdown wlan0
    ifup wlan0

#    /etc/init.d/networking restart
fi

. /opt/musicbox/setsound.sh

if [ "$INI__network__workgroup" != "" ]
then
    #change smb.conf workgroup value
    sed -i "s/workgroup = .*$/workgroup = $INI__network__workgroup/ig" /etc/samba/smb.conf
    #restart samba
    /etc/init.d/samba restart
fi

#redirect 6680 to 80
#iptables -t nat -A PREROUTING -p tcp --dport 80 -j REDIRECT --to-port 6680 > /dev/null 2>&1 || true

# start SSH if enabled
if [ "$INI__network__enable_ssh" == "1" ]
then
    iptables -A INPUT -p tcp --dport 22 -j ACCEPT > /dev/null 2>&1 || true
else
    $SSH_STOP
    iptables -A INPUT -p tcp --dport 22 -j DENY > /dev/null 2>&1 || true
fi

#check networking, sleep for a while
MYIP=$(hostname -I)
while [ "$MYIP" == "" -a "$INI__network__wait_for_network" != "0" ]
do
    echo "Waiting for network..."
    echo
    sleep 5
    MYIP=$(hostname -I)
done

# set date/time
ntpdate ntp.ubuntu.com > /dev/null 2>&1 || true

#mount windows share
if [ "$INI__network__mount_address" != "" ]
then
    #mount samba share, readonly
    log_progress_msg "Mounting Windows Network drive..." "$NAME"
    MOUNT_UID=$(id -u mopidy)
    MOUNT_GID=$(getent group mopidy | cut -d: -f3)
    mount -t cifs -o sec=ntlm,ro,user=$INI__network__mount_user,password=$INI__network__mount_password,uid=$MOUNT_UID,gid=$MOUNT_GID,iocharset=utf8 $INI__network__mount_address /music/Network/
#    mount -t cifs -o sec=ntlm,ro,rsize=2048,wsize=4096,cache=strict,user=$INI__network__mount_user,password=$INI__network__mount_password $INI__network__mount_address /music/Network/
#add rsize=2048,wsize=4096,cache=strict because of usb (from raspyfi)
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
    log_progress_msg "Scanning music-files, please wait..."
    /etc/init.d/mopidy stop
    /etc/init.d/mopidy run local scan
    #if somehow mopidy is not killed ok. kill manually
    killall -9 mopidy
    /etc/init.d/mopidy start
fi

if [ "$INI__network__name" != "$CLEAN_NAME" -a "$INI__network__name" != "" ]
then
    log_warning_msg "The new name of your MusicBox, $INI__network__name, is not ok! It should be max. 9 alphanumerical caracters."
fi

# Print the IP address
_IP=$(hostname -I) || true
if [ "$_IP" ]; then
    log_progress_msg "My IP address is $_IP. Connect to MusicBox in your browser via http://$CLEAN_NAME.local or http://$_IP "
fi

if [ "$INI__musicbox__autoplay" -a "$INI__musicbox__autoplaywait" ]
then
    log_progress_msg "Waiting $INI__musicbox__autoplaywait seconds before autoplay." "$NAME"
    sleep $INI__musicbox__autoplaywait
    log_progress_msg "Playing $INI__musicbox__autoplay" "$NAME"
    mpc add "$INI__musicbox__autoplay"
    mpc play
fi

# check and clean dirty bit of vfat partition if unsavely removed
fsck /dev/mmcblk0p1 -v -a -w -p > /dev/null 2>&1 || true

log_end_msg 0
