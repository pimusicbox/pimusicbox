***********
This project is no longer maintained.
***********

There will be no more releases and probably no more support from myself.
The Pi 4 and Zero W 2 do not work with the last release and I don't know
of any workarounds.

Potential alternative software (in no particular order):

* `HiFiBerryOS <https://www.hifiberry.com/hifiberryos>`_ (Free, Open-Source)
* `Volumio <https://volumio.com>`_ (Free?)
* `Roon <https://roonlabs.com/>`_ (Non-free?)

Have a suggestion/recommendation? Open a PR.


***********
Pi MusicBox
***********

Pi MusicBox is the Swiss Army Knife of streaming music on the Raspberry Pi.
With Pi MusicBox, you can create a cheap (Sonos-like) standalone streaming
music player for Spotify and other online music services.


Maintainer Wanted
=================

This project is outdated and requires more work than I am currently prepared
to invest. If you are interested in becoming the maintainer then please get
in touch.


Features
========

- Headless audio player based on `Mopidy <https://www.mopidy.com/>`_. Just
  connect your speakers or headphones - no need for a monitor.
- Quick and easy setup with no Linux knowledge required.
- Stream music from Spotify, SoundCloud, Google Music and YouTube.
- Listen to podcasts (with iTunes and Podder directories) as well as online
  radio (TuneIn, Dirble and Soma FM).
- Play MP3/OGG/FLAC/AAC music from your SD card, USB drives and network shares.
- Remote controllable with a choice of browser-interfaces or with an MPD-client
  (e.g. `MPDroid
  <https://play.google.com/store/apps/details?id=com.namelessdev.mpdroid>`_ for
  Android).
- AirTunes/AirPlay and DLNA streaming from your smartphone, tablet or computer.
- Support for all kinds of USB, HifiBerry and IQ Audio soundcards.
- Wi-Fi support (WPA, Raspbian supported Wi-Fi adapters only)
- Last.fm scrobbling.
- Spotify Connect support.

**Please note that Pi MusicBox does NOT currently support the Raspberry Pi 4.**


Installation
============

1. Download the `latest release <https://github.com/pimusicbox/pimusicbox/releases>`_.
2. Write the image to your SD card. See `here <https://www.raspberrypi.org/documentation/installation/installing-images/README.md>`_ for details.
3. Customise the /boot/config/settings.ini file.
4. Boot your Raspberry Pi and wait for PiMusicbox to start.
5. Finish configuring the system using the web settings.  


Creating an image
=================

If you want to build an image from source, note that the current v0.7 image is an
incremental update of v0.6 and can be generated as follows::

    # 1. Install prerequisite packages (probably not an exhaustive list, sorry....)
    sudo apt-get install git coreutils e2fsprogs zerofree util-linux qemu-user-static latexmk python-sphinx

    # 2. Download and unzip very latest project source files (use master.zip for current release)
    wget https://github.com/pimusicbox/pimusicbox/archive/develop.zip
    unzip develop.zip && mv pimusicbox-develop src

    # 3. Download and unzip base v0.6 image
    wget https://github.com/pimusicbox/pimusicbox/releases/download/v0.6.0/pimusicbox-0.6.0.zip
    unzip pimusicbox-0.6.0.zip && mv musicbox0.6.img musicbox.img

    # 4. Enlarge image so there is free space to work in 
    ./src/makeimage.sh musicbox.img bigger

    # 5. Run update script within base image (requires sudo).
    ./src/chroot.sh musicbox.img create_musicbox0.7.sh

    # 6. Go have a cup of tea/coffee while you wait...

    # 7. Shrink the image and other finishing touches
    ./src/makeimage.sh musicbox.img finalise


Project resources
=================

- `Website <http://www.pimusicbox.com/>`_
- `Discussion forum <https://discourse.mopidy.com/c/pi-musicbox>`_
- `Source code <https://github.com/pimusicbox/pimusicbox>`_
- `Changelog <https://github.com/pimusicbox/pimusicbox/blob/develop/docs/changes.rst>`_
- `Issue tracker <https://github.com/pimusicbox/pimusicbox/issues>`_
- Twitter: `@PiMusicBox <https://twitter.com/pimusicbox>`_
- Facebook: `raspberrypimusicbox <https://www.facebook.com/raspberrypimusicbox>`_


License
=======

Copyright 2013-2020 Wouter van Wijk and contributors.

Licensed under the Apache License, Version 2.0. See the file LICENSE for the
full license text.
