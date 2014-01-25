#!/bin/bash 
# Build the configuration file of Mopidy, from the ini-file of MusicBox
#

#set user vars
MB_USER=musicbox
MB_HOME=/home/musicbox
CONFIG_FILE=/boot/config/settings.ini

# import ini parser
. /opt/musicbox/read_ini.sh

# convert windows ini to unix
dos2unix -n $CONFIG_FILE /tmp/settings.ini > /dev/null 2>&1 || true

# ini vars to mopidy settings
read_ini /tmp/settings.ini

rm /tmp/settings.ini > /dev/null 2>&1 || true

echo "$INI__musicbox__test"
