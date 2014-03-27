#!/bin/bash -e
## from http://blog.tkjelectronics.dk/2013/06/how-to-stream-video-and-audio-from-a-raspberry-pi-with-no-latency/

serverIp=$(ifconfig | grep -E 'inet.[0-9]' | grep -v '127.0.0.1' | awk '{ print $2}')
clientIp=$(echo $serverIp | cut -d '.' -f 1-3).255 # Send to all

gst-launch-1.0 -v alsasrc device=plughw:Set \
! mulawenc ! rtppcmupay ! udpsink host=$clientIp port=5001 &

kill $!