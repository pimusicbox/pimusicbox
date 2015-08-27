.. _faq:

**************************
Frequently Asked Questions
**************************

Where can I ask questions and get support?

    You can discuss features and problems on the `forum
    <https://discuss.mopidy.com/>__. Please report bugs about MusicBox itself
    at `the repo at Github <https://github.com/pimusicbox/pimusicbox>`__. You
    can also try the #mopidy channel on `Freenode
    <https://www.freenode.net/>`_, or the `Raspberry Pi forums
    <https://www.raspberrypi.org/forums/>`_.

What were the login credentials again? I forgot them...

    Username: ``root``, password: ``musicbox``

Is there a way to upgrade the music box image, or is the only solution to use
the whole new image? 

    For now, there is no real upgrade path, and the only way to upgrade is to
    simply download the newest image. You could copy over your
    :file:`settings.ini` and :file:`streamuris.js` config files to the new
    image.

Can I use the free version of Spotify?

    No, sorry. Spotify does not allow free users to stream to third party
    clients.

Can I use Spotify Connect?

    No, sorry. Spotify has not released the API.

I upgraded my Musicbox with apt-get, now I'm having issues. Can you advise me
on what to do? 

    We would advise you not to upgrade your Raspbian unless it is absolutely
    necessary, as it tends to cause breakage.

Can I change the standard radio station list?

    Yes. Currently the list is stored in :file:`/boot/config/streamuris.js` which you
    can edit by hand with any text editor. You can also use any of the popular
    MPD clients on your phone/pc/mac, most of them have the option of storing
    playlists and radio stations locally. See http://mpd.wikia.com/wiki/Clients
    for a suggested client list.

Can I use Spotify radio?

    Unfortunately Spotify's current libspotify SDK does not support that
    function, if they implement it I'll try and include it.

Can I use HiFiBerry?

    Yes, use the latest version of Musicbox. Output through i2s.

Can I have several Musicboxes stream content to one another?

    Not yet, but I'm hoping to get it implemented one day.

Can i access the Pi via terminal/command line remotely?

    Yes, simply allow SSH in Pi Musicbox's settings.ini file.

Where can I find the hardcore technical info in Musicbox?

    https://github.com/pimusicbox/pimusicbox 

How do i make (insert wifi dongle name here) work with the Musicbox?

    Musicbox is built off Raspbian, so any supported dongle will most likely
    work, but as with all things Linux/GNU, breakage can (and usually will)
    occur.

Can the Musicbox stream to my airplay device?

    Right now it can't. We may implement this if we ever have enough time, as
    it is a complicated project to get it working.

Can I edit my Spotify playlists from the Musicbox?

    Once it is implemented in Mopidy, you'll be able to.

Can I run the Musicbox output to several devices via a multi-channel USB audio
device?

    To do that you would have to run multiple instances of Mopidy and make them
    run in sync, it's not supported and it isn't on my to-do list, sorry.

Is there a support forum where I can ask in-depth questions?

    Yes, https://discuss.mopidy.com/c/pi-musicbox.

Can I stream Spotify to several different Musicboxes at once?

    No, as this is a Spotify limitation.

    But perhaps if we get around to implementing the streaming from Musicbox to
    Musicbox, it may become possible.

Can I get the Musicbox to auto-start playing a playlist or radio station upon bootup ? 

    Yes, use the settings page!

Will you add WiMP support?

    WiMP support in MusicBox depends on WiMP support in Mopidy. The story of
    that can be read at https://github.com/mopidy/mopidy/issues/48. 
