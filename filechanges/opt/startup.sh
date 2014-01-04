#!/bin/bash
#
# MusicBox startup script
#
# This script is executed by /etc/rc.local
#

#set user var
SSH_COMMAND='/etc/init.d/dropbear start > /dev/null 2>&1 || true'

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
                        echo "found internal device: card$INT_CARD"
                        if tvservice -s | grep -q HDMI; then
                            echo "HDMI output connected"
                            HDMI_CARD=$num
                        fi
                    elif [[ ${dev[1]} == "snd-hifiberry-dac" ]]; then
                        I2S_CARD=$num
                        echo "found i2s device: card$I2S_CARD"
                    fi
                    ;;
                usb)
                    USB_CARD=$num
                    echo "found usb device: card$USB_CARD"
                    ;;
            esac
        fi
    done
}

#import script for reading ini and building Mopidy config
. /opt/buildconfig.sh

if [ "$INI__MusicBox__RESIZE_ONCE" == "true" ]
then
    #set RESIZE_ONCE=false in ini file
    sed -i -e "/^\[MusicBox\]/,/^\[.*\]/ s|^\(RESIZE_ONCE[ \t]*=[ \t]*\).*$|\1'false'\r|" $CONFIG_FILE
    sh /opt/resizefs.sh -y
    reboot
    exit
fi

#get name of device and trim
HOSTNM=`cat /etc/hostname | tr -cd "[:alnum:]"`
#get name in ini and trim
CLEAN_NAME=$(echo $INI__MusicBox__NAME | tr -cd "[:alnum:]")
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
    reboot
    exit
fi

echo
echo "MusicBox name is $CLEAN_NAME"
echo

# do the change password stuff
if [ "$INI__MusicBox__MUSICBOX_PASSWORD" != "" ]
then
    echo "musicbox:$INI__MusicBox__MUSICBOX_PASSWORD" | chpasswd
    echo "root:$INI__MusicBox__ROOT_PASSWORD" | chpasswd
    #remove password
    sed -i -e "/^\[MusicBox\]/,/^\[.*\]/ s|^\(MUSICBOX_PASSWORD[ \t]*=[ \t]*\).*$|\1''\r|" $CONFIG_FILE
fi

if [ "$INI__MusicBox__ROOT_PASSWORD" != "" ]
then
    echo "root:$INI__MusicBox__ROOT_PASSWORD" | chpasswd
    #remove password
    sed -i -e "/^\[MusicBox\]/,/^\[.*\]/ s|^\(ROOT_PASSWORD[ \t]*=[ \t]*\).*$|\1''\r|" $CONFIG_FILE
fi

#put wifi settings for wpa
cat >/etc/wpa.conf <<EOF
network={
    ssid="$INI__MusicBox__WIFI_NETWORK"
    psk="$INI__MusicBox__WIFI_PASSWORD"
}
EOF

# if output not defined, it will automatically detect USB / HDMI / Analog in given order
# it is at this momement not possible to detect wheter a i2s device is connected hence
# i2s is only selected if explicitly given as output in the config file
OUTPUT=$(echo $INI__MusicBox__OUTPUT | tr "[:upper:]" "[:lower:]")
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

echo
echo "Line out set to $OUTPUT card $CARD"
echo

# set default soundcard in Alsa
if [ "$OUTPUT" == "usb" -a "$INI__MusicBox__KEEP_SAMPLE_RATE" == "" ]
then
# resamples to 44K because of problems with some usb-dacs on 48k (probably related to usb drawbacks of Pi)
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

if [ "$INI__MusicBox__WORKGROUP" != "" ]
then
    #change smb.conf workgroup value
    sed -i "s/workgroup = .*$/workgroup = $INI__MusicBox__WORKGROUP/ig" /etc/samba/smb.conf
    #restart samba
    /etc/init.d/samba restart
fi

#check networking, sleep for a while
MYIP=$(hostname -I)
while [ "$MYIP" == "" -a "$INI__MusicBox__WAIT_FOR_NETWORK" != "false" ]
do
    echo "Waiting for network..."
    echo
    sleep 5
    MYIP=$(hostname -I)
done

# set date/time
ntpdate ntp.ubuntu.com > /dev/null 2>&1 || true

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

#mount windows share
if [ "$INI__MusicBox__NETWORK_MOUNT_ADDRESS" != "" ]
then
    #mount samba share, readonly
    echo
    echo "Mounting Windows Network drive..."
    echo
    mount -t cifs -o ro,rsize=2048,wsize=4096,cache=strict,user=$INI__MusicBox__NETWORK_MOUNT_USER,password=$INI__MusicBox__NETWORK_MOUNT_PASSWORD $INI__MusicBox__NETWORK_MOUNT_ADDRESS /music/network/
#add rsize=2048,wsize=4096,cache=strict because of usb (from raspyfi)
fi

# start SSH if enabled
if [ "$INI__MusicBox__ENABLE_SSH" == "true" ]
then
    $SSH_COMMAND
    iptables -A INPUT -p tcp --dport 22 -j ACCEPT > /dev/null 2>&1 || true
else
    iptables -A INPUT -p tcp --dport 22 -j DENY > /dev/null 2>&1 || true
fi

# scan local music files once (by setting the ini value)
if [ "$INI__MusicBox__SCAN_ONCE" == "true" ]
then
    #set SCAN_ONCE = false
    sed -i -e "/^\[MusicBox\]/,/^\[.*\]/ s|^\(SCAN_ONCE[ \t]*=[ \t]*\).*$|\1'false'\r|" $CONFIG_FILE
fi

# scan local/networked music files if setting is true
if [ "$INI__MusicBox__SCAN_ALWAYS" == "true" -o "$INI__MusicBox__SCAN_ONCE" == "true" ]
then
    echo
    echo "Scanning music-files, please wait.... The scanned files will be displayed. You can ignore warnings about non-music files."
    echo
    touch /home/musicbox/.cache/mopidy/tag_cache
    mopidy-scan
# new command
#  mopidy local scan
    chown musicbox:musicbox /home/musicbox/.cache/mopidy/tag_cache

# create one big local playlist
#    find /music -type f -iname *.mp3 -o -iname *.ogg -o -iname *.flac > '/home/musicbox/.local/share/mopidy/local/playlists/Local Playlist.m3u'
fi

if [ "$INI__MusicBox__NAME" != "$CLEAN_NAME" -a "$INI__MusicBox__NAME" != "" ]
then
    echo
    echo "The new name of your MusicBox, $INI__MusicBox__NAME, is not ok! It should be max. 9 alphanumerical caracters."
    echo
fi

# Print the IP address
_IP=$(hostname -I) || true
if [ "$_IP" ]; then
    echo
    echo "My IP address is $_IP"
    echo
    echo "Connect to MusicBox in your browser via http://$CLEAN_NAME.local or http://$_IP"
    echo
fi

#start mopidy 
/opt/startmopidy.sh > /dev/null 2>&1 || true
#/opt/startmopidy.sh
