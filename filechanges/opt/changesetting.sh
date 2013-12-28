#!/bin/bash
#
#
# change the settings of Mopidy, reread ini and restart the program

if [ "$1" == "" ]
then
  echo "This is not executable manually"
  exit
fi

CONFIG_FILE=/boot/config/settingst.ini

#change ini values 
VARRAY=(
        'WIFI_NETWORK'
        'WIFI_PASSWORD'
        'SPOTIFY_USERNAME'
        'SPOTIFY_PASSWORD'
        'SPOTIFY_BITRATE'
        'LASTFM_USERNAME'
        'LASTFM_PASSWORD'
        'SOUNDCLOUD_TOKEN'
        'SOUNDCLOUD_EXPLORE'
        'GMUSIC_USERNAME'
        'GMUSIC_PASSWORD'
        'GMUSIC_DEVICE_ID'
        'MUSICBOX_PASSWORD'
        'OUTPUT'
        'NETWORK_MOUNT_ADDRESS'
        'NETWORK_MOUNT_USER'
        'NETWORK_MOUNT_PASSWORD'
        'SCAN_ONCE'
        'SCAN_ALWAYS'
        'RESIZE_ONCE'
        'WORKGROUP'
        'ROOT_PASSWORD'
        'ENABLE_SSH'
        'WAIT_FOR_NETWORK'
        'VOLUME'
    )

COUNTER=0
for ARG in $@
do
    #sed -i -e "/^\[MusicBox\]/,/^\[.*\]/ s|^\($VAR[ \t]*=[ \t]*\).*$|\1'$ARG'\r|" $CONFIG_FILE
    VAR=${VARRAY[COUNTER]}
#    sed -i -e "/^\[MusicBox\]/,/^\[.*\]/ s|^\($VAR[ \t]*=[ \t]*\).*$|\1'$ARG'\r|" $CONFIG_FILE
    echo $ARG
    COUNTER=$[$COUNTER+1]
done

exit

/opt/buildconfig.sh
/opt/restartmopidy.sh
