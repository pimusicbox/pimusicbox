#!/bin/bash 
# Build the configuration file of Mopidy, from the ini-file of MusicBox
#

#set user vars
MB_USER=musicbox
MB_HOME=/home/musicbox
CONFIG_FILE=/boot/config/settings.ini

# import ini parser
. /opt/read_ini.sh

# convert windows ini to unix
dos2unix -n $CONFIG_FILE /tmp/settings.ini > /dev/null 2>&1 || true

# ini vars to mopidy settings
read_ini /tmp/settings.ini MusicBox

rm /tmp/settings.ini > /dev/null 2>&1 || true

#check spotify
ENABLE_SPOTIFY='true'
if [ "$INI__MusicBox__SPOTIFY_USERNAME" == "" -o "$INI__MusicBox__SPOTIFY_PASSWORD" == "" ]
then
     ENABLE_SPOTIFY='false'
     echo
     echo "Disabled Spotify. Missing username and/or password..."
     echo
fi

#check bitrate
SPOTIFY_BITRATE=160
if [ "$INI__MusicBox__SPOTIFY_BITRATE" == "320" ]
then
    SPOTIFY_BITRATE=320
fi
if [ "$INI__MusicBox__SPOTIFY_BITRATE" == "96" ]
then
    SPOTIFY_BITRATE=96
fi

#check lastfm
ENABLE_LASTFM='true'
if [ "$INI__MusicBox__LASTFM_USERNAME" == "" -o "$INI__MusicBox__LASTFM_PASSWORD" == "" ]
then
     ENABLE_LASTFM='false'
     echo
     echo "Disabled LastFM. Missing username and/or password..."
     echo
fi

#check soundcloud
ENABLE_SOUNDCLOUD='true'
if [ "$INI__MusicBox__SOUNDCLOUD_TOKEN" == "" ]
then
     ENABLE_SOUNDCLOUD='false'
     echo
     echo "Disabled SoundCloud. Missing token..."
     echo
fi

SOUNDCLOUD_EXPLORE=''
if [ "$INI__MusicBox__SOUNDCLOUD_EXPLORE" != "" ]
then
     SOUNDCLOUD_EXPLORE="explore = $INI__MusicBox__SOUNDCLOUD_EXPLORE"
fi

#check gmusic
ENABLE_GMUSIC='true'
if [ "$INI__MusicBox__GMUSIC_USERNAME" == "" -o "$INI__MusicBox__GMUSIC_PASSWORD" == "" ]
then
     ENABLE_GMUSIC='false'
     echo
     echo "Disabled Google Music. Missing username and/or password..."
     echo
fi

#set volume
VOLUME=85

if [ "$INI__MusicBox__VOLUME" != '' ]
then
    VOLUME=$INI__MusicBox__VOLUME
fi

#put settings in mopidy
rm $MB_HOME/.config/mopidy/mopidy.conf > /dev/null 2>&1 || true

cat >$MB_HOME/.config/mopidy/mopidy.conf <<EOF
[spotify]
enabled = $ENABLE_SPOTIFY
username = $INI__MusicBox__SPOTIFY_USERNAME
password = $INI__MusicBox__SPOTIFY_PASSWORD
bitrate = $SPOTIFY_BITRATE

[scrobbler]
enabled = $ENABLE_LASTFM
username = $INI__MusicBox__LASTFM_USERNAME
password = $INI__MusicBox__LASTFM_PASSWORD

[mpd]
hostname = 0.0.0.0

[local]
media_dir = /music
tag_cache_file = $MB_HOME/.cache/mopidy/tag_cache

[mpris]
enabled = false

[http]
enabled = true
hostname = 0.0.0.0
port = 6680
static_dir = /opt/defaultwebclient

[audio]
output = alsasink
mixer = software
volume = $VOLUME

[stream]
enabled = true
protocols =
    http
    https
    mms
    rtmp
    rtmps
    rtsp

[soundcloud]
enabled = $ENABLE_SOUNDCLOUD
auth_token = $INI__MusicBox__SOUNDCLOUD_TOKEN
$SOUNDCLOUD_EXPLORE

[gmusic]
enabled = $ENABLE_GMUSIC
username = $INI__MusicBox__GMUSIC_USERNAME
password = $INI__MusicBox__GMUSIC_PASSWORD
deviceid = $INI__MusicBox__GMUSIC_DEVICE_ID

EOF
