#!/bin/sh 
#
#
# change the settings of Mopidy and restart
# $1=spotifyuser 
# 2=pass
# 3=spotifyspeed
# 4=lastfmuser
# 5=lastfmpass
# 6=wifinetwork
# 7=wifipass
# 8=defaultsound
# 9=root/musicbox password

if [ "$1" == "" ] 
then
  echo "This is not really executable"
  exit 0
fi

INI_FILE=/boot/config/settings.ini
# sed -i "s/error_reporting = .*/error_reporting = ${ERROR_REPORTING}/" /etc/php.ini
sed -i "s/SPOTIFY_USERNAME.*=.*/SPOTIFY_USERNAME = $1/" $INI_FILE
sed -i "s/SPOTIFY_PASSWORD.*=.*/SPOTIFY_PASSWORD = $2/" $INI_FILE 
sed -i "s/SPOTIFY_BITRATE.*=.*/SPOTIFY_BITRATE = $3/" $INI_FILE 
sed -i "s/LASTFM_USERNAME.*=.*/LASTFM_USERNAME = $4/" $INI_FILE
sed -i "s/LASTFM_PASSWORD.*=.*/LASTFM_PASSWORD = $5/" $INI_FILE
sed -i "s/WIFI_NETWORK.*=.*/WIFI_NETWORK = $6/" $INI_FILE
sed -i "s/WIFI_PASSWORD.*=.*/WIFI_PASSWORD = $7/" $INI_FILE
sed -i "s/OUTPUT.*=.*/OUTPUT = $8/" $INI_FILE

reboot
exit 0