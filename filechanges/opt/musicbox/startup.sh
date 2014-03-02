#!/bin/bash
#
# MusicBox startup script
#
# This script is executed by /etc/rc.local
#

#set user vars
MB_USER=musicbox
MB_HOME=/home/musicbox
CONFIG_FILE=/boot/config/settings.ini
NAME="MusicBox"

SSH_STOP='/etc/init.d/dropbear stop'

# Define LSB log_* functions.
. /lib/lsb/init-functions

log_use_fancy_output

log_begin_msg "Initializing MusicBox..."

I2S_CARD=
USB_CARD=
INT_CARD=
HDMI_CARD=

function enumerate_alsa_cards()
{
    SYSFS_SOUND_PATH=/sys/class/sound

    # iterate over all since gaps can occur if a device is hot(un)plugged 
    for i in `seq 0 9`
    do
        card=$SYSFS_SOUND_PATH/card$i
        if [[ -d $card ]]
        then
            num=`cat $card/number`
            modalias=`cat $card/device/modalias`
            dev=(${modalias//:/ })

            case ${dev[0]} in
                platform)
                    if [[ ${dev[1]} == "bcm2835"* ]]; then
                        INT_CARD=$num
                        log_progress_msg "found internal device: card$INT_CARD" "$NAME"
                        if tvservice -s | grep -q HDMI; then
                            log_progress_msg "HDMI output connected" "$NAME"
                            HDMI_CARD=$num
                        fi
                    elif [[ ${dev[1]} == "snd-hifiberry-dac" ]]; then
                        I2S_CARD=$num
                        log_progress_msg "found i2s device: card$I2S_CARD" "$NAME"
                    fi
                    ;;
                usb)
                    USB_CARD=$num
                    log_progress_msg "found usb device: card$USB_CARD" "$NAME"
                    ;;
            esac
        fi
    done
}

# import ini parser
. /opt/musicbox/read_ini.sh

# convert windows ini to unix
dos2unix -n $CONFIG_FILE /tmp/settings.ini > /dev/null 2>&1 || true

# ini vars to mopidy settings
read_ini /tmp/settings.ini

rm /tmp/settings.ini > /dev/null 2>&1 || true

if [ "$INI__musicbox__resize_once" == "1" ]
then
    #set resize_once=false in ini file
    sed -i -e "/^\[musicbox\]/,/^\[.*\]/ s|^\(RESIZE_ONCE[ \t]*=[ \t]*\).*$|\1false\r|" $CONFIG_FILE
    log_progress_msg "Initalizing resize..." "$NAME"
    sh /opt/musicbox/resizefs.sh -y
    reboot
    exit
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
    log_end_msg "Name of device set. Rebooting..." "$NAME"
    reboot
    exit
fi

log_progress_msg "MusicBox name is $CLEAN_NAME" "$NAME"

# do the change password stuff
if [ "$INI__musicbox__musicbox_password" != "" ]
then
    log_progress_msg "Setting musicbox user Password" "$NAME"
    echo "musicbox:$INI__musicbox__musicbox_password" | chpasswd
#    echo "root:$INI__musicbox__ROOT_PASSWORD" | chpasswd
    #remove password
    sed -i -e "/^\[musicbox\]/,/^\[.*\]/ s|^\(musicbox_password[ \t]*=[ \t]*\).*$|\1\r|" $CONFIG_FILE
fi

if [ "$INI__musicbox__root_password" != "" ]
then
    log_progress_msg "Setting root user Password" "$NAME"
    echo "root:$INI__musicbox__root_password" | chpasswd
    #remove password
    sed -i -e "/^\[musicbox\]/,/^\[.*\]/ s|^\(root_password[ \t]*=[ \t]*\).*$|\1\r|" $CONFIG_FILE
fi

#put wifi settings for wpa
cat >/etc/wpa.conf <<EOF
network={
    ssid="$INI__network__wifi_network"
    psk="$INI__network__wifi_password"
}
EOF

/etc/init.d/networking restart

# if output not defined, it will automatically detect USB / HDMI / Analog in given order
# it is at this momement not possible to detect wheter a i2s device is connected hence
# i2s is only selected if explicitly given as output in the config file
OUTPUT=$(echo $INI__musicbox__output | tr "[:upper:]" "[:lower:]")
CARD=

# get alsa cards
enumerate_alsa_cards

case $OUTPUT in
    analog)
        CARD=$INT_CARD
        ;;
    hdmi)
        CARD=$HDMI_CARD
        ;;
    usb)
        CARD=$USB_CARD
        ;;
    i2s)
        CARD=$I2S_CARD
        ;;
esac

# if preferred output not found or given fall back to auto detection
if [[ -z $CARD ]];
then
    if [[ -n $USB_CARD ]]; then
        CARD=$USB_CARD
        OUTPUT="usb"
    else
        CARD=$INT_CARD
        if  [[ -n $HDMI_CARD ]]; then
            OUTPUT="hdmi"
        else
            OUTPUT="analog"
        fi
    fi
