#!/bin/bash

# build your own Pi MusicBox.
# reeeeeeaaallly alpha. Also see Create Pi MusicBox.rst

#Update the mount options so anyone can mount the boot partition and give everyone all permissions.
sed -i '/mmcblk0p1\s\+\/boot\s\+vfat/ s/defaults /defaults,user,umask=000/' /etc/fstab

#make sure no unneeded packages are installed
echo -e 'APT::Install-Recommends "0";\nAPT::Install-Suggests "0";\n' > /etc/apt/apt.conf

#Install the packages you need to continue:
apt-get update && apt-get --yes install sudo wget unzip mc

#Next, issue this command to update the distribution.
#This is good because newer versions have fixes for audio and usb-issues:

apt-get dist-upgrade -y

#Next, configure the installation of Mopidy, the music server that is the heart of MusicBox.
#wget -q -O - http://apt.mopidy.com/mopidy.gpg | sudo apt-key add -
#wget -q -O /etc/apt/sources.list.d/mopidy.list http://apt.mopidy.com/mopidy.list

#update time, to prevent update problems
ntpdate -u ntp.ubuntu.com

#Then install all packages we need with this command:
sudo apt-get update && sudo apt-get --yes --no-install-suggests --no-install-recommends install logrotate alsa-utils wpasupplicant gstreamer0.10-alsa ifplugd gstreamer0.10-fluendo-mp3 gstreamer0.10-tools samba dos2unix avahi-utils alsa-base cifs-utils avahi-autoipd libnss-mdns ntpdate ca-certificates ncmpcpp rpi-update linux-wlan-ng alsa-firmware-loaders iw atmel-firmware firmware-atheros firmware-brcm80211 firmware-ipw2x00 firmware-iwlwifi firmware-libertas firmware-linux firmware-linux-nonfree firmware-ralink firmware-realtek zd1211-firmware linux-wlan-ng-firmware iptables build-essential python-dev python-pip python-gst0.10 gstreamer0.10-plugins-good gstreamer0.10-plugins-bad gstreamer0.10-plugins-ugly usbmount monit upmpdcli watchdog dropbear mpc dosfstools

#mopidy from pip
sudo pip install -U mopidy mopidy-spotify mopidy-local-sqlite mopidy-local-whoosh mopidy-scrobbler mopidy-soundcloud mopidy-dirble mopidy-tunein mopidy-gmusic mopidy-subsonic mopidy-mobile mopidy-moped mopidy-musicbox-webclient mopidy-websettings mopidy-internetarchive mopidy-podcast mopidy-podcast-itunes mopidy-podcast-gpodder.net Mopidy-Simple-Webclient mopidy-somafm mopidy-spotify-tunigo mopidy-youtube

#Google Music works a lot better if you use the development version of mopidy-gmusic:
sudo pip install https://github.com/hechtus/mopidy-gmusic/archive/develop.zip

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

chmod +x /etc/network/if-up.d/iptables
chown root:root /etc/firewall/musicbox_iptables
chmod 600 /etc/firewall/musicbox_iptables

#Next, create a symlink from the package to the /opt/defaultwebclient.
ln -fsn /usr/local/lib/python2.7/dist-packages/mopidy_musicbox_webclient/static /opt/webclient
ln -fsn /usr/local/lib/python2.7/dist-packages/mopidy_moped/static /opt/moped
ln -fsn /opt/webclient /opt/defaultwebclient

#Remove the streamuris.js and point it to the file in /boot/config
mv /usr/local/lib/python2.7/dist-packages/mopidy_musicbox_webclient/static/js/streamuris.js streamuris.bk
ln -fsn /boot/config/streamuris.js /usr/local/lib/python2.7/dist-packages/mopidy_musicbox_webclient/static/js/streamuris.js

#Let everyone shutdown the system (to support it from the webclient):
chmod u+s /sbin/shutdown

#**Add the mopidy user**
#Mopidy runs under the user mopidy. Add it.
useradd -m mopidy
passwd -l mopidy

#Add the user to the group audio:
usermod -a -G audio mopidy

#Create a couple of directories inside the user dir:
mkdir -p /home/mopidy/.config/mopidy
mkdir -p /home/mopidy/.cache/mopidy
mkdir -p /home/mopidy/.local/share/mopidy
chown -R mopidy:mopidy /home/mopidy

#**Create Music directory for MP3/OGG/FLAC **
#Create the directory containing the music and the one where the network share is mounted:
mkdir -p /music/MusicBox
mkdir -p /music/Network
mkdir -p /music/USB
mkdir -p /music/USB2
mkdir -p /music/USB3
mkdir -p /music/USB4
chmod -R 777 /music
chown -R mopidy:mopidy /music

#Disable the SSH service for more security if you want (it can be started with an option in the configuration-file):
update-rc.d ssh disable

#Link the mopidy configuration to the new one in /boot/config
ln -fsn /boot/config/settings.ini /home/mopidy/.config/mopidy/mopidy.conf
mkdir -p /var/lib/mopidy/.config/mopidy
ln -fsn /boot/config/settings.ini /var/lib/mopidy/.config/mopidy/mopidy.conf

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
apt-get remove build-essential python-pip
apt-get autoremove
apt-get clean
apt-get autoclean

#other options to be done by hand. Won't do it automatically on a running system
