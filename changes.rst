**Pi MusicBox Changelog**
-------------------------

v0.5.1 beta2
----------------------------------------
- Shairport-sync instead of Shairport. AirPlay audio now syncs.
- Webclient enhancements
- Alsamixer extension included for hardware mixers (no gui, only in ini file)

v0.5.1 beta
----------------------------------------

- Replaced gmediarender with upmpdcli for better and more stable upnp streaming support.
- Less stuttering of Spotify at the start of a track
- Bugfixes for webclient interface (popups work better now)
- Enable/disable Shairport and DLNA streaming
- Sound detection fixed
- SSH/Dropbear enhancements
- Bugfixes

0.5.1 alpha2 - 6 october 2014
----------------------------------------

- Mostly bugfixes.
- Better support for albumart in webclient

0.5.1 alpha
----------------------------------------

- Google Music Works a lot better now, including search, albums, artists, coverart, browsing
- Support for cards from IQ Audio, newer HifiBerry, model B+
- More responsive mopidy, version 0.19.4
- Youtube integration
- Nicer webclient with new homescreen
- Play streams from youtube, spotify, soundcloud, radio by pasting an url
- Search music per service
- SoundCloud search won't block other services anymore

0.5 8 july 2014
----------------------------------------

- Updated Google Music, SoundCloud
- Added missing webclient fonts
- Playing files from the network enhanced
- Disabled Samba printing
- Small changes, bugfixes
- Faster USB, no more stuttering for some DACs
- HifiBerry Digi support is not complete :( See https://github.com/woutervanwijk/Pi-MusicBox/issues/100
- SoundCloud can break searching

0.5 beta2
----------------------------------------

- Google Music works again!
- Fixed bugs in webinterface
- Networking bug fixed
- Icons for media sources in webinterface
- Search fixed
- Added codecs for internetradio (gstreamer-plugins bad and ugly)
- Hifiberry Digi supported
- More wifi-usb sticks supported, I hope
- Bigger package (because of gstreamer plugins)

0.5 beta1
----------------------------------------

- Best release evah! Way less stuttering of sound!
- DLNA/UPNP streaming works out of the box (gmediarender-resurect)
- Fixed settings page, webclient, search bugs
- Added Internet Archive and Soma FM support
- Wifi will autoconnect to an open network if found
- Reverted back to old MusicBox system, new kernel (with better USB support). And thanks to that:
- Smaller package
- Monitoring of crashed daemons Shairport, Mopidy, Gmediarender
- Detection of crashed Pi (watchdog)
- Latest kernel (with a lot of fixes for USB)
- Whoosh backend for local files (should be faster)
- Updated Podcast
- Gmusic does not work reliable (yet)
- Upnp/Airplay/Mopidy cannot play at the same time. Don't do that, it can crash the services and this could need a reboot!

0.5 alpha4
----------------------------------------

- Better mopidy performance
- Bugfixes

0.5 alpha3
----------------------------------------

- New Settings page for easily selecting most settings of MusicBox!!
- Based on kernel from Volumio. Works nicely!
- Mopidy is more reliable now (thanks to new kernel?)
- Webclient updated to (way) better support browsing
- Podcast working, including browsing podcasts from iTunes, gpodder
- UPNP/DLNA Streaming using gmediarender-resurrect
- Seperate webserver (lighttp) on startup
- Jukebox functionality included with aternative webclient JukePi. Great for the office!
- Also included alternative webclient Moped
- Larger image. Only fits on a 2G SD for now :(
- Google Music All Access working again
- TuneIn, Dirble, Podcasts enabled by default
- Firewall disabled for now
- Mopidy extensions Radio-de/somafm/internetarchive not working (yet)
- Upnp/Airplay/Mopidy cannot play at the same time. Don't do that, it can crash the services and you need to reboot!

0.5 alpha2 - March 7 2014
----------------------------------------

- Fix for networking problems (I hope!)
- Automatically play a stream at startup
- Webclient: Easier to add radiostations from Dirble/TuneIn browsing to the favorites in the radio section
- Webclient fixes
- Bugfixes (like samba/cifs mount, wifi, settings.ini)
- Disbled login for musicbox user. No need anymore
- Soma FM works
- Fixed partition size
- motd ascii art
- Resize bug fixed
- Check added for fat partition

0.5 alpha - March 1 2014
----------------------------------------

- Mopidy 0.18.x, with lots of enhancements
- Browsing support for local media files, Spotify, Dirble, etc
- Dirble, Subsonic, Internet Archive Sound, TuneIn Radio support
- First steps to support Podcasts, SomaFM, Rad.io/Radio.de/Radio.fr (does not work (fully) yet)
- Better webradio (Mopidy can read m3u and asx files now!)
- Quick hack to easily edit default radio stations in webinterface (use radiostations.js)
- Better USB Sound, better i2s
- Settings.ini and mopidy.conf merged to one file, so you can configure Mopidy specific settings yourself easily
- Mopidy runs as a service
- More reliable networking
- Logging on startup (not totally there yet)
- Newer kernel
- Bugfixes

0.4.3 - 8 january 2014
USB disks mounted at boot and scanned for music
Better recognition of USB Dacs (Simon)
Better scrolling on iOS
Start SSH before filescan
Slightly smaller image file (did not fit on all cards)

0.4.2.1 - 31 december 2013
Fix for bug in setting default volume
Fix for bug in setting spotify bitrate

0.4.2 - 30 december 2013
Best sounding Pi MusicBox ever! No hiccups, no unwanted noises, just music!
Shutdown/Reboot from interface
Font-icons for shuffle/repeat in interface
Disabled power management for wireless dongles
Better hdmi support (hotplug, force open)
Newer Kernel: 3.10.24+ (i2s included)
Split startup script into multiple files for better management
Initial i2s support by Simon de Bakker/HifiBerry
Set default volume in config file (Simon again)
Log file viewable via webinterface ( http://musicbox.local/log )
Initial work to support a settings page in the webinterface (not working yet)
No hamsters were harmed during the production

0.4.1 (21 december 2013)
Bugfix for SoundCloud in webinterface
Bugfix for distorted sound on some webradiostations

0.4 (15 december 2013)
Bugfixes: setting passwords, webclient inputfields in Safari
Info:
Uses Mopidy 0.15, Linux 3.6.11+ (updated Moebius Linux),
Shairport 0.05, Mopidy Webclient 0.15 (JQuery Mobile 1.3 + flat client)

0.4-beta
Much nicer interface, thanks to Ulrich Lichtenegger
Small bugfixes

0.4-alpha2
A lot of smaller and bigger bugfixes
Support for Google Music All Access

0.4-alpha
Use multiple Pi's on the same network (Multiroom Audio)
Webradio support
SoundCloud support (beta!)
Google Music support (alpha!)
Windows workgroup name configuration

Completely refreshed system
Big updates to web interface (faster, cleaner, more stable, more options)
Big updates to Mopidy music server
Optimizations to have less services running, less logging, less writes to SD-Card, no unwanted noises

Security
Better security trough a simple firewall
Mopidy runs as a normal user now
SSH service disabled by default
Automatically change passwords of musicbox and root users

0.3
All configuration is done in one ini-file
HDMI output supported
Autodetection of HDMI at start (next to autodetection of USB)
Override output setting in ini-file
LastFM scrobbling enabled
Webinterface updated (speedier)
Local music files supported, accessible via windows network (but not yet in webinterface)

0.2.2
Windows finds the musicbox.local address by itself now (samba).

0.2.1
Removed ugly sounds on analog port when changing tracks (pulseaudio). An USB-soundcard is still recommended.

0.2
Based on Raspbian for better performance
Nicer Webinterface
Turbo

0.01.4
Enabled Medium Turbo mode to speedup everything, usb sound works automagically, bugs fixed. Login screen isn't cleared anymore. Set sound volume on boot. Reset network config, clear logs, etc. Script to create image.

0.01.3
New kernel, added raspberry packages.

0.01.1
Updates, fixed some small bugs, updated webclient

0.01
Initial release
