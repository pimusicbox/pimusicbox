#!/bin/bash

SCRIPTPATH=$( cd $(dirname $0) ; pwd -P )
PIMUSICBOX_BRANCH='develop'
PIMUSICBOX_FILES="${1:-$SCRIPTPATH/filechanges}"
PIMUSICBOX_PACKAGES="/opt/musicbox/packages"

! read -d '' APT_PACKAGES << EOF
alsa-base
alsa-firmware-loaders
alsa-utils
avahi-autoipd
avahi-utils
build-essential
ca-certificates
cifs-utils
dos2unix
dosfstools
dropbear
gstreamer1.0-alsa
gstreamer1.0-fluendo-mp3
gstreamer1.0-plugins-bad
gstreamer1.0-plugins-good
gstreamer1.0-plugins-ugly
gstreamer1.0-tools
ifplugd
iptables
iw
libffi-dev
libnss-mdns
libssl-dev
logrotate
mopidy
mopidy-alsamixer
mopidy-dirble
mopidy-internetarchive
mopidy-local-sqlite
mopidy-podcast
mopidy-podcast-gpodder
mopidy-podcast-itunes
mopidy-scrobbler
mopidy-somafm
mopidy-soundcloud
mopidy-spotify
mopidy-spotify-tunigo
mopidy-tunein
monit
mpc
ncmpcpp
nginx
python-dev
rpi-update
samba
shairport-sync
upmpdcli
usbmount
watchdog
wpasupplicant
atmel-firmware
firmware-atheros
firmware-brcm80211
firmware-ipw2x00
firmware-iwlwifi
firmware-libertas
firmware-linux
firmware-linux-nonfree
firmware-ralink
firmware-realtek
zd1211-firmware
EOF
! read -d '' PIP_PACKAGES << EOF
mopidy-gmusic
mopidy-mobile
mopidy-moped
mopidy-mopify
mopidy-musicbox-webclient
mopidy-simple-webclient
mopidy-subsonic
mopidy-websettings
mopidy-youtube
EOF

if [ $(id -u) -ne 0 ]; then
    printf "** You must be the superuser to run this script **\n"
    return false
fi

printf "**********************************\n"
printf "*** Build your own PiMusicBox. ***\n"
printf "**********************************\n"

