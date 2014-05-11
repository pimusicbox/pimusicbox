#!/bin/bash
#
# MusicBox Sound configuration script
#

CONFIG_FILE=/boot/config/settings.ini

# Define LSB log_* functions.
. /lib/lsb/init-functions

log_use_fancy_output

log_begin_msg "Setting sound configuration..."

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

if [[ $INI_READ != true ]] 
then
    echo "read ini"
    # import ini parser
    . /opt/musicbox/read_ini.sh

    # convert windows ini to unix
    dos2unix -n $CONFIG_FILE /tmp/settings.ini > /dev/null 2>&1 || true

    # ini vars to mopidy settings
    read_ini /tmp/settings.ini

    rm /tmp/settings.ini > /dev/null 2>&1 || true
fi

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
#            period_time 0
#            period_size 4096
#            buffer_size 131072
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

#/etc/init.d/shairport restart
#/etc/init.d/mopidy restart
#/etc/init.d/gmediarenderer restart
