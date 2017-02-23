# dpkg: warning: unable to delete old directory '/lib/modules/3.18.7+/kernel/drivers/net/wireless': Directory not empty
rm /lib/modules/3.18.7+/kernel/drivers/net/wireless/8188eu.ko
# Prevent upgraded services from trying to start inside chroot
echo exit 101 > /usr/sbin/policy-rc.d
chmod +x /usr/sbin/policy-rc.d
DEBIAN_FRONTEND=noninteractive
# Remove unused and outdated Mopidy APT repo
rm /etc/apt/sources.list.d/mopidy.list

# Upgrade!
apt-get update && apt-get dist-upgrade -y

#https://github.com/pimusicbox/pimusicbox/issues/316
apt-get remove --purge linux-wlan-ng -y

# The lastest versions that still support Mopidy v0.19.5
pip install mopidy-musicbox-webclient==2.0.0
pip install mopidy-mopify==1.6.0
pip install mopidy-mobile==1.7.5
pip install mopidy-tunein==0.1.3
pip install mopidy-youtube==1.0.2
pip install mopidy-spotify-web==0.3.0
pip install https://github.com/pimusicbox/mopidy-websettings/zipball/develop

# Reckless hack for playlists not appearing issue.
sed -i '175s/^/#/' /usr/local/lib/python2.7/dist-packages/mopidy_spotify/session_manager.py

# Copy updated files
if [ -d /tmp/filechanges ]; then
    cp -R /tmp/filechanges/* /
fi

# Clean up
apt-get clean
apt-get autoclean
rm -rf /var/lib/apt/lists/* /etc/apt/apt.conf.d/01proxy /usr/sbin/policy-rc.d
rm /etc/dropbear/*key
find /var/log -type f | xargs rm
find /home/ -type f -name *.log | xargs rm
find /home/ -type f -name *_history | xargs rm
