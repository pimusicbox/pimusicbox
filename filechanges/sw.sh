#!/bin/bash

OCHANNEL=`pactl list modules short | cut -f 1`
for i in $OCHANNEL; do
        echo "altes module $i"
        pactl unload-module $i
done
CHANNEL=`pactl load-module module-alsa-sink`


#echo "neues module $CHANNEL"
#if [ $? -ne 0 ]; then
#        echo "No usb"
#        exit -1
#fi

#SINK=`pactl list sinks short | grep usb | cut -f 1`
#INPUTS=`pactl list sink-inputs short | cut -f 1`
#for i in $INPUTS; do
#        echo "Verschiebe in $i nach $SINK"
#        pactl move-sink-input $i $SINK
#done