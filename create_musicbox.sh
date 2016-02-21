#!/bin/bash -e

# build your own Pi MusicBox.
# reeeeeeaaallly alpha. Also see Create Pi MusicBox.rst

#update time, to prevent update problems
ntpdate -u ntp.ubuntu.com

#Update the mount options so anyone can mount the boot partition and give everyone all permissions.
sed -i '/mmcblk0p1\s\+\/boot\s\+vfat/ s/defaults /defaults,user,umask=000/' /etc/fstab

#make sure no unneeded packages are installed
echo -e 'APT::Install-Recommends "0";\nAPT::Install-Suggests "0";\n' > /etc/apt/apt.conf

#Install the packages you need to continue:
apt-get update && apt-get --yes install sudo wget unzip mc

#Next, issue this command to update the distribution.
#This is good because newer versions have fixes for audio and usb-issues:
sudo apt-get dist-upgrade -y

#Next, configure the installation of Mopidy, the music server that is the heart of MusicBox.
sudo wget -q -O - http://apt.mopidy.com/mopidy.gpg | sudo apt-key add -
sudo wget -q -O /etc/apt/sources.list.d/mopidy.list http://apt.mopidy.com/mopidy.list

#Then install all packages we need with this command:
sudo apt-get update && sudo apt-get --yes --no-install-suggests --no-install-recommends install logrotate alsa-utils wpasupplicant gstreamer0.10-alsa ifplugd gstreamer0.10-fluendo-mp3 gstreamer0.10-tools samba dos2unix avahi-utils alsa-base cifs-utils avahi-autoipd libnss-mdns ntpdate ca-certificates ncmpcpp rpi-update alsa-firmware-loaders iw atmel-firmware firmware-atheros firmware-brcm80211 firmware-iwlwifi firmware-libertas firmware-linux firmware-linux-nonfree firmware-ralink firmware-realtek zd1211-firmware iptables build-essential python-dev python-pip python-gst0.10 gstreamer0.10-plugins-good gstreamer0.10-plugins-bad gstreamer0.10-plugins-ugly usbmount monit watchdog dropbear mpc dosfstools libffi6 libffi-dev libssl-dev python-spotify libspotify-dev gstreamer1.0-tools gir1.2-gstreamer-1.0 gir1.2-gst-plugins-base-1.0
#sudo apt-get install firmware-ipw2x00 # requires interaction on license agreement
#sudo apt-get install upmpdcli # E: Unable to locate package upmpdcli

#mopidy from pip
sudo pip install -U utils mopidy mopidy-local-sqlite mopidy-local-whoosh mopidy-scrobbler mopidy-soundcloud mopidy-dirble mopidy-tunein mopidy-gmusic mopidy-subsonic mopidy-mobile mopidy-moped mopidy-musicbox-webclient mopidy-websettings mopidy-internetarchive mopidy-podcast mopidy-podcast-itunes mopidy-podcast-gpodder.net Mopidy-Simple-Webclient mopidy-somafm mopidy-youtube pyspotify Mopidy-Spotify mopidy-spotify-tunigo

#Avoids "Double requirement given" error
sudo pip install -U mopidy-gmusic

#**Configuration and Files**

#Now we are going to copy some files. Backup the old ones if you’re not sure!
#This sets up the boot and opt directories:
#manually copy cmdline.txt and config.txt if you want
sudo mkdir /boot/config
sudo cp filechanges/boot/config/settings.ini /boot/config/settings.ini
sudo cp filechanges/boot/config/streamuris.js /boot/config/streamuris.js
sudo cp -R filechanges/opt/* /opt

#Make the system work:
sudo cp -R filechanges/etc/* /etc
sudo chmod +x /etc/network/if-up.d/iptables
sudo chown root:root /etc/firewall/musicbox_iptables
sudo chmod 600 /etc/firewall/musicbox_iptables

#Next, create a symlink from the package to the /opt/defaultwebclient.
sudo ln -fsn /usr/local/lib/python2.7/dist-packages/mopidy_musicbox_webclient/static /opt/webclient
sudo ln -fsn /usr/local/lib/python2.7/dist-packages/mopidy_moped/static /opt/moped
sudo ln -fsn /opt/webclient /opt/defaultwebclient

#Remove the streamuris.js and point it to the file in /boot/config
sudo mv /usr/local/lib/python2.7/dist-packages/mopidy_musicbox_webclient/static/js/streamuris.js streamuris.js.bk
sudo ln -fsn /boot/config/streamuris.js /usr/local/lib/python2.7/dist-packages/mopidy_musicbox_webclient/static/js/streamuris.js

#Let everyone shutdown the system (to support it from the webclient):
sudo chmod u+s /sbin/shutdown

#**Add the mopidy user**
#Mopidy runs under the user mopidy. Add it.
sudo useradd -m mopidy && sudo passwd -l mopidy

#Add the user to the group audio/video groups:
sudo usermod -a -G audio mopidy
sudo usermod -a -G video mopidy

#Create a couple of directories inside the user dir:
sudo mkdir -p /home/mopidy/.config/mopidy
sudo mkdir -p /home/mopidy/.cache/mopidy
sudo mkdir -p /home/mopidy/.local/share/mopidy
sudo chown -R mopidy:mopidy /home/mopidy

#**Create Music directory for MP3/OGG/FLAC **
#Create the directory containing the music and the one where the network share is mounted:
sudo mkdir -p /music/MusicBox
sudo mkdir -p /music/Network
sudo mkdir -p /music/USB
sudo mkdir -p /music/USB2
sudo mkdir -p /music/USB3
sudo mkdir -p /music/USB4
sudo chmod -R 777 /music
sudo chown -R mopidy:mopidy /music

#Link the mopidy configuration to the new one in /boot/config
sudo ln -fsn /boot/config/settings.ini /home/mopidy/.config/mopidy/mopidy.conf
sudo mkdir -p /var/lib/mopidy/.config/mopidy
sudo ln -fsn /boot/config/settings.ini /var/lib/mopidy/.config/mopidy/mopidy.conf

# Create Log file
sudo mkdir /var/log/mopidy/
sudo touch /var/log/mopidy/mopidy.log
sudo chown mopidy:mopidy /var/log/mopidy/mopidy.log

#**Optimizations**
#For the music to play without cracks, you have to optimize your system a bit.
#For MusicBox, these are the optimizations:

#**USB Fix**
#It's tricky to get good sound out of the Pi. For USB Audio (sound cards, etc),
# it is essential to disable the so called FIQ_SPLIT. Why? It seems that audio
# at high nitrates interferes with the ethernet activity, which also runs over USB.
# These options are added at the beginning of the cmdline.txt file in /boot
sudo sed -i '1s/^/dwc_otg.fiq_fix_enable=1 dwc_otg.fiq_split_enable=0 smsc95xx.turbo_mode=N /' /boot/cmdline.txt

#run
sudo systemctl enable mopidy
sudo systemctl start mopidy
sudo service mopidy run local scan
curl -d '{"jsonrpc": "2.0", "id": 1, "method": "core.library.refresh"}' http://localhost:6680/mopidy/rpc

#cleanup
sudo apt-get autoremove --yes
sudo apt-get remove --yes build-essential python-pip
sudo apt-get clean
sudo apt-get autoclean

#Disable the SSH service for more security if you want (it can be started with an option in the configuration-file):
#update-rc.d ssh disable

#other options to be done by hand. Won't do it automatically on a running system
