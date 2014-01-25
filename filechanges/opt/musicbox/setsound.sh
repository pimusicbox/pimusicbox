#!/bin/bash
#
# MusicBox sound configuration
#

#set user var
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
pcm.!default plug:both

ctl.!default {
  type hw
  card 0
}

pcm.both {
  type route;
  slave.pcm {
      type multi;
      slaves.a.pcm "native";
      slaves.b.pcm "hdmi";
      slaves.a.channels 2;
      slaves.b.channels 2;
      bindings.0.slave a;
      bindings.0.channel 0;
      bindings.1.slave a;
      bindings.1.channel 1;

      bindings.2.slave b;
      bindings.2.channel 0;
      bindings.3.slave b;
      bindings.3.channel 1;
  }

  ttable.0.0 1;
  ttable.1.1 1;
  ttable.0.2 1;
  ttable.1.3 1;
}

ctl.both {
  type hw;
  card 0;
}

pcm.hdmi {
   type dmix
   ipc_key 1024
   slave {
       pcm "hw:0,1"
       period_time 0
       period_size 1024
       buffer_size 16384
#       buffer_time 0
#       periods 128
       rate 48000
       channels 2
    }
    bindings {
       0 0
       1 1
    }
}

pcm.native {
   type dmix
   ipc_key 1024
   slave {
       pcm "hw:0,0"
       period_time 0
       period_size 1024
       buffer_size 65536
#       buffer_time 0
#       periods 128
       rate 48000
       channels 2
    }
    bindings {
       0 0
       1 1
    }
}

pcm.usb {
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

ctl.hdmi {
   type hw
   card 0
}

ctl.native {
   type hw
   card 0
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

