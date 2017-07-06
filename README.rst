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


Building an image
=================

The current v0.7 image is an incremental update and can be generated with the
following steps::

    sudo apt-get install git coreutils e2fsprogs zerofree util-linux qemu-arm-static
    wget https://dl.mopidy.com/pimusicbox/pimusicbox-0.6.0.zip
    unzip pimusicbox-0.6.0.zip
    git clone https://github.com/pimusicbox/pimusicbox
    cd pimusicbox
    IMG=../pimusicbox-0.6.0/musicbox0.6.img
    ./makeimage.sh bigger $IMG
    ./chroot.sh $IMG create_musicbox0.7.sh
    IMAGE_ONLY=yes ./makeimage.sh release $IMG


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

Copyright 2013-2016 Wouter van Wijk and contributors.

Licensed under the Apache License, Version 2.0. See the file LICENSE for the
full license text.
