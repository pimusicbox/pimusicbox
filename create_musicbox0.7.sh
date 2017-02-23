APT_PROXY=${APT_PROXY:-localhost:3142}
echo "Acquire::http { Proxy \"http://$APT_PROXY\"; };" > \
    /etc/apt/apt.conf.d/01proxy
    
# dpkg: warning: unable to delete old directory '/lib/modules/3.18.7+/kernel/drivers/net/wireless': Directory not empty
rm /lib/modules/3.18.7+/kernel/drivers/net/wireless/8188eu.ko
# Prevent upgraded services from trying to start inside chroot
echo exit 101 > /usr/sbin/policy-rc.d
chmod +x /usr/sbin/policy-rc.d
DEBIAN_FRONTEND=noninteractive
# Update Wheezy's Mopidy APT repo details 
wget -q -O /etc/apt/sources.list.d/mopidy.list https://apt.mopidy.com/wheezy.list

# Upgrade!
apt-get update && apt-get dist-upgrade -y

#https://github.com/pimusicbox/pimusicbox/issues/316
apt-get remove --yes --purge linux-wlan-ng

# Prefer APT versions of everything as dependencies are easier.
# So remove old pip versions of those extensions we can get from APT.
MOPIDY_APT_EXTENSIONS="mopidy-local-sqlite mopidy-tunein"
pip uninstall --yes mopidy-local-whoosh $MOPIDY_APT_EXTENSIONS

# Remove existing system support for pip's Mopidy, we want APT's now
deluser --remove-home --remove-all-files mopidy
deluser --group mopidy
rm -rf /etc/logrotate.d/mopidy /etc/init.d/mopidy /etc/mopidy/*
apt-get install --yes mopidy $MOPIDY_APT_EXTENSIONS

# Need these to rebuild python dependencies
PYTHON_BUILD_DEPS="build-essential python-dev libffi-dev"
apt-get install --yes $PYTHON_BUILD_DEPS

# The lastest versions that still support Mopidy v1.1.2
pip install mopidy-musicbox-webclient==2.3.0
pip install mopidy-mopify==1.6.0
pip install mopidy-mobile==1.8.0
pip install mopidy-youtube==2.0.2
pip install gmusicapi --upgrade
pip install mopidy-gmusic==2.0.0
pip install mopidy-spotify-web==0.3.0
pip install https://github.com/pimusicbox/mopidy-websettings/zipball/develop
pip install mopidy-spotify==1.4.0

# Reckless hack for playlists not appearing issue.
sed -i '175s/^/#/' /usr/local/lib/python2.7/dist-packages/mopidy_spotify/session_manager.py

# Copy updated files
if [ -d /tmp/filechanges ]; then
    cp -R /tmp/filechanges/* /
fi

# Clean up
apt-get remove --yes --purge $PYTHON_BUILD_DEPS
apt-get clean
apt-get autoclean
rm -rf /var/lib/apt/lists/* /etc/apt/apt.conf.d/01proxy /usr/sbin/policy-rc.d
rm /etc/dropbear/*key
find /var/log -type f | xargs rm
find /home/ -type f -name *.log | xargs rm
find /home/ -type f -name *_history | xargs rm
