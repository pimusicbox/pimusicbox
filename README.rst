***********
Pi MusicBox
***********

Pi MusicBox is the Swiss Army Knife of streaming music on the Raspberry Pi.
With Pi MusicBox, you can create a cheap (Sonos-like) standalone streaming
music player for Spotify and other online music services.


Features
========

- Headless audio player based on `Mopidy <https://www.mopidy.com/>`_. Just
  connect your speakers or headphones - no need for a monitor.
- Quick and easy setup with no Linux knowledge required.
- Stream music from Spotify, SoundCloud, Google Music, YouTube and Subsonic.
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


Creating an image
=================

The current v0.7 image is an incremental update of v0.6 and can be generated as
follows::

    # 1. Install prerequisite packages (probably not an exhaustive list, sorry....)
    sudo apt-get install git coreutils e2fsprogs zerofree util-linux qemu-arm-static

    # 2. Download and unzip very latest project source files (use master.zip for current release)
    wget https://github.com/pimusicbox/pimusicbox/archive/develop.zip
    unzip develop.zip && mv pimusicbox-develop src

    # 3. Download and unzip base v0.6 image
    wget https://github.com/pimusicbox/pimusicbox/releases/download/v0.6.0/pimusicbox-0.6.0.zip
    unzip pimusicbox-0.6.0.zip && mv pimusicbox-0.6.0/*.img musicbox.img

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
- `Discussion forum <https://discuss.mopidy.com/c/pi-musicbox>`_
- `Source code <https://github.com/pimusicbox/pimusicbox>`_
- `Changelog <https://github.com/pimusicbox/pimusicbox/blob/master/changes.rst>`_
- `Issue tracker <https://github.com/pimusicbox/pimusicbox/issues>`_
- Twitter: `@PiMusicBox <https://twitter.com/pimusicbox>`_
- Facebook: `raspberrypimusicbox <https://www.facebook.com/raspberrypimusicbox>`_


License
=======

Copyright 2013-2017 Wouter van Wijk and contributors.

Licensed under the Apache License, Version 2.0. See the file LICENSE for the
full license text.
