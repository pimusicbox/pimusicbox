.. _faq:

**************************
Frequently Asked Questions
**************************

Where can I ask my own questions and get further support?

    You can discuss features and problems on the 
    `forum <https://discourse.mopidy.com/c/pi-musicbox>`_. Please search before
    creating a new topic as your question may have already been answered.
    You can also try the #mopidy channel on `Freenode <https://www.freenode.net/>`_.
    For more general Raspberry Pi questions you may find better answers on the 
    `official Raspberry Pi forum <https://www.raspberrypi.org/forums/>`_.

What hardware is supported?

    All Raspberry Pi models are supported but you'll find the system is noticeably
    faster and more responsive on a Raspberry Pi 2 or 3.

What are the default login credentials?

    Username: ``root``, password: ``musicbox``
    You should change this password as soon as possible.
    
Can I use the free version of Spotify?

    No, you must have a Spotify Premium account. 
    Spotify does not allow free users to stream using third party clients.

Can I use Spotify Connect?

    YES! There is support for Spotify Connect in the latest release provided by the
    brilliant `librespot <https://github.com/plietar/librespot/>`_ software. This
    reverse engineered implementation provides most Connect functionality but should
    still be considered experimental.
    Please direct any frustrations regarding the state of affairs at Spotify as they
    are responsible for not making the Connect API available.

Can I use Spotify radio?

    Unfortunately Spotify's current libspotify SDK does not support this functionality.

Is there a way to upgrade the system?

    There is currently no real upgrade path. The only way to upgrade is to
    download the latest image and copy over your :file:`settings.ini` file.

I tried to upgrade my installation with apt-get/pip and now I'm having issues. what should I do?

    This is not supported (see above) and it's not advisable unless you know what
    you are doing. If you don't know what you are doing then reinstall the
    latest version and then try to ask for support on the
    `forum <https://discourse.mopidy.com/c/pi-musicbox>`_ where someone may be
    able and willing to help you.

What happened to streamuris.js? How do I change the saved stream list?

    Radio stations are now stored in :file:`/music/playlists/[Radio Streams].m3u`
    and will appear in a playlist called 'Musicbox Favourites'. You can modify this 
    playlist using the webclient's Streams page or by editing the underlying
    playlist file. Any modifications you make will be visible to all clients.
    
Can I edit my playlists from Pi Musicbox?

    You can save the current track queue as a 'local' playlist but note it will
    only be available on your Pi Musicbox system. Some webclients, such as
    mopidy-mobile, also provide an interface to edit these local playlists. For
    now, Spotify playlists can only be modified using the official Spotify
    apps/website.

Can I use my HiFiBerry/IQAudio/PhatDAC/USB/JustBoom soundcard?

    Yes, but you must specify the particular soundcard in :file:`settings.ini`
    or the settings webpage. Most soundcards are supported but if you find yours
    isn't then please request it on the
    `forum <https://discourse.mopidy.com/c/pi-musicbox>`_.

Can I use my Bluetooth speaker?

    No, unfortunately we don't support this (yet). If you are able to get it
    working please share your findings on the `forum
    <https://discourse.mopidy.com/c/pi-musicbox>`_.

How do I make my random USB device work with Pi Musicbox?

    Pi Musicbox is based on Raspbian Wheezy but includes all drivers from the very
    latest Raspbian Jessie release. Any USB device that works with a regular Raspbian
    installation should also work with Pi Musicbox. If you encounter any problems then
    search the `forum <https://discourse.mopidy.com/c/pi-musicbox>`_ for help.

Can I use a different user interface?

    Yes, you can use your favourite MPD client or choose from any of the available
    webclients. Note that webclients generally perform better than MPD clients and
    provide a richer user experience. A list of installed webclients can be found
    at http://musicbox/mopidy/ and the default webclient can be specified on the 
    settings webpage.

Can I have several Pi Musicbox systems streaming content to one another?

    Not yet, but I'm hoping to get it implemented one day.

Can I access the Pi remotely via terminal/command line?

    Yes, enable SSH access in :file:`settings.ini` or the settings webpage.

Where can I find the source files and submit improvements to Pi Musicbox?

    https://github.com/pimusicbox/pimusicbox

Can Pi Musicbox stream *to* my Airplay device?

    No, this functionality is not supported.

Can Pi Musicbox output to several devices via a multi-channel USB audio device?

    No, this functionality is not supported. 

Can I use my Spotify account on several different Musicboxes at once?

    No, this is a Spotify restriction.

Can I get Pi Musicbox to play a song, playlist or radio station on startup?

    Yes, configure the autoplay functionality in :file:`settings.ini` or the
    settings webpage. Search the
    `forum <https://discourse.mopidy.com/c/pi-musicbox>`_ for examples.

Will you add support for XYZ streaming service?

    Support for additional streaming services in Pi MusicBox depends on support 
    in Mopidy which may or may not be available yet. Please search the 
    `forum <https://discourse.mopidy.com/c/pi-musicbox>`_ for more information
    regarding the streaming service you're interested in.

Why isn't http://musicbox.local working on my Android device?

    Even the very latest version of Android does not have support for using
    .local names on your home network. Most home routers should allow you to
    access http://musicbox instead. Alternatively, you'll need to configure
    an IP address reservation (or similar) on your router to ensure the IP
    address of your Pi Musicbox system does not change between reboots and
    simply bookmark that particular IP address.
