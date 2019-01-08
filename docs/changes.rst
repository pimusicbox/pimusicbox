*********
Changelog
*********

v0.7.0RC7 (2019-01-08)
======================
- Raspberry Pi 3 A+ support
- Linux kernel v4.14.89
- Shairport-Sync v3.2.2

v0.7.0RC6 (2018-03-20)
======================
- Raspberry Pi 3 B+ support
- Librespot updated up v20180313-9d9c311 and added logging
- Updated Linux kernel to v4.14.26
- Fixed missing Allo Boss DAC firmware files
- Added support for Audioinjector soundcards
- Fixed boot loop when soundcard not found
- Removed Mopidy-Subsonic
- Backported OAuth functionality for Mopidy-Spotify to fix search

v0.7.0RC5 (2017-07-28)
======================
- Firewall is now optional and is DISABLED by default
- Added Spotify Connect functionality (librespot v20170717-910974e)
- Includes mpd-watchdog for restoring stream playback following connectivity loss
- Ability to configure the WiFi country and use region specific channels
- Updated Shairport-Sync to v3.0.2
- Support for 64 character hex keys
- Fixed blocked Airplay ports (broken in v0.7.0RC4)
- OPML podcast file now available in /boot/config/
- Support for SD card friendly Mopidy debug logging
- Currently broken Spotify browse features disabled/hidden
- Updated Spotify-Tunigo to latest version

v0.7.0RC4 (2017-03-21)
======================

- Updated Linux kernel to v4.9.16 and support Device Tree module loading
- Full support for Pi3 and Pi0W on-board WiFi
- Support JustBoom audio cards
- Fixed mDNS support (broken in v0.7.0RC3)
- Fixed default webclient redirect for Firefox (broken in v0.7.0RC3)
- Improve startup script output

v0.7.0RC3 (2017-03-15)
======================

- Updated upmpdcli to v1.2.11
- Fixed Shairport-Sync support
- Updated mopidy-dirble, mopidy-soundcloud, mopidy-musicbox-webclient
- "Fixed" mopidy-youtube preferring m4a streams
- "Fixed" slow MPD connection creation
- Removed streamuris. Favourite streams now stored in an m3u playlist in /music/playlists/

v0.7.0RC2 (2017-03-09)
======================

- Updated Shairport-Sync to v3.0
- Fixed support for HiFiBerry Digi

v0.7.0RC1 (2017-02-23)
======================

- Raspberry Pi 3 and Zero compatability (using updated kernel)
- Compatible with Mopidy v1.1.2
- Mopidy extensions updated
- "Fixed" spotify playlists not appearing
- Added mopidy-spotify-web
- Disabled alsamixer by default
- Implemented 2 minute timeout while waiting for network
- Removed wireless-ng package
- Limit overclocking settings to Raspberry Pi 1 hardware only
- Log startup to /var/log/musicbox_startup.log
- Add support for webapp type webclients
- Applying settings via websettings restarts Mopidy (not system) when possible

v0.6.0 (2015-04-06)
===================

- Raspberry Pi 2 compatability (using updated kernel)
- Enhanced support for local/networked files
- New version of the MusicBox-Webclient (2.0)
- Stability fixes
- Many other bugfixes
- Compatible with Mopidy 0.19.5

v0.6.0rc1 (2015-03-29)
======================

- Added support for HiFiBerry AMP
- Fixed USB soundcard detection
- Removed some entries for extensions in settings.ini where using defaults.
- Compatible with Mopidy 0.19.5

v0.5.4 (2015-02-25)
===================

- Initial Raspberry Pi 2 compatability

v0.5.3 (2015-01-18)
===================

- Mopidy 0.19.5 with bugfixes
- New version of Shairport-sync to fix problems
- Filesystem check settings changed, also to fix fsck problems

v0.5.2 (2014-12-18)
===================

- Wifi not coming up bug fixed
- Resize bug fixed
- Webinterface stops streams instead of pause
- Button to easily save current stream to favorites
- Fixed Spotify stuttering
- Fixed Spotify Browse
- Changed default settings of audio, SomaFM and others

v0.5.1 (2014-12-07)
===================

- Monitoring of crashed services enhanced
- Small bugfix in html

v0.5.1rc2 (2014-11-24)
======================

- No more slow loading of Spotify playlists
- Added audioaddict extension
- Other bugfixes

v0.5.1rc1 (2014-11-07)
======================

