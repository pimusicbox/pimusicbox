#!/bin/sh
#
# MusicBox autoplay script
#

. /opt/musicbox/utils.sh

AUTOPLAY_TIMEOUT=60
load_settings

if [ "$INI__musicbox__autoplay" != "" ]
then
    echo "Waiting for Mopidy to accept connections.."
    waittime=0
    while ! nc -q 1 localhost 6600 </dev/null;
    do
        sleep 1;
        waittime=$((waittime+1));
        if [ $waittime -gt $AUTOPLAY_TIMEOUT ]
        then
            echo "Autoplay timed out after $AUTOPLAY_TIMEOUT secs"
            exit 1;
        fi
    done
    if [ -f "$INI__musicbox__autoplay" -a -r "$INI__musicbox__autoplay" ]
    then
        echo "Running script $INI__musicbox__autoplay"
        . "$INI__musicbox__autoplay"
    else
        echo "Autoplaying $INI__musicbox__autoplay"
        mpc add "$INI__musicbox__autoplay"
        mpc play
    fi
fi
