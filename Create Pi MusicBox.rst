**How to create Pi MusicBox**
-----------------------------

First, download or create an (minimal) installation of Raspbian, the most used Linux distribution for the Pi. I used the Raspbian Installer.

**First configuration**

Login as root. Or use 

	sudo -l

to gain full rights.

Issue this command. This will prevent the system from installing unnecessary packages. This command takes care that the apt-system doesn’t fill up the SD Card with stuff you don’t need. If you don’t care about a bit of wasted space, or you use your system for other purposes, skip it.

	echo -e 'APT::Install-Recommends "0";\nAPT::Install-Suggests "0";\n' > /etc/apt/apt.conf 

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

	sudo apt-get update && sudo apt-get --yes --no-install-suggests --no-install-recommends install logrotate mopidy alsa-utils python-cherrypy3 python-ws4py wpasupplicant python-spotify gstreamer0.10-alsa ifplugd gstreamer0.10-fluendo-mp3 gstreamer0.10-tools samba dos2unix avahi-utils alsa-base python-pylast cifs-utils avahi-autoipd libnss-mdns ntpdate ca-certificates ncmpcpp

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

	cp etc/avahi/services/* /etc/avahi/services/

	cp etc/samba/smb.conf /etc/samba

	cp etc/modules /etc

	cp etc/network/interfaces /etc/network

	mkdir /etc/firewall

	cp etc/firewall/* /etc/firewall

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

Mopidy runs under the user musicbox. Add it.

	useradd -m musicbox

	passwd musicbox

Add the user to the group audio

	usermod -a -G audio musicbox

Create a couple of directories inside the user dir:

	mkdir -p /home/musicbox/.config/mopidy

	mkdir -p /home/musicbox/.cache/mopidy

	mkdir -p /home/musicbox/.local/share/mopidy

	chown -R musicbox:musicbox /home/musicbox

**One last thing**

And create the directory containing the music

	mkdir -p /music/local

	mkdir -p /music/network

	chmod -R 777 /music

	chown -R musicbox:musicbox /music

That’s it. MusicBox should now start when you reboot!

**Optimizations**
-----------------

For the music to play without cracks, you have to optimize your system a bit. For MusicBox, these are the optimizations:

**Fstab**

Make sure that root is mounted with the flag noatime. Normally this would be configured that way already.
You can also add these options, to put the most used directories in RAM, instead of using the SD-Card:

	tmpfs      	/tmp       	tmpfs  	defaults,noatime        	0 	0
	
	tmpfs      	/var/tmp   	tmpfs  	defaults,noatime        	0 	0
	
	tmpfs      	/var/log   	tmpfs  	defaults,noatime        	0 	0
	
	tmpfs      	/var/mail  	tmpfs  	defaults,noatime        	0 	0

**More fun with RAM**

Add the next lines to the file /etc/default/rcS 

	RAMRUN=yes 

	RAMLOCK=yes

This will run more stuff in RAM, instead of the SD-Card.

**Less Turbo**

Add the following option to /boot/cmdline.txt 

	smsc95xx.turbo_mode=N

This will prevent the ethernet system from using burst to increase the network throughput. This can interfere with the music data sent over usb.

**Services**

Disable services that are not needed. NTP is disabled because the time is updated at boot.

	update-rc.d ntp disable

**USB Sound**

Edit the sound settings of USB Cards in /etc/modprobe.d/modprobe.conf :

Find the line

	options snd-usb-audio index=-2

and add this:

	options snd-usb-audio index=-2 nrpacks=1

**Group Power**

Give the audio group more power by editting /etc/security/limits.conf

	@audio - rtprio 99

	@audio - memlock unlimited

	@audio - nice -19

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


That’s it for now. Thanks!
- Wouter van Wijk

10 september 2013