- Shairport-sync instead of Shairport. AirPlay audio now syncs to e.g. a video
- Webclient enhancements
- Mopidy-ALSAMixer extension included for hardware mixers (no gui, only in ini
  file)
- Removed fastclick to prevent accidental clicks in the webinterface
- Updated mopidy extensions
- Bugfixes

v0.5.1b1 (date unknown)
=======================

- Replaced gmediarender with upmpdcli for better and more stable upnp streaming support.
- Less stuttering of Spotify at the start of a track
- Bugfixes for webclient interface (popups work better now)
- Enable/disable Shairport and DLNA streaming
- Sound detection fixed
- SSH/Dropbear enhancements
- Bugfixes

v0.5.1a2 (2014-10-06)
=====================

- Mostly bugfixes
- Better support for albumart in webclient

v0.5.1a1 (date unknown)
=======================

- Google Music Works a lot better now, including search, albums, artists,
  coverart, browsing
- Support for cards from IQ Audio, newer HifiBerry, model B+
- More responsive Mopidy, version 0.19.4
- Youtube integration
- Nicer webclient with new homescreen
- Play streams from youtube, spotify, soundcloud, radio by pasting an url
- Search music per service
- SoundCloud search won't block other services anymore

v0.5.0 (2014-07-08)
===================