fi

log_progress_msg "Line out set to $OUTPUT card $CARD" "$NAME"

if [ "$OUTPUT" == "usb" -a "$INI__musicbox__downsample_usb" == "1" ]
# resamples to 44K because of problems with some usb-dacs on 48k (probably related to usb drawbacks of Pi)
# and extra buffer for usb
#if [ "$OUTPUT" == "usb" ]
then
cat << EOF > /etc/asound.conf
pcm.!default {
    type plug
    slave.pcm {
        type dmix
        ipc_key 1024
        slave {
            pcm "hw:$CARD"
            rate 44100
            period_time 0
            period_size 4096
            buffer_size 131072
        }
    }
}
ctl.!default {
    type hw
    card $CARD
}
EOF
else
cat << EOF > /etc/asound.conf
pcm.!default {
    type hw
    card $CARD
}
ctl.!default {
    type hw
    card $CARD
}
EOF
fi

#reset mixer
amixer cset numid=3 0 > /dev/null 2>&1 || true

#set mixer to analog output
if [ "$OUTPUT" == "analog" ]
then
    amixer cset numid=3 1 > /dev/null 2>&1 || true
fi

#set mixer to hdmi
if [ "$OUTPUT" == "hdmi" ]
then
    amixer cset numid=3 2 > /dev/null 2>&1 || true
fi

for CTL in \
        Master \
        PCM \
        Line \
        "PCM,1" \
        Wave \
        Music \
        AC97 \
        "Master Digital" \
        DAC \
        "DAC,0" \
        "DAC,1" \
        Speaker \
	Playback \
	Digital \
	Aux \
	Front \
	Center
do
	#set initial hardware volume
        amixer set -c $CARD "$CTL" 96% unmute > /dev/null 2>&1 || true 
#	 amixer set -c $CARD "$CTL" ${VOLUME}% unmute > /dev/null 2>&1 || true 
done

#set PCM of Pi higher, because it's really quit otherwise (hardware thing)
amixer -c 0 set PCM playback 98% > /dev/null 2>&1 || true &
#amixer -c 0 set PCM playback ${VOLUME}% > /dev/null 2>&1 || true &

if [ "$INI__network__workgroup" != "" ]
then
    #change smb.conf workgroup value
    sed -i "s/workgroup = .*$/workgroup = $INI__network__workgroup/ig" /etc/samba/smb.conf
    #restart samba
    /etc/init.d/samba restart
fi

#start shairport in the background
if [ "$OUTPUT" == "usb" ]
then
    #start shairport for usb (alsa device 1,0)
    su $MB_USER -c "/opt/shairport/shairport.pl -d -a $CLEAN_NAME --ao_driver alsa --ao_devicename \"hw:1,0\" --play_prog=\"ncmpcpp stop \"" > /dev/null 2>&1 &
#    su $MB_USER -c "/opt/shairport/shairport.pl -d -a $CLEAN_NAME --ao_driver alsa --ao_devicename \"hw:1,0\"" > /dev/null 2>&1 &
else
    #start shairport normally
#    /opt/shairport/shairport.pl -d -a MusicBox > /dev/null 2>&1 &
    su $MB_USER -c "/opt/shairport/shairport.pl -d -a $CLEAN_NAME --play_prog=\"ncmpcpp stop \"" > /dev/null 2>&1 &
#    su $MB_USER -c "/opt/shairport/shairport.pl -d -a $CLEAN_NAME" > /dev/null 2>&1 &
fi

#redirect 6680 to 80
iptables -t nat -A PREROUTING -p tcp --dport 80 -j REDIRECT --to-port 6680 > /dev/null 2>&1 || true

# start SSH if enabled
if [ "$INI__network__enable_ssh" == "1" ]
then
#    $SSH_COMMAND start
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
    mount -t cifs -o sec=ntlm,ro,rsize=2048,wsize=4096,cache=strict,user=$INI__network__mount_user,password=$INI__network__mount_password $INI__network__network_mount_address /music/Network/
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
    log_progress_msg "Scanning music-files, please wait..." "$NAME"
    /etc/init.d/mopidy force-reload
fi

if [ "$INI__network__name" != "$CLEAN_NAME" -a "$INI__network__name" != "" ]
then
    log_warning_msg "The new name of your MusicBox, $INI__network__name, is not ok! It should be max. 9 alphanumerical caracters." "$NAME"
fi

# Print the IP address
_IP=$(hostname -I) || true
if [ "$_IP" ]; then
    log_progress_msg "My IP address is $_IP. Connect to MusicBox in your browser via http://$CLEAN_NAME.local or http://$_IP " "$NAME"
fi

log_end_msg 0
