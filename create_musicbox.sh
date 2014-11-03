#!/bin/bash

# build your own Pi MusicBox.
# reeeeeeaaallly alpha.

#Install the packages you need to continue:
apt-get update && apt-get --yes install sudo wget unzip mc

#Next, issue this command to update the distribution. 
#This is good because newer versions have fixes for audio and usb-issues:

apt-get dist-upgrade -y

#Next, configure the installation of Mopidy, the music server that is the heart of MusicBox.
wget -q -O - http://apt.mopidy.com/mopidy.gpg | sudo apt-key add -
wget -q -O /etc/apt/sources.list.d/mopidy.list http://apt.mopidy.com/mopidy.list

#update time, to prevent update problems
ntpdate -u ntp.ubuntu.com

#Then install all packages we need with this command:
sudo apt-get update && sudo apt-get --yes install logrotate alsa-utils python-cherrypy3 python-ws4py wpasupplicant python-spotify gstreamer0.10-alsa ifplugd gstreamer0.10-fluendo-mp3 gstreamer0.10-tools samba dos2unix avahi-utils alsa-base python-pylast cifs-utils avahi-autoipd libnss-mdns ntpdate ca-certificates ncmpcpp rpi-update linux-wlan-ng alsa-firmware-loaders iw atmel-firmware firmware-atheros firmware-brcm80211 firmware-ipw2x00 firmware-iwlwifi firmware-libertas firmware-linux firmware-linux-nonfree firmware-ralink firmware-realtek zd1211-firmware linux-wlan-ng-firmware alsa-firmware-loaders dropbear python-pip usbmount mopidy

#mopidy from pip
yes | pip install mopidy mopidy-spotify mopidy-scrobbler mopidy-soundcloud mopidy-dirble mopidy-gmusic mopidy-subsonic mopidy-audioaddict

#**Configuration and Files**
cd /opt

#Get the files of the Pi MusicBox project
wget https://github.com/woutervanwijk/Pi-MusicBox/archive/master.zip

#Unpack the zip-file and remove it if you want.
unzip master.zip
rm master.zip

#Then go to the directory which you just unpacked, subdirectory ‘filechanges’:
cd Pi-MusicBox-master/filechanges

#Now we are going to copy some files. Backup the old ones if you’re not sure!
#This sets up the boot and opt directories:
#manually copy cmdline.txt and config.txt if you want
mkdir /boot/config
cp -R boot/config /boot/config
cp -R opt/* /opt

#Make the system work:
cp -R etc/* /etc

#**Install webclient**
cd /opt

#Get the webclient from github:
wget https://github.com/woutervanwijk/Mopidy-Webclient/archive/develop.zip
#Unpack and copy:
unzip develop.zip
rm develop.zip

cd Mopidy-Webclient-develop/
cp -R webclient /opt

#Next, create a symlink from the package to the /opt/defaultwebclient. This is done because you could install other webclients and just point the link to the newly installed client:
ln -s /opt/webclient /opt/defaultwebclient

#**Add the MusicBox user**
#Mopidy can run under the user musicbox. Add it.

useradd -m musicbox
passwd musicbox

#Add the user to the group audio:
usermod -a -G audio,avahi musicbox
#Create a couple of directories inside the user dir:
mkdir -p /home/musicbox/.config/mopidy
mkdir -p /home/musicbox/.cache/mopidy
mkdir -p /home/musicbox/.local/share/mopidy
chown -R musicbox:musicbox /home/musicbox

#**Create Music directory for MP3/OGG/FLAC **
#Create the directory containing the music and the one where the network share is mounted:
mkdir -p /music/SD\ Card
mkdir -p /music/Network
mkdir -p /music/USB
mkdir -p /music/USB2
mkdir -p /music/USB3
mkdir -p /music/USB4
chmod -R 777 /music
chown -R musicbox:musicbox /music

#Disable the SSH service for more security if you want (it can be started with an option in the configuration-file):
update-rc.d ssh disable

ln -s /boot/config/settings.ini /home/musicbox/.config/mopidy/mopidy.conf
ln -s /boot/config/settings.ini /var/lib/mopidy/.config/mopidy/mopidy.conf

#**AirTunes**
#For AirPlay/AirTunes audio streaming, you have to compile and install Shairport. First issue this command to install the libraries needed to build it:

sudo apt-get --yes install libcrypt-openssl-rsa-perl libio-socket-inet6-perl libwww-perl libssl-dev libao-dev

cd ~
#Build an updated version of Perl-Net
git clone https://github.com/njh/perl-net-sdp.git perl-net-sdp
cd perl-net-sdp
perl Build.PL
sudo ./Build
sudo ./Build test
sudo ./Build install

#Build Shairport:
cd ..
git clone https://github.com/hendrikw82/shairport.git
cd shairport
make

#Next, move the new shairport directory to /opt
mv shairport /opt

#Finally, copy libao.conf from the Pi MusicBox files to /etc :
cp /opt/Pi-MusicBox-master/filechanges/etc/libao.conf /etc

#**Optimizations**
#For the music to play without cracks, you have to optimize your system a bit. 
#For MusicBox, these are the optimizations:

#**USB Fix**
#It's tricky to get good sound out of the Pi. For USB Audio (sound cards, etc), 
# it is essential to disable the so called FIQ_SPLIT. Why? It seems that audio 
# at high nitrates interferes with the ethernet activity, which also runs over USB. 
# These options are added at the beginning of the cmdline.txt file in /boot
sed -i '1s/^/dwc_otg.fiq_fix_enable=1 dwc_otg.fiq_split_enable=0 smsc95xx.turbo_mode=N /' /boot/cmdline.txt 

#cleanup
apt-get autoremove
apt-get clean
apt-get autoclean

#other options to be done by hand. Won't do it automatically on a running system

exit
