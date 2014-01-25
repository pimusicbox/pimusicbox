#!/bin/sh 
#start mopidy in the background, under the user musixbox
cd /home/musicbox
#log output to /var/log/mopidy.log
touch /var/log/mopidy.log
chown musicbox:musicbox /var/log/mopidy.log

#su musicbox -c "mopidy --save-debug-log 2>&1 | tee /var/log/mopidy.log" &
su musicbox -c "mopidy 2>&1 | tee /var/log/mopidy.log" &
#su musicbox -c "mopidy | tee /var/log/mopidy.log" &

# wait for process to start and renice
#sleep 10
#renice 5 -p `echo \`pgrep mopidy\``
