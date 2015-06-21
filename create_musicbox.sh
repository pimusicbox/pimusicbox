#!/bin/bash

# build your own Pi MusicBox.
# reeeeeeaaallly alpha. Also see Create Pi MusicBox.rst

if [ $(id -u) != "0" ]; then
    echo "You must be the superuser to run this script" >&2
    exit 1
fi

# Install the most basic packages we need to continue
apt-get update && apt-get --yes install sudo wget unzip ntpdate

# Update the distribution to get latest fixes for audio and usb-issues
apt-get dist-upgrade -y

# Update time, to prevent update problems
ntpdate -u ntp.ubuntu.com

# Add additional package repositories
wget -q -O - http://apt.mopidy.com/mopidy.gpg | apt-key add -
wget -q -O /etc/apt/sources.list.d/mopidy.list http://apt.mopidy.com/mopidy.list
sed -i 's/stable/wheezy/' /etc/apt/sources.list.d/mopidy.list
wget -q -O - http://www.lesbonscomptes.com/key/jf@dockes.org.gpg.key | apt-key add -
cat << EOF > /etc/apt/sources.list.d/upmpdcli.list
deb http://www.lesbonscomptes.com/upmpdcli/downloads/debian/ unstable main
deb-src http://www.lesbonscomptes.com/upmpdcli/downloads/debian/ unstable main
EOF

# Agree to Intel firmware license
echo firmware-ipw2x00 firmware-ipw2x00/license/accepted boolean true | debconf-set-selections
# Enable mopidy system service
echo mopidy	mopidy/daemon	boolean	true | debconf-set-selections

# Install debian packages
apt-get update
apt-get --yes --no-install-suggests --no-install-recommends install \
    logrotate wpasupplicant ifplugd samba dos2unix cifs-utils iptables \
    iw atmel-firmware firmware-atheros firmware-brcm80211 firmware-ipw2x00 \
    firmware-iwlwifi firmware-libertas firmware-ralink firmware-realtek \
    zd1211-firmware firmware-linux firmware-linux-nonfree
    rpi-update dropbear libnss-mdns ca-certificates \
    dosfstools usbmount watchdog alsa-utils alsa-base alsa-firmware-loaders \
    avahi-utils avahi-autoipd build-essential libffi-dev libssl-dev \
    python-dev python-gst0.10 \
    gstreamer0.10-plugins-good gstreamer0.10-plugins-bad gstreamer0.10-plugins-ugly \
    gstreamer0.10-alsa gstreamer0.10-fluendo-mp3 gstreamer0.10-tools \
    mopidy mopidy-spotify mopidy-scrobbler mopidy-soundcloud mopidy-dirble \
    mopidy-alsamixer mpc ncmpcpp monit upmpdcli

# Install pip and additional python packages
curl "https://bootstrap.pypa.io/get-pip.py" -o "/tmp/get-pip.py"
python /tmp/get-pip.py
pip install requests[security]
pip install mopidy-internetarchive \
            mopidy-local-sqlite \
            mopidy-local-whoosh \
            mopidy-mobile \
            mopidy-moped \
            mopidy-mopify \
            mopidy-musicbox-webclient \
            mopidy-podcast \
            mopidy-podcast-itunes \
            mopidy-podcast-gpodder.net \
            mopidy-simple-webclient \
            mopidy-spotify-tunigo \
            mopidy-subsonic \
            mopidy-tunein \
            mopidy-youtube \
            mopidy-websettings


# mopidy-gmusic package is outdated, use development version
pip install https://github.com/hechtus/mopidy-gmusic/archive/develop.zip
# Use development versions for now (DO_NOT_RELEASE)
pip install --upgrade --no-deps https://github.com/woutervanwijk/Mopidy-MusicBox-Webclient/archive/develop.zip
pip install --upgrade --no-deps https://github.com/woutervanwijk/mopidy-websettings/archive/develop.zip

#**Configuration and Files**
cd /opt

# Get the latest stable Pi MusicBox release
wget https://github.com/woutervanwijk/Pi-MusicBox/archive/master.zip
unzip master.zip
rm master.zip
cd Pi-MusicBox-master/filechanges

# Copy some files. Backup the old ones if you’re not sure!
cp boot/config.txt /boot/config.txt
cp -R boot/config /boot/
cp -R opt/* /opt
cp -R etc/* /etc

chmod +x /etc/network/if-up.d/iptables
chown root:root /etc/firewall/musicbox_iptables
chmod 600 /etc/firewall/musicbox_iptables

# Create a symlink from the package to the /opt/defaultwebclient.
ln -fsn /usr/local/lib/python2.7/dist-packages/mopidy_musicbox_webclient/static /opt/webclient
ln -fsn /usr/local/lib/python2.7/dist-packages/mopidy_moped/static /opt/moped
ln -fsn /opt/webclient /opt/defaultwebclient

# Link the user-configurable files in /boot/config
ln -fsn /boot/config/streamuris.js /usr/local/lib/python2.7/dist-packages/mopidy_musicbox_webclient/static/js/streamuris.js
ln -fsn /boot/config/settings.ini /etc/mopidy/mopidy.conf

#Let everyone shutdown the system (to support it from the webclient):
chmod u+s /sbin/shutdown

#**Create Music directory for MP3/OGG/FLAC **
#Create the directory containing the music and the one where the network share is mounted:
mkdir -p /music/MusicBox
mkdir -p /music/Network
mkdir -p /music/USB
mkdir -p /music/USB2
mkdir -p /music/USB3
mkdir -p /music/USB4
chmod -R 777 /music
chown -R mopidy:audio /music

# Disable the SSH service (can be enabled with an option in the configuration-file)
update-rc.d ssh disable


# Update the mount options so anyone can mount the boot partition and give everyone all permissions.
#sed -i '/mmcblk0p1\s\+\/boot\s\+vfat/ s/defaults /defaults,user,umask=000/' /etc/fstab

#**Optimizations**
#For the music to play without cracks, you have to optimize your system a bit.
#For MusicBox, these are the optimizations:

#**USB Fix**
#It's tricky to get good sound out of the Pi. For USB Audio (sound cards, etc),
# it is essential to disable the so called FIQ_SPLIT. Why? It seems that audio
# at high bitrates interferes with the ethernet activity, which also runs over USB.
sed -i '1s/^/dwc_otg.fiq_fix_enable=1 dwc_otg.fiq_split_enable=0 smsc95xx.turbo_mode=N /' /boot/cmdline.txt

#cleanup
apt-get autoremove
apt-get clean
apt-get autoclean

#other options to be done by hand. Won't do it automatically on a running system
