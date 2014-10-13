****************************
Pi MusicBox
****************************

Pi MusicBox is the Swiss Army Knife of streaming music on the Raspberry Pi. With Pi MusicBox, you can create a cheap (Sonos-like) standalone streaming music player for Spotify and other music streams. 

This is the code used to create the image (download from `www.pimusicbox.com
<http://www.pimusicbox.com/>`_)

Features
========

- Headless audio player based on Mopidy (no need for a monitor), streaming music from Spotify, SoundCloud, Google Music, Podcasts (with iTunes, gPodder directories), MP3/OGG/FLAC/AAC, Webradio (with TuneIn, Dirble directories), Subsonic, Soma FM.
- Remote control it with a nice browser-interface or with an MPD-client like MPDroid for Android.
- Also includes AirTunes/AirPlay and DLNA streaming from your phone, tablet (iOS and Android)
- USB Audio support, for all kinds of USB soundcards, speakers, headphones. The sound from the Pi itself is not that good...
- Wifi support (WPA, for Raspbian supported wifi-adapters)
- No need for tinkering, no need to use the Linux commandline
- Play music files from the SD Card, USB, Network.
- Last.FM scrobbling.
- Most HifiBerry, IQ Audio soundcards supported

Usage
=====

The files (modified or new) for the system are in the directory /filechanges. In the root you'll find a description on how to build it and the build scripts.


Project resources
=================

- `Source code <https://github.com/woutervanwijk/pi-musicbox>`_
- `Issue tracker <https://github.com/woutervanwijk/pi-musicbox/issues>`_
- `Development branch tarball <https://github.com/woutervanwijk/pi-musicbox/archive/master.tar.gz>`_


Changelog
=========

Look at the file /filechanges/boot/config/changes.txt for a full overview. 

v0.5.1 beta
----------------------------------------

- Replaced gmediarender with upmpdcli for better and more stable upnp streaming support.
- Fixed stuttering of Spotify at the start of a track
- Bugfixes for webclient interface (popups work better now)
- Better soundcard detection
- Enable/disable Shairport and DLNA streaming
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
