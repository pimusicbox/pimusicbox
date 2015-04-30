**How to create Pi MusicBox (Work in progress)**
------------------------------------------------

First, download or create an (minimal) installation of Raspbian, the most used Linux distribution for the Pi. I used the Raspbian Installer.

**First configuration**

Login as root. Or use

    sudo -l

to gain full rights.

Make sure there is enough space on the SD Card. Use the command raspi-config to resize the filesystem when needed.

Update the mount options so anyone can mount the boot partition and give everyone all permissions.
    sed -i '/mmcblk0p1\s\+\/boot\s\+vfat/ s/defaults /defaults,rw,user,umask=000/' /etc/fstab

Issue this command. This will prevent the system from installing unnecessary packages. This command takes care that the apt-system doesn’t fill up the SD Card with stuff you don’t need. If you don’t care about a bit of wasted space, or you use your system for other purposes, skip it.

    echo -e 'APT::Install-Recommends "0";\nAPT::Install-Suggests "0";\n' > /etc/apt/apt.conf

The file /etc/apt/sources.list should contain all Raspbian repositories, including non-free (for the wireless firmware). Make sure the file contains these lines (not only with the 'main', but also 'contrib', etc):

    deb http://mirrordirector.raspbian.org/raspbian/ wheezy main contrib non-free rpi
    deb-src http://mirrordirector.raspbian.org/raspbian/ wheezy main contrib non-free rpi

Install the packages you need to continue:

    apt-get update && apt-get install sudo wget unzip mc

The last part of this command ‘mc’, will install midnight commander, an easy to use command line file manager for Linux. You don’t have to do that, but I like it.

**Update**

Next, issue this command to update the distribution. This is good because newer versions have fixes for audio and usb-issues:

    apt-get dist-upgrade -y

**Mopidy Music Server**

Install all packages we need with this command:

    sudo apt-get update && sudo apt-get --yes --no-install-suggests --no-install-recommends install logrotate alsa-utils wpasupplicant gstreamer0.10-alsa ifplugd gstreamer0.10-fluendo-mp3 gstreamer0.10-tools samba dos2unix avahi-utils alsa-base cifs-utils avahi-autoipd libnss-mdns ntpdate ca-certificates ncmpcpp rpi-update linux-wlan-ng alsa-firmware-loaders iw atmel-firmware firmware-atheros firmware-brcm80211 firmware-ipw2x00 firmware-iwlwifi firmware-libertas firmware-linux firmware-linux-nonfree firmware-ralink firmware-realtek zd1211-firmware linux-wlan-ng-firmware iptables build-essential python-dev python-pip python-gst0.10 gstreamer0.10-plugins-good gstreamer0.10-plugins-bad gstreamer0.10-plugins-ugly usbmount monit upmpdcli watchdog dropbear mpc dosfstools

Depending on your configuration, you could leave out certain packages, e.g. the firmware files if you don't use a wireless dongle.

Then install mopidy and the extensions we need:

    sudo pip install -U mopidy mopidy-spotify mopidy-local-sqlite mopidy-local-whoosh mopidy-scrobbler mopidy-soundcloud mopidy-dirble mopidy-tunein mopidy-gmusic mopidy-subsonic mopidy-mobile mopidy-moped mopidy-musicbox-webclient mopidy-websettings mopidy-internetarchive mopidy-podcast mopidy-podcast-itunes mopidy-podcast-gpodder.net Mopidy-Simple-Webclient mopidy-somafm mopidy-spotify-tunigo mopidy-youtube

Google Music works a lot better if you use the development version of mopidy-gmusic:

    sudo pip install https://github.com/hechtus/mopidy-gmusic/archive/develop.zip

**Configuration and Files**

Go to the /opt directory

    cd /opt

Get the files of the Pi MusicBox project

    wget https://github.com/woutervanwijk/Pi-MusicBox/archive/master.zip

If you get an error about certificates, issue the following command:

    ntpdate -u ntp.ubuntu.com

Unpack the zip-file and remove it if you want.

    unzip master.zip

    rm master.zip

Then go to the directory which you just unpacked, subdirectory ‘filechanges’:

    cd Pi-MusicBox-master/filechanges

Now we are going to copy some files. Backup the old ones if you’re not sure!

