#!/bin/sh 
#start mopidy in the background, under the user musixbox
#nice value of -10 makes the music stutter less.
#log output to /var/log/mopidy.log
nice -15 mopidy 2>&1 | tee /var/log/mopidy.log &
#mopidy 2>&1 | tee /var/log/mopidy.log &
#su musicbox -c mopidy 2>&1 | tee /var/log/mopidy.log &
