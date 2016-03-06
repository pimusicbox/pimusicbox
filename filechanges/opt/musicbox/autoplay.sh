#!/bin/sh
#
# MusicBox autoplay script
#

. /opt/musicbox/utils.sh

load_settings

if [ "$INI__musicbox__autoplay" -a "$INI__musicbox__autoplay_timeout" ]
then
    if ! [[ $INI__musicbox__autoplay_timeout =~ ^[0-9]*+$ ]]
    then
        echo "WARNING: Value specified for 'autoplay_timeout' is not a number, defaulting to 60"
        INI__musicbox__autoplay_timeout=60
    fi
    echo "Waiting for Mopidy to accept connections.."
    waittime=0
    while ! nc -q 1 localhost 6600 </dev/null;
    do
        sleep 1;
        waittime=$((waittime+1));
        if [ $waittime -gt $INI__musicbox__autoplay_timeout ]
        then
            echo 1 "Autoplay timeout"
            break;
        fi
    done
    if [ $waittime -le $INI__musicbox__autoplay_timeout ]
    then
        echo "Autoplaying $INI__musicbox__autoplay"
        # TODO: Make this more generic and support arbitrary commands.
        mpc add "$INI__musicbox__autoplay"
        mpc play
    fi
fi