This sets up the boot and opt directories:

    mkdir /boot/config

    cp -R boot/config/* /boot/config/

    cp -R opt/* /opt

Make the system work:

    cp -R etc/* /etc

Network configuration:

    chmod +x /etc/network/if-up.d/iptables

    chown root:root /etc/firewall/musicbox_iptables

    chmod 600 /etc/firewall/musicbox_iptables

Webclient:

Create a symlink from the package to the /opt/webclient and to /opt/defaultwebclient. This is done because you could install other webclients and just point the link to the newly installed client:

    ln -fsn /usr/local/lib/python2.7/dist-packages/mopidy_musicbox_webclient/static /opt/webclient
    
    ln -fsn /usr/local/lib/python2.7/dist-packages/mopidy_moped/static /opt/moped

    ln -fsn /opt/webclient /opt/defaultwebclient

Remove the streamuris.js and point it to the file in /boot/config

    mv /usr/local/lib/python2.7/dist-packages/mopidy_musicbox_webclient/static/js/streamuris.js streamuris.bk

    ln -fsn /boot/config/streamuris.js /usr/local/lib/python2.7/dist-packages/mopidy_musicbox_webclient/static/js/streamuris.js

Let everyone shutdown the system (to support it from the webclient):

    chmod u+s /sbin/shutdown

**Add the mopidy user**

Mopidy runs under the user mopidy. Add it.

    useradd -m mopidy

    passwd -l mopidy

Add the user to the group audio:

    usermod -a -G audio mopidy

Create a couple of directories inside the user dir:

    mkdir -p /home/mopidy/.config/mopidy

    mkdir -p /home/mopidy/.cache/mopidy

    mkdir -p /home/mopidy/.local/share/mopidy

    chown -R mopidy:mopidy /home/mopidy

**Create Music directory for MP3/OGG/FLAC **

Create the directory containing the music and the one where the network share is mounted:

    mkdir -p /music/MusicBox

    mkdir -p /music/Network

    mkdir -p /music/USB

    mkdir -p /music/USB2

    mkdir -p /music/USB3

    mkdir -p /music/USB4

    chmod -R 777 /music

    chown -R mopidy:mopidy /music

Disable the SSH service for more security if you want (it can be started with an option in the configuration-file):

    update-rc.d ssh disable

Link the mopidy configuration to the new one in /boot/config
    ln -fsn /boot/config/settings.ini /home/mopidy/.config/mopidy/mopidy.conf
    mkdir -p /var/lib/mopidy/.config/mopidy
    ln -fsn /boot/config/settings.ini /var/lib/mopidy/.config/mopidy/mopidy.conf


That’s it. MusicBox should now start when you reboot!

**AirTunes**
------------

For AirPlay/AirTunes audio streaming, you have to compile and install Shairport-sync. Check out github for that:
https://github.com/mikebrady/shairport-sync

**DLNA/Upnp streaming**
------------

For DLNA/Upnp audio streaming, MusicBox uses upmpdcli. It's installed in the command above already. Or use:

    apt-get install upmpdcli

and copy the configuration file from Pi MusicBox Master to /etc (first cd to Pi-MusicBox-master/filechanges like before)

    cp upmpdcli.conf /etc

**Optimizations**
-----------------

For the music to play without cracks, you have to optimize your system a bit. For MusicBox, these are the optimizations:

**Updated kernel**

Update the kernel to make sure all optimizations of newer core-software:
    rpi-update

**USB Fix**

It's tricky to get good sound out of the Pi. For USB Audio (sound cards, etc), it is essential to disable the so called FIQ_SPLIT. Why? It seems that audio at high nitrates interferes with the ethernet activity, which also runs over USB. Add these options to the cmdline.txt file on your SD Card.

    dwc_otg.fiq_fix_enable=1 dwc_otg.fiq_split_enable=0

While you're at it, also add or edit the elevator option to

    elevator=deadline

It will probably look something like this after that:

    dwc_otg.fiq_fix_enable=1 dwc_otg.fiq_split_enable=0 dwc_otg.lpm_enable=0 console=ttyAMA0,115200 kgdboc=ttyAMA0,115200 console=tty1 root=/dev/mmcblk0p2 rootfstype=ext4 elevator=deadline rootwait

Don't just copy this, because your root could be different.

You can also add this, if you still have problems with ethernet in connection to USB audio:

    smsc95xx.turbo_mode=N

This will prevent the ethernet system from using burst to increase the network throughput. This can interfere with the music data sent over usb.

**More fun with RAM**

Add the next lines to the file /etc/default/rcS

    RAMRUN=yes

    RAMLOCK=yes

This will run more stuff in RAM, instead of the SD-Card.

**USB Sound**

Edit the sound settings of USB Cards in /etc/modprobe.d/modprobe.conf :

Find the line

    options snd-usb-audio index=-2

and add this:

    options snd-usb-audio index=-2 nrpacks=1

**Services**

Disable services that are not needed. NTP is disabled because the time is updated at boot.

    update-rc.d ntp disable

**Log Less**

Less logging, means less to do for the system. Edit /etc/syslog.conf and put this in it:

    -e *.*;mail.none;cron.none       -/dev/null

    cron.*   -/dev/null

    mail.*   -/dev/null

This will send the logs directly to loggers heaven (/dev/null)

**More Memory**

Add this line to /boot/config.txt to have less memory for the video (MusicBox doesn’t need that):

    gpu_mem=16

**Overclocking**

By over clocking your Pi, you will get better performance. This could lower the life expectency of your Pi though, use at your own risk! See:

    http://elinux.org/RPiconfig

You can overclock the Pi mildly by adding this line to /boot/config.txt

    arm_freq=800

(700 MHz is the default)

Or you can overclock it more, by adding these lines:

    arm_freq=900

    core_freq=250

    sdram_freq=450

    over_voltage=2

**Fstab**

Make sure that root is mounted with the flag noatime. Normally this would be configured that way already.
You can also add these options, to put the most used directories in RAM, instead of using the SD-Card:

    tmpfs          /tmp           tmpfs      defaults,noatime            0     0

    tmpfs          /var/tmp       tmpfs      defaults,noatime            0     0

    tmpfs          /var/log       tmpfs      defaults,noatime            0     0

    tmpfs          /var/mail      tmpfs      defaults,noatime            0     0

**Cleanup**

If you upgraded the kernel, and the system works, you could remove:
/boot.bk
/modules.bk

Issue these commands to clean up packages:
apt-get autoremove
apt-get clean
apt-get autoclean


That’s it for now. Thanks!
- Wouter van Wijk

7 november 2014
