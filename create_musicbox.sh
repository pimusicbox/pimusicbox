#!/bin/bash

# build your own Pi MusicBox.
# reeeeeeaaallly alpha. Also see Create Pi MusicBox.rst

SYSTEM_PASSWORD='musicbox'
MUSICBOX_BRANCH='develop'

if [ "$(id -u)" -ne 0 ]; then
    echo "You must be the superuser to run this script" >&2
    exit 1
fi

if [ "$INSTALL_PACKAGES" -eq 1 ]; then
    
    # Install the most basic packages we need to continue
    apt-get update && apt-get --yes install sudo wget unzip ntpdate lsb-release

    # Update the distribution to get latest fixes for audio and usb-issues
    apt-get dist-upgrade -y

    # Update time, to prevent update problems
    ntpdate -u ntp.ubuntu.com

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
    echo mopidy	mopidy/daemon	boolean	false | debconf-set-selections

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

    # Install pip and additional python packages
    wget -q -O - https://bootstrap.pypa.io/get-pip.py | python -
    pip install --upgrade requests[security]
    pip install mopidy-internetarchive \
                mopidy-local-whoosh \
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

    # Disable SSH as we use dropbear instead.
    update-rc.d ssh disable
    # Disable all optional services by default. User enables desired services in settings.ini
    update-rc.d dropbear disable
    update-rc.d upmpdcli disable
    # TODO: Add shairport-sync here once we install it...

    # Create the directories for USB and network mounts.
    mkdir -p /music/MusicBox
    mkdir -p /music/Network
    mkdir -p /music/USB
    mkdir -p /music/USB2
    mkdir -p /music/USB3
    mkdir -p /music/USB4
    chmod -R 777 /music
    chown -R mopidy:audio /music

    # Cleanup
    apt-get -y autoremove
    apt-get -y autoclean

    # Set the system password
    echo "pi:musicbox" | chpasswd
fi

if [ "$INSTALL_CONFIG" -eq 1 ]; then
    cd "${ROOTDIR}/tmp"

    # Download Pi MusicBox files if not already available.
    if [ ! -d "${ROOTDIR}/tmp/Pi-MusicBox" ]; then
        wget -q https://github.com/woutervanwijk/Pi-MusicBox/archive/${MUSICBOX_BRANCH}.zip 
        unzip -- "${MUSICBOX_BRANCH}.zip"
        rm -- "${MUSICBOX_BRANCH}.zip"
        cd -- "Pi-MusicBox-${MUSICBOX_BRANCH}"
    fi

    cd filechanges
    # Copy some files. Backup the old ones if you’re not sure!
    cp -- boot/config.txt "${BOOTDIR}/boot/config.txt"
    cp -R --  boot/config "${BOOTDIR}/boot/"
    cp -R -- opt/* "${ROOTDIR}/opt"

    chmod +x "${ROOTDIR}/etc/network/if-up.d/iptables"
    chown root:root "${ROOTDIR}/etc/firewall/musicbox_iptables"
    chmod 600 "${ROOTDIR}/etc/firewall/musicbox_iptables"

    # Link the user-configurable files in /boot/config
    ln -fsn /boot/config/streamuris.js "${ROOTDIR}/usr/local/lib/python2.7/dist-packages/mopidy_musicbox_webclient/static/js/streamuris.js"
    ln -fsn /boot/config/settings.ini "${ROOTDIR}/etc/mopidy/mopidy.conf"

    #Let everyone shutdown the system (to support it from the webclient):
    chmod u+s "${ROOTDIR}/sbin/shutdown"

    # Update the mount options so anyone can mount the boot partition and give everyone all permissions.
    #sed -i '/mmcblk0p1\s\+\/boot\s\+vfat/ s/defaults /defaults,user,umask=000/' "${ROOTDIR}/etc/fstab"

    #**Optimizations**
    #For the music to play without cracks, you have to optimize your system a bit.
    #For MusicBox, these are the optimizations:

    #**USB Fix**
    #It's tricky to get good sound out of the Pi. For USB Audio (sound cards, etc),
    # it is essential to disable the so called FIQ_SPLIT. Why? It seems that audio
    # at high bitrates interferes with the ethernet activity, which also runs over USB.
    sed -i '1s/^/dwc_otg.fiq_fix_enable=1 dwc_otg.fiq_split_enable=0 smsc95xx.turbo_mode=N /' /boot/cmdline.txt
fi

#other options to be done by hand. Won't do it automatically on a running system
