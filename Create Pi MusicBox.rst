**How to create Pi MusicBox**
-----------------------------

First, download or create an (minimal) installation of Raspbian, the most used Linux distribution for the Pi. I used the Raspbian Installer.

**First configuration**

Login as root. Or use 

	sudo -l

to gain full rights.

Make sure there is enough space on the SD Card. Use the command raspi-config to resize the filesystem when needed.

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

Next, configure the installation of Mopidy, the music server that is the heart of MusicBox. 

	wget -q -O - http://apt.mopidy.com/mopidy.gpg | sudo apt-key add -

	sudo wget -q -O /etc/apt/sources.list.d/mopidy.list http://apt.mopidy.com/mopidy.list



Then install all packages we need with this command:

	sudo apt-get update && sudo apt-get --yes --no-install-suggests --no-install-recommends install logrotate mopidy alsa-utils python-cherrypy3 python-ws4py wpasupplicant python-spotify gstreamer0.10-alsa ifplugd gstreamer0.10-fluendo-mp3 gstreamer0.10-tools samba dos2unix avahi-utils alsa-base python-pylast cifs-utils avahi-autoipd libnss-mdns ntpdate ca-certificates ncmpcpp rpi-update linux-wlan-ng alsa-firmware-loaders iw atmel-firmware firmware-atheros firmware-brcm80211 firmware-ipw2x00 firmware-iwlwifi firmware-libertas firmware-linux firmware-linux-nonfree firmware-ralink firmware-realtek zd1211-firmware linux-wlan-ng-firmware alsa-firmware-loaders iptables

Depending on your configuration, you could leave out certain packages, e.g. the firmware files if you don't use a wireless dongle. 

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

	cp boot/config/settings.ini /boot/config/

	cp opt/* /opt

Make the system work:

	cp etc/rc.local /etc

	cp etc/modules /etc

Network configuration:

	cp etc/avahi/services/* /etc/avahi/services/

	cp etc/samba/smb.conf /etc/samba

	cp etc/network/interfaces /etc/network

 	mkdir /etc/firewall

 	cp etc/firewall/* /etc/firewall

        cp etc/network/if-up.d/* /etc/network/if-up.d/

	chmod +x /etc/netwok/if-up.d/iptables

	chown root:root /etc/firewall/musicbox_iptables.sh	

	chmod 600 /etc/firewall/musicbox_iptables.sh

**Install webclient**

To install the Mopidy webclient, do the following:

	cd /opt

Get the webclient from github:

	wget https://github.com/woutervanwijk/Mopidy-Webclient/archive/master.zip

Unpack and copy:

	unzip master.zip

	cd Mopidy-Webclient-master/

	cp -R webclient /opt

Next, create a symlink from the package to the /opt/defaultwebclient. This is done because you could install other webclients and just point the link to the newly installed client:

	ln -s /opt/webclient /opt/defaultwebclient

**Add the MusicBox user**

Mopidy can run under the user musicbox. Add it.

	useradd -m musicbox

	passwd musicbox

Add the user to the group audio:

	usermod -a -G audio musicbox

Create a couple of directories inside the user dir:

	mkdir -p /home/musicbox/.config/mopidy

	mkdir -p /home/musicbox/.cache/mopidy

	mkdir -p /home/musicbox/.local/share/mopidy

	chown -R musicbox:musicbox /home/musicbox

In the latest MusicBox release, Mopidy still runs as root, because, when running it as another user, some glitches in the sound can be heard.

**Create Music directory for MP3/OGG/FLAC **

Create the directory containing the music and the one where the network share is mounted:

	mkdir -p /music/local

	mkdir -p /music/network

	chmod -R 777 /music

	chown -R musicbox:musicbox /music

Disable the SSH service for more security if you want (it can be started with an option in the configuration-file):

	update-rc.d ssh disable

That’s it. MusicBox should now start when you reboot!

**AirTunes**
------------

For AirPlay/AirTunes audio streaming, you have to compile and install Shairport. First issue this command to install the libraries needed to build it:

	apt-get update && apt-get --yes --no-install-suggests --no-install-recommends install build-essential libssl-dev libcrypt-openssl-rsa-perl libao-dev libio-socket-inet6-perl libwww-perl avahi-utils pkg-config git chkconfig libssl-dev libavahi-client-dev libasound2-dev pcregrep


Then, issue these commands to build everything:

	cd ~

Build an updated version of Perl-Net

	git clone https://github.com/njh/perl-net-sdp.git perl-net-sdp 

	cd perl-net-sdp 

	perl Build.PL 

	sudo ./Build 

	sudo ./Build test 

	sudo ./Build install 

Build Shairport:

	cd .. 

	git clone https://github.com/hendrikw82/shairport.git 

	cd shairport 

	make

Next, move the new shairport directory to /opt

	mv shairport /opt
 
Finally, copy libao.conf from the Pi MusicBox files to /etc :

	cp /opt/Pi-MusicBox-master/filechanges/etc/libao.conf /etc

That's it!

**Extensions**
--------------

You can install SoundCloud or Google Music support via extensions of Mopidy. Use this command to first install Pip, the python package manager:

	easy_install pip

Then, use pip to install the extensions:

	pip install mopidy-soundcloud

and/or

	pip install gmusicapi

	pip install mopidy-gmusic

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

	tmpfs      	/tmp       	tmpfs  	defaults,noatime        	0 	0
	
	tmpfs      	/var/tmp   	tmpfs  	defaults,noatime        	0 	0
	
	tmpfs      	/var/log   	tmpfs  	defaults,noatime        	0 	0
	
	tmpfs      	/var/mail  	tmpfs  	defaults,noatime        	0 	0

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

10 september 2013