# Download Pi MusicBox files if not already available.
if [ "$PIMUSICBOX_FILES" != "" ]; then
    if [ ! -d "$PIMUSICBOX_FILES" ]; then
        printf "** Unable to find PiMusicBox files at $PIMUSICBOX_FILES.\n"
        printf "** Downloading $PIMUSICBOX_BRANCH branch from github...\n"
        cd /tmp
        wget -q "https://github.com/pimusicbox/pimusicbox/archive/${PIMUSICBOX_BRANCH}.zip" 
        unzip -- "${PIMUSICBOX_BRANCH}.zip"
        rm -- "${PIMUSICBOX_BRANCH}.zip"
        mv -- "pimusicbox-${PIMUSICBOX_BRANCH}/filechanges" "$PIMUSICBOX_FILES"
    fi
    if [ ! -d "$PIMUSICBOX_FILES" ]; then
        printf "** Failed to find PiMusicBox files at $PIMUSICBOX_FILES.\n"
        return false
    fi

    printf "\n ** Found PiMusicBox files at $PIMUSICBOX_FILES\n"

    printf "\n ** Copying PiMusicBox packages to $PIMUSICBOX_PACKAGES\n"
    mkdir -p "$PIMUSICBOX_PACKAGES"
    cp $PIMUSICBOX_FILES/../packages/* $PIMUSICBOX_PACKAGES/
else
    printf "\n ** Error: Could not find PiMusicBox files.\n"
    return false
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
echo "Europe/London" > /etc/timezone
dpkg-reconfigure -f noninteractive tzdata
ntpdate -u ntp.ubuntu.com

# Update the distribution to get latest fixes for audio and usb-issues
apt-get dist-upgrade -y

# Add additional package repositories
wget -q -O - https://apt.mopidy.com/mopidy.gpg | apt-key add -
wget -q -O /etc/apt/sources.list.d/mopidy.list https://apt.mopidy.com/jessie.list
wget -q -O - http://www.lesbonscomptes.com/key/jf@dockes.org.gpg.key | apt-key add -
cat << EOF > /etc/apt/sources.list.d/upmpdcli.list
deb http://www.lesbonscomptes.com/upmpdcli/downloads/debian/ unstable main
deb-src http://www.lesbonscomptes.com/upmpdcli/downloads/debian/ unstable main
EOF
#TODO: import musicbox gpg key.
cat << EOF > /etc/apt/sources.list.d/musicbox.list
deb [trusted=yes] file:$PIMUSICBOX_PACKAGES ./
EOF

# Agree to Intel firmware license
echo firmware-ipw2x00 firmware-ipw2x00/license/accepted boolean true | debconf-set-selections

# Install debian packages
apt-get update
apt-get --yes --no-install-suggests install $APT_PACKAGES

# Quick cleanup
apt-get -y autoremove
apt-get -y autoclean
rm /usr/sbin/policy-rc.d

printf "\n ** Installing Python packages...\n\n"

# Install pip and additional python packages
wget -q -O - https://bootstrap.pypa.io/get-pip.py | python -
pip install --upgrade requests[security]
pip install $PIP_PACKAGES

# TODO: Use latest releases.
pip install --upgrade --no-deps https://github.com/woutervanwijk/Mopidy-MusicBox-Webclient/archive/develop.zip
pip install --upgrade --no-deps https://github.com/woutervanwijk/mopidy-websettings/archive/develop.zip

printf "\n ** Configuring system services...\n\n"

# Boot to console rather than desktop.
systemctl set-default multi-user.target
# Use dropbear instead of SSH.
systemctl mask ssh
sed -i 's/NO_START=1/NO_START=0/' /etc/default/dropbear
# TODO: Consider presets (https://www.freedesktop.org/software/systemd/man/systemd.preset.html)
systemctl enable dropbear upmpdcli mopidy shairport-sync

printf "\n ** Creating music directories...\n\n"

for x in MusicBox Network USB USB2 USB3 USB4
    do mkdir -p /music/$x
done
chmod -R 777 /music
chown -R mopidy:audio /music

printf "\n ** Setting system password...\n"

echo "pi:musicbox" | chpasswd

if [ "$PIMUSICBOX_FILES" == "" ]; then
    printf "\n ** Warning: no PiMusicBox files specified - setup is incomplete\n"
    return 0
fi

printf "\n ** Installing PiMusicBox files...\n"

cp -R -- "${PIMUSICBOX_FILES}"/opt/* /opt/
cp -R -- "${PIMUSICBOX_FILES}"/etc/* /etc/
cp -R -- "${PIMUSICBOX_FILES}"/lib/* /lib/
[ -d /boot ] && cp -R -- "${PIMUSICBOX_FILES}"/boot/* /boot/
chmod +x /etc/network/if-up.d/iptables
#chown root:root /etc/firewall/musicbox_iptables
chmod 600 /etc/firewall/musicbox_iptables

# Link the default musicbox config somewhere the Mopidy service can read it.
ln -fsn /opt/musicbox/musicbox.conf /usr/share/mopidy/conf.d/musicbox.conf
chown -R mopidy:audio /usr/share/mopidy

# Link the musicbox nginx config.
ln -fsn /etc/nginx/sites-available/musicbox /etc/nginx/sites-enabled/default

# Musicbox state data lives here.
mkdir -p /var/opt/musicbox

# Small changes to config files, eventually move these to config packages:
# TODO: Why?
sed -i 's/dns$/dns mdns4/' /etc/nsswitch.conf
# Enable Watchdog
sed -i -e 's/^#watchdog-device/watchdog-device/' \
       -e 's/^#max-load-1/max-load-1/' /etc/watchdog.conf
# Fix for broken watchdog.service file (https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=793309)
sed -i '/[Install]/a WantedBy=multi-user.target' /lib/systemd/system/watchdog.service
# Force setting time even if moves block backwards.
sed -i 's/^#FORCE=/FORCE=/' /etc/default/fake-hwclock
#TODO: Do we want to disable avahi when unicast dns servers that provide .local are detected?  
sed -i 's/AVAHI_DAEMON_DETECT_LOCAL=./AVAHI_DAEMON_DETECT_LOCAL=0/' /etc/default/avahi-daemon
sed -i -e 's/^#\?disallow-other-stacks=.*/disallow-other-stacks=yes/' \
       -e 's/^#\?publish-a-on-ipv6=.*/publish-a-on-ipv6=yes/' /etc/avahi/avahi-daemon.conf
# Reduce priority of upmpdcli. TODO: better done through systemd?
sed -i '/As a last resort, sleep for some time./a renice 19 `pgrep upmpdcli`' /etc/init.d/upmpdcli
sed -i -e 's@//\s*run_this_before_play_begins =.*$@\trun_this_before_play_begins = "/usr/bin/mpc stop";@' \
       -e 's@//\s*wait_for_completion =.*$@\twait_for_completion = "yes";@' /etc/shairport-sync.conf

printf "\n ** Enabling PiMusicBox service...\n"

systemctl enable musicbox

if grep -q Raspbian /etc/*-release; then
    printf "\n ** Performing raspberry pi specific fixes/optimisations...\n"

    # Disable swap
    systemctl mask dphys-swapfile

    # Link the user-configurable files in /boot/config
    ln -fsn /boot/config/settings.ini /etc/mopidy/mopidy.conf

    # Update the mount options so anyone can mount the boot partition and give everyone all permissions.
    sed -i '/mmcblk0p1\s\+\/boot\s\+vfat/ s/defaults /defaults,user,umask=000/' /etc/fstab

    #**USB Fix**
    #It's tricky to get good sound out of the Pi. For USB Audio (sound cards, etc),
    # it is essential to disable the so called FIQ_SPLIT. Why? It seems that audio
    # at high bitrates interferes with the ethernet activity, which also runs over USB.
    sed -i '1s/^/dwc_otg.fiq_fix_enable=1 dwc_otg.fiq_split_enable=0 smsc95xx.turbo_mode=N /' /boot/cmdline.txt
fi

printf "** Install complete, please reboot. **\n"
