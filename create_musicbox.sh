#!/bin/bash

PIMUSICBOX_BRANCH='develop'
PIMUSICBOX_FILES='/tmp/pimusicbox/filechanges'

if [ $(id -u) -ne 0 ]; then
    printf "** You must be the superuser to run this script **\n"
    exit 1
fi
if ! grep -q Raspbian /etc/*-release; then
    printf "** Error: expected raspbian **\n"
    exit 1
fi

printf "**********************************\n"
printf "*** Build your own PiMusicBox. ***\n"
printf "**********************************\n"

# Download Pi MusicBox files if not already available.
if [ "$PIMUSICBOX_FILES" != "" ]; then
    if [ ! -d "$PIMUSICBOX_FILES" ]; then
        printf "** Unable to find pimusicbox files at $PIMUSICBOX_FILES.\n"
        printf "** Downloading $PIMUSICBOX_BRANCH branch from github...\n"
        cd /tmp
        wget -q "https://github.com/pimusicbox/pimusicbox/archive/${PIMUSICBOX_BRANCH}.zip" 
        unzip -- "${PIMUSICBOX_BRANCH}.zip"
        rm -- "${PIMUSICBOX_BRANCH}.zip"
        mv -- "pimusicbox-${PIMUSICBOX_BRANCH}/filechanges" "$PIMUSICBOX_FILES"
    fi
    if [ ! -d "$PIMUSICBOX_FILES" ]; then
        printf "** Failed to find pimusicbox files at $PIMUSICBOX_FILES.\n"
        exit 1
    fi

    printf "\n ** Found pimusicbox files at $PIMUSICBOX_FILES\n"
else
    printf "\n ** Warning: No pimusicbox files specified.\n"
fi

# Prevent unhelpful services from starting during install.
cat > /usr/sbin/policy-rc.d << EOF
#!/bin/sh
exit 101
EOF
chmod a+x /usr/sbin/policy-rc.d

printf "\n ** Installing Debian packages...\n\n"

# Install the most basic packages we need to continue
apt-get update && apt-get --yes install sudo wget unzip ntpdate lsb-release

# Update time, to prevent update problems
ntpdate -u ntp.ubuntu.com

# Remove big packages we don't want and save some space
apt-get --yes remove --purge wolfram-engine sonic-pi dhcpcd5

# Update the distribution to get latest fixes for audio and usb-issues
apt-get dist-upgrade -y

# Add additional package repositories
wget -q -O - http://apt.mopidy.com/mopidy.gpg | apt-key add -
wget -q -O /etc/apt/sources.list.d/mopidy.list http://apt.mopidy.com/mopidy.list
if [ "$(lsb_release -c -s)" = wheezy ]; then
    sed -i 's/stable/wheezy/' /etc/apt/sources.list.d/mopidy.list
fi
wget -q -O - http://www.lesbonscomptes.com/key/jf@dockes.org.gpg.key | apt-key add -
cat << EOF > /etc/apt/sources.list.d/upmpdcli.list
deb http://www.lesbonscomptes.com/upmpdcli/downloads/debian/ unstable main
deb-src http://www.lesbonscomptes.com/upmpdcli/downloads/debian/ unstable main
EOF

# Agree to Intel firmware license
echo firmware-ipw2x00 firmware-ipw2x00/license/accepted boolean true | debconf-set-selections
# Enable mopidy system service
#echo mopidy	mopidy/daemon	boolean	false | debconf-set-selections

# Install debian packages
apt-get update
apt-get --yes --no-install-suggests --no-install-recommends install \
    logrotate wpasupplicant ifplugd samba dos2unix cifs-utils iptables \
    iw atmel-firmware firmware-atheros firmware-brcm80211 firmware-ipw2x00 \
    firmware-iwlwifi firmware-libertas firmware-ralink firmware-realtek \
    zd1211-firmware firmware-linux firmware-linux-nonfree \
    rpi-update dropbear libnss-mdns ca-certificates \
    dosfstools usbmount watchdog alsa-utils alsa-base alsa-firmware-loaders \
    avahi-utils avahi-autoipd build-essential libffi-dev libssl-dev \
    python-dev python-gst0.10 \
    gstreamer0.10-plugins-good gstreamer0.10-plugins-bad gstreamer0.10-plugins-ugly \
    gstreamer0.10-alsa gstreamer0.10-fluendo-mp3 gstreamer0.10-tools \
    mopidy mopidy-spotify mopidy-scrobbler mopidy-soundcloud mopidy-dirble \
    mopidy-spotify-tunigo mopidy-tunein mopidy-local-sqlite \
    mopidy-podcast mopidy-podcast-itunes mopidy-podcast-gpodder \
    mopidy-alsamixer mpc ncmpcpp monit upmpdcli

# Quick cleanup
apt-get -y autoremove
apt-get -y autoclean
rm /usr/sbin/policy-rc.d

printf "\n ** Installing Python packages...\n\n"

# Install pip and additional python packages
wget -q -O - https://bootstrap.pypa.io/get-pip.py | python -
pip install --upgrade requests[security]
pip install mopidy-internetarchive \
            mopidy-mobile \
            mopidy-moped \
            mopidy-mopify \
            mopidy-musicbox-webclient \
            mopidy-simple-webclient \
            mopidy-subsonic \
            mopidy-websettings \
            mopidy-youtube

# mopidy-gmusic package is outdated, use development version
pip install https://github.com/hechtus/mopidy-gmusic/archive/develop.zip
# Use development versions for now (DO_NOT_RELEASE)
pip install --upgrade --no-deps https://github.com/woutervanwijk/Mopidy-MusicBox-Webclient/archive/develop.zip
pip install --upgrade --no-deps https://github.com/woutervanwijk/mopidy-websettings/archive/develop.zip

printf "\n ** Disabling services...\n\n"

# Disable SSH as we use dropbear instead.
update-rc.d ssh disable
# Disable all optional services by default. User enables desired services in settings.ini
# Prevent package upgrade renabling services: update-rc.d mopidy stop 80 0 1 2 3 4 5 6
update-rc.d mopidy disable
update-rc.d dropbear disable
update-rc.d upmpdcli disable
# TODO: Add shairport-sync here once we install it...

# Create the directories for USB and network mounts.
for x in MusicBox Network USB USB2 USB3 USB4
    do mkdir -p /music/$x
done
chmod -R 777 /music
chown -R mopidy:audio /music

printf "\n ** Setting the system password...\n"

echo "pi:musicbox" | chpasswd

if [ "$PIMUSICBOX_FILES" == "" ]; then
    printf "\n ** No pimusicbox files specified - setup incomplete\n"
    exit 0
fi

printf "\n ** Copying pimusicbox files...\n"

cp -- "${PIMUSICBOX_FILES}"/boot/config.txt /boot/config.txt
cp -R -- "${PIMUSICBOX_FILES}"/boot/config /boot/
cp -R -- "${PIMUSICBOX_FILES}"/opt/* /opt/
cp -R -- "${PIMUSICBOX_FILES}"/etc/* /etc/

# Enable our init scripts
# TODO: Use sysv-rc-conf instead?
update-rc.d musicbox defaults
update-rc.d musicbox enable

chmod +x /etc/network/if-up.d/iptables
#chown root:root /etc/firewall/musicbox_iptables
chmod 600 /etc/firewall/musicbox_iptables

# Link the user-configurable files in /boot/config
ln -fsn /boot/config/streamuris.js /usr/local/lib/python2.7/dist-packages/mopidy_musicbox_webclient/static/js/streamuris.js
ln -fsn /boot/config/settings.ini /etc/mopidy/mopidy.conf

# Update the mount options so anyone can mount the boot partition and give everyone all permissions.
#sed -i '/mmcblk0p1\s\+\/boot\s\+vfat/ s/defaults /defaults,user,umask=000/' "${ROOTDIR}/etc/fstab"

printf "\n ** Enabling raspberry pi fixes/optimisations...\n"

#For the music to play without cracks, you have to optimize your system a bit.
#For MusicBox, these are the optimizations:

#**USB Fix**
#It's tricky to get good sound out of the Pi. For USB Audio (sound cards, etc),
# it is essential to disable the so called FIQ_SPLIT. Why? It seems that audio
# at high bitrates interferes with the ethernet activity, which also runs over USB.
sed -i '1s/^/dwc_otg.fiq_fix_enable=1 dwc_otg.fiq_split_enable=0 smsc95xx.turbo_mode=N /' /boot/cmdline.txt
