MIN_FREE_SPACE_KB=$(expr 1024 \* 1024)
PIMUSICBOX_FILES=/tmp/filechanges
SHAIRPORT_VERSION=3.0.2
LIBRESPOT_VERSION=v20170605-39012ba

FREE_SPACE=$(df | awk '$NF == "/" { print $4 }')
if [ $FREE_SPACE -lt $MIN_FREE_SPACE_KB ]; then
    echo "************************************************"
    echo "** ERROR: Insufficient free space to upgrade  **"
    echo "** Use ./makeimage.sh bigger <image_file>     **"
    echo "************************************************"
    exit 3
fi

cd /tmp

# Update system time to avoid SSL errors later.
ntpdate-debian
service fake-hwclock stop

# Things we no longer need:
# * Favourite streams now implemented with playlists.
rm /boot/config/streamuris.js
# * Device Tree now properly handles all this stuff. Revert to upstream versions.
rm /etc/modules /etc/modprobe.d/*
# * Avahi support now included in Raspbian. Revert to upstream versions.
rm -rf /etc/avahi/*
# * Revert to upstream shairport-sync systemV script.
rm -f /etc/init.d/shairport-sync
# * Upgraded musicbox distro files.
rm -rf /opt/musicbox /opt/shairport-sync /opt/webclient /opt/defaultwebclient /opt/moped
# * dpkg: warning: unable to delete old directory '/lib/modules/3.18.7+/kernel/drivers/net/wireless': Directory not empty
rm /lib/modules/3.18.7+/kernel/drivers/net/wireless/8188eu.ko
# Remove Mopidy APT repo details, using pip version to avoid Wheezy induced dependency hell.
rm /etc/apt/sources.list.d/mopidy.list
rm -rf /etc/mopidy/extensions.d

wget -q -O - http://www.lesbonscomptes.com/key/jf@dockes.org.gpg.key | apt-key add -
cat << EOF > /etc/apt/sources.list.d/upmpdcli.list
deb http://www.lesbonscomptes.com/upmpdcli/downloads/raspbian-wheezy/ unstable main
deb-src http://www.lesbonscomptes.com/upmpdcli/downloads/raspbian-wheezy/ unstable main
EOF

export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get remove --yes --purge python-pykka python-pylast
# https://github.com/pimusicbox/pimusicbox/issues/316
apt-get remove --yes --purge linux-wlan-ng

# Ensure we reinstall the upstream config.
apt-get install --yes -o Dpkg::Options::="--force-confmiss" --reinstall avahi-daemon

# Get the packages required for setting wifi region
apt-get install --yes wireless-regdb crda

# Fix locale
apt-get install --yes locales
echo "Europe/London" > /etc/timezone
dpkg-reconfigure -f noninteractive tzdata
sed -i -e 's/en_US.UTF-8 UTF-8/# en_US.UTF-8 UTF-8/' /etc/locale.gen
sed -i -e 's/# en_GB.UTF-8 UTF-8/en_GB.UTF-8 UTF-8/' /etc/locale.gen
echo -e 'LANG="en_GB.UTF-8"\nLANGUAGE="en_GB:en"' > /etc/default/locale
dpkg-reconfigure --frontend=noninteractive locales
update-locale LANG=en_GB.UTF-8

# Upgrade!
apt-get dist-upgrade --yes -o Dpkg::Options::="--force-confnew"

# Build and install latest version of shairport-sync
SHAIRPORT_BUILD_DEPS="build-essential xmltoman autoconf automake libdaemon-dev libasound2-dev libpopt-dev libconfig-dev libavahi-client-dev libssl-dev"
SHAIRPORT_RUN_DEPS="libc6 libconfig9 libdaemon0 libasound2 libpopt0 libavahi-common3 avahi-daemon libavahi-client3 libssl1.0.0 libtool avahi-daemon"
apt-get install --yes $SHAIRPORT_BUILD_DEPS $SHAIRPORT_RUN_DEPS
wget https://github.com/mikebrady/shairport-sync/archive/${SHAIRPORT_VERSION}.zip
unzip ${SHAIRPORT_VERSION}.zip && rm ${SHAIRPORT_VERSION}.zip
cd shairport-sync-${SHAIRPORT_VERSION}
autoreconf -i -f
./configure --sysconfdir=/etc --with-alsa --with-avahi --with-ssl=openssl --with-metadata --with-systemv
make && make install
cd ../
rm -rf shairport-sync*

# Download and install Raspberry Pi Compatible ARMHF
mkdir /opt/librespot
cd /opt/librespot
wget https://github.com/herrernst/librespot/releases/download/${LIBRESPOT_VERSION}/librespot-linux-armhf-raspberry_pi.zip
unzip librespot-linux-armhf-raspberry_pi.zip
rm librespot-linux-armhf-raspberry_pi.zip
chmod +x librespot

# Install mpd-watchdog (#224)
wget https://github.com/pimusicbox/mpd-watchdog/releases/download/v0.3.0/mpd-watchdog_0.3.0-0tkem2_all.deb
dpkg -i mpd-watchdog_0.3.0-0tkem2_all.deb

# Need these to rebuild python dependencies
PYTHON_BUILD_DEPS="build-essential python-dev libffi-dev libssl-dev"
apt-get install --yes $PYTHON_BUILD_DEPS

rm -rf /tmp/pip_build_root
python -m pip install -U pip
# Upgrade some dependencies.
pip install requests[security] backports.ssl-match-hostname backports-abc tornado gmusicapi pykka pylast pafy youtube-dl --upgrade
# The lastest versions that are still supported in Wheezy (Gstreamer 0.10).
pip install mopidy==1.1.2
pip install mopidy-musicbox-webclient==2.4.0
pip install mopidy-websettings==0.1.6.2
pip install mopidy-mopify==1.6.0
pip install mopidy-mobile==1.8.0
pip install mopidy-youtube==2.0.2
pip install mopidy-gmusic==2.0.0
pip install mopidy-spotify-web==0.3.0
pip install mopidy-spotify==1.4.0
pip install mopidy-tunein==0.4.1
pip install mopidy-local-sqlite==1.0.0
pip install mopidy-scrobbler==1.1.1
# Unreleased mopidy-soundcloud has some useful fixes.
pip install --no-deps https://github.com/mopidy/mopidy-soundcloud/archive/faeb6710980f12b50b03bf78c1878be751b8e21a.zip
pip install mopidy-dirble==1.3.0
pip install mopidy-podcast==2.0.1
pip install mopidy-podcast-itunes==2.0.0
pip install mopidy-internetarchive==2.0.3

# https://github.com/pimusicbox/pimusicbox/issues/371
pip uninstall --yes mopidy-local-whoosh
pip uninstall --yes mopidy-podcast-gpodder.net

# Check everything except python and gstreamer is coming from pip.
mopidy --version
mopidy deps | grep "/usr/lib" | grep -v -e "GStreamer: 0.10" -e "Python: CPython" | wc -l

# A bunch of reckless hacks:
# Force Spotify playlists to appear:
sed -i '182s/^/#/' /usr/local/lib/python2.7/dist-packages/mopidy_spotify/session_manager.py
# This should fix MPDroid trying to use MPD commands unsupported by Mopidy. But MPDroid still isn't working properly.
#sed -i 's/0.19.0/0.18.0/' /usr/local/lib/python2.7/dist-packages/mopidy/mpd/protocol/__init__.py
# Speedup MPD connections.
sed -i '/try:/i \
        # Horrible hack here:\
        core.library\
        core.history\
        core.mixer\
        core.playback\
        core.playlists\
        core.tracklist' /usr/local/lib/python2.7/dist-packages/mopidy/mpd/actor.py
# Force YouTube to favour m4a streams as gstreamer0.10's webm support is bad/non-existent:
sed -i '/getbestaudio(/getbestaudio(preftype="m4a"/' /usr/local/lib/python2.7/dist-packages/mopidy_youtube/backend.py

cp -R $PIMUSICBOX_FILES/* /

deluser --remove-home mopidy
adduser --quiet --system --no-create-home --home /var/lib/mopidy --ingroup audio mopidy
chown -R mopidy:audio /var/cache/mopidy
chown -R mopidy:audio /var/lib/mopidy
chown -R mopidy:audio /var/log/mopidy
chown -R mopidy:audio /music/playlists

MUSICBOX_SERVICES="ssh dropbear upmpdcli shairport-sync mpd-watchdog"
for service in $MUSICBOX_SERVICES
do
    update-rc.d $service disable
done

# Update kernel to latest version (4.9.16).
apt-get install --yes git rpi-update
PRUNE_MODULES=1 SKIP_WARNING=1 rpi-update 70d0e67030661cffbf863f66d71c59dff28fd20c

# Clean up.
apt-get remove --yes --purge $PYTHON_BUILD_DEPS $SHAIRPORT_BUILD_DEPS git rpi-update
apt-get autoremove --yes
apt-get clean
apt-get autoclean