- Updated Google Music, SoundCloud
- Added missing webclient fonts
- Playing files from the network enhanced
- Disabled Samba printing
- Small changes, bugfixes
- Faster USB, no more stuttering for some DACs
- HifiBerry Digi support is not complete :( See :pimusicbox:`100`
- SoundCloud can break searching

v0.5.0b2 (date unknown)
=======================

- Google Music works again!
- Fixed bugs in webinterface
- Networking bug fixed
- Icons for media sources in webinterface
- Search fixed
- Added codecs for internetradio (gstreamer-plugins bad and ugly)
- Hifiberry Digi supported
- More wifi-usb sticks supported, I hope
- Bigger package (because of gstreamer plugins)

v0.5.0b1 (date unknown)
=======================

- Best release evah! Way less stuttering of sound!
- DLNA/UPNP streaming works out of the box (gmediarender-resurect)
- Fixed settings page, webclient, search bugs
- Added Internet Archive and Soma FM support
- Wifi will autoconnect to an open network if found
- Reverted back to old MusicBox system, new kernel (with better USB support).
  And thanks to that:
- Smaller package
- Monitoring of crashed daemons Shairport, Mopidy, Gmediarender
- Detection of crashed Pi (watchdog)
- Latest kernel (with a lot of fixes for USB)
- Whoosh backend for local files (should be faster)
- Updated Podcast
- Gmusic does not work reliable (yet)
- Upnp/Airplay/Mopidy cannot play at the same time. Don't do that, it can crash
  the services and this could need a reboot!

v0.5.0a4 (date unknown)
=======================

- Better mopidy performance
- Bugfixes

v0.5.0a3 (date unknown)
=======================

- New Settings page for easily selecting most settings of MusicBox!!
- Based on kernel from Volumio. Works nicely!
- Mopidy is more reliable now (thanks to new kernel?)
- Webclient updated to (way) better support browsing
- Podcast working, including browsing podcasts from iTunes, gpodder
- UPNP/DLNA Streaming using gmediarender-resurrect
- Seperate webserver (lighttp) on startup
- Jukebox functionality included with aternative webclient JukePi. Great for
  the office!
- Also included alternative webclient Moped
- Larger image. Only fits on a 2G SD for now :(
- Google Music All Access working again
- TuneIn, Dirble, Podcasts enabled by default
- Firewall disabled for now
- Mopidy extensions Radio-de/somafm/internetarchive not working (yet)
- Upnp/Airplay/Mopidy cannot play at the same time. Don't do that, it can crash
  the services and you need to reboot!

v0.5.0a2 (2014-03-07)
=====================

- Fix for networking problems (I hope!)
- Automatically play a stream at startup
- Webclient: Easier to add radiostations from Dirble/TuneIn browsing to the
  favorites in the radio section
- Webclient fixes
- Bugfixes (like samba/cifs mount, wifi, settings.ini)
- Disbled login for musicbox user. No need anymore
- Soma FM works
- Fixed partition size
- motd ascii art
- Resize bug fixed
- Check added for fat partition

v0.5.0a1 (2014-03-01)
=====================

- Mopidy 0.18.x, with lots of enhancements
- Browsing support for local media files, Spotify, Dirble, etc
- Dirble, Subsonic, Internet Archive Sound, TuneIn Radio support
- First steps to support Podcasts, SomaFM, Rad.io/Radio.de/Radio.fr (does not
  work (fully) yet)
- Better webradio (Mopidy can read m3u and asx files now!)
- Quick hack to easily edit default radio stations in webinterface (use
  radiostations.js)
- Better USB Sound, better i2s
- Settings.ini and mopidy.conf merged to one file, so you can configure Mopidy
  specific settings yourself easily
- Mopidy runs as a service
- More reliable networking
- Logging on startup (not totally there yet)
- Newer kernel
- Bugfixes

v0.4.3 (2014-01-08)
===================

- USB disks mounted at boot and scanned for music
- Better recognition of USB Dacs (Simon)
- Better scrolling on iOS
- Start SSH before filescan
- Slightly smaller image file (did not fit on all cards)

v0.4.2.1 (2013-12-31)
=====================

- Fix for bug in setting default volume
- Fix for bug in setting spotify bitrate

v0.4.2 (2013-12-30)
===================

- Best sounding Pi MusicBox ever! No hiccups, no unwanted noises, just music!
- Shutdown/Reboot from interface
- Font-icons for shuffle/repeat in interface
- Disabled power management for wireless dongles
- Better hdmi support (hotplug, force open)
- Newer Kernel: 3.10.24+ (i2s included)
- Split startup script into multiple files for better management
- Initial i2s support by Simon de Bakker/HifiBerry
- Set default volume in config file (Simon again)
- Log file viewable via webinterface ( http://musicbox.local/log )
- Initial work to support a settings page in the webinterface (not working yet)
- No hamsters were harmed during the production

v0.4.1 (2013-12-21)
===================

- Bugfix for SoundCloud in webinterface
- Bugfix for distorted sound on some webradiostations

v0.4.0 (2013-12-15)
===================

- Bugfixes: setting passwords, webclient inputfields in Safari
- Info: Uses Mopidy 0.15, Linux 3.6.11+ (updated Moebius Linux), Shairport
  0.05, Mopidy Webclient 0.15 (JQuery Mobile 1.3 + flat client)

v0.4.0b1 (date unknown)
=======================

- Much nicer interface, thanks to Ulrich Lichtenegger
- Small bugfixes

v0.4.0a2 (date unknown)
=======================

- A lot of smaller and bigger bugfixes
- Support for Google Music All Access

v0.4.0a1 (date unknown)
=======================

- Use multiple Pi's on the same network (Multiroom Audio)
- Webradio support
- SoundCloud support (beta!)
- Google Music support (alpha!)
- Windows workgroup name configuration

- Completely refreshed system

  - Big updates to web interface (faster, cleaner, more stable, more options)
  - Big updates to Mopidy music server
  - Optimizations to have less services running, less logging, less writes to
    SD-Card, no unwanted noises

- Security

  - Better security trough a simple firewall
  - Mopidy runs as a normal user now
  - SSH service disabled by default
  - Automatically change passwords of musicbox and root users

v0.3.0 (date unknown)
=====================

- All configuration is done in one ini-file
- HDMI output supported
- Autodetection of HDMI at start (next to autodetection of USB)
- Override output setting in ini-file
- LastFM scrobbling enabled
- Webinterface updated (speedier)
- Local music files supported, accessible via windows network (but not yet in
  webinterface)

v0.2.2 (date unknown)
=====================

- Windows finds the musicbox.local address by itself now (samba).

v0.2.1 (date unknown)
=====================

Removed ugly sounds on analog port when changing tracks (pulseaudio). An
USB-soundcard is still recommended.

v0.2.0 (date unknown)
=====================

- Based on Raspbian for better performance
- Nicer Webinterface
- Turbo

v0.1.4 (date unknown)
=====================

- Enabled Medium Turbo mode to speedup everything, usb sound works
  automagically, bugs fixed.
- Login screen isn't cleared anymore.
- Set sound volume on boot.
- Reset network config, clear logs, etc.
- Script to create image.

v0.1.3 (date unknown)
=====================

- New kernel, added raspberry packages.

v0.1.1 (date unknown)
=====================

- Updates, fixed some small bugs, updated webclient

v0.1.0 (date unknown)
=====================

- Initial release
