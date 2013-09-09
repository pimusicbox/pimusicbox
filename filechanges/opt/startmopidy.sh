#!/bin/sh 
#start mopidy in the background, under the user musixbox
#nice value of -15 (lower prio!) makes the music stutter less. Strange but true
#log output to a file
nice -n18 su musicbox -c mopidy 2>&1 | tee /var/log/mopidy.log &
#su musicbox -c mopidy 2>&1 | tee /var/log/mopidy.log &
