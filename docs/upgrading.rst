*********
Upgrading
*********

.. warning::
    Upgrading is not officially supported by authors of Pi MusicBox.

.. warning::
    Upgrading Python packages will currently break Subsonic support (and
    probably other things).

Upgrading is divided into several steps. Steps should be made in sequence they
are mentioned. To do the update SSH must be enabled. 

.. warning::
    Upon failure this procedure can render Pi MusicBox unbootable. Please be
    ready to reinstall Pi MusicBox in worst case!


Step 1: Upgrading Pi MusicBox scripts
=====================================

Updated scripts are required for Raspbian update.
To update Pi MusicBox scripts run these shell commands via SSH::

    curl https://raw.githubusercontent.com/pimusicbox/pimusicbox/master/filechanges/opt/musicbox/setsound.sh > /opt/musicbox/setsound.sh
    chmod 755 /opt/musicbox/setsound.sh
    curl https://raw.githubusercontent.com/pimusicbox/pimusicbox/master/filechanges/boot/config.txt > /boot/config.txt


Step 2: Upgrading Raspbian
==========================

Raspbian is Debian Linux derivative which is used as underlying OS in Pi
MusicBox. To update Raspbian (and reboot) run these shell commands via SSH::

    apt-get update
    apt-get -y dist-upgrade
    shutdown -r now

Step 3: Upgrading Python packages
=================================

Mopidy is music server which is used as core of Pi MusicBox music/media
subsystem. Mopidy and its plugins are Python packages. To stop Mopidy and
update all installed Python packages from PyPI repository run these shell
commands via SSH::

    apt-get -y install build-essential python-dev libffi-dev
    service monit stop
    service mopidy stop
    pip install requests[security]
    pip install --upgrade pip
    pip freeze --local | grep -v '^\-e' | cut -d = -f 1 > ~/pip-packages.txt
    pip install --upgrade -r ~/pip-packages.txt


Step 4: Fix-ups after Python packages update
============================================

There are a few things which must be fixed/reconfigured after
Mopidy-MusicBox-Webclient (one of Python packages) update. To do the fixups and
start Mopidy run these shell commands via SSH::

    echo -e "\n[musicbox_webclient]\nmusicbox = true" >> /boot/config/settings.ini
    sed -i 's/static_dir \=.*/static_dir = \/opt\/webclient/g' /boot/config/settings.ini
    rm /opt/webclient
    mkdir /opt/webclient
    echo -e "<html><head><meta http-equiv=\"refresh\" content=\"0; URL=/musicbox_webclient/index.html\"></head><body>Web interface moved, <a href=\"/musicbox_webclient/index.html\">click here</a></body></html>" > /opt/webclient/index.html
    service mopidy restart
    service monit start
