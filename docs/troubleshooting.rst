***************
Troubleshooting
***************

.. note::
    The first boot may take a few minutes while the filesystem is expanded and
    configured for the first time, especially on Models A, B, B+ and Zero. If
    you have enabled media scanning and have a lot of music files, this will
    take even longer. Please be patient.

If you experience problems with Pi Musicbox your first port of call should be
the `discussion forum <https://discourse.mopidy.com/c/pi-musicbox>`_. Please
search before creating a new topic as your question may have already been
answered.  Otherwise feel free to ask any questions, suggest features or
report bugs.

When you're debugging yourself or asking for help, you should check the
following things first:

SD card

  Not all SD cards are created equal and even expensive branded cards are
  sometimes faulty. Try rewriting the image to a different memory card,
  preferably one you know definitely works. Always buy your SD cards from a
  trusted seller - beware of fakes! Card speed is not usually an issue and is
  only really noticeable when writing the image. The minimum card size is 1GB
  but a larger card is preferable as it leaves you with more free space. When
  powering off or restarting Pi Musicbox please make sure you shutdown the
  system first to avoid SD card corruption.
   
Power supply
  
  Some cheap unbranded 5V power supplies have been reported to cause problems,
  especially with the RPi Model 3B and/or power-hungry USB devices. If you're
  also connecting a USB harddisk ensure it has sufficient power; desktop drives
  must be connected via a powered hub or have their own dedicated power brick.
  Refer to the `Raspberry Pi website for further guidance
  <https://www.raspberrypi.org/documentation/hardware/raspberrypi/power/README.md>`_.

Wireless dongle

  If you are having wireless network problems then connecting an ethernet cable
  will allow you to get up and running and make further debug easier. When
  using USB wifi devices, the problem is often with the dongle itself so try
  a different one. 

Startup errors

  Most errors occuring during startup will print an accompanying error message
  to help you identify the underlying problem. Attaching a computer monitor or
  TV screen via HDMI will allow you to view these error messages. This is
  particularly useful when network problems are preventing you from gaining
  remote access to the system via SSH (see below).

Enable SSH remote access

  Being able to connect to the system from another computer will make debugging
  much easier. To enable SSH in Pi Musicbox, set ``enable_ssh = true`` in 
  :file:`settings.ini` or use the settings webpage. Help on how to connect from
  your Windows computer is available `here
  <https://www.raspberrypi.org/documentation/remote-access/ssh/windows.md>`_.
  You must have a working network connection to do this but if you don't,
  you can still login locally by attachng a USB keyboard. In either case, the
  username is ``root`` and the default password is ``musicbox``.
   
Log files

  Once logged in, you can view the various log filesfor more hints. The startup
  log can be found at :file:`/var/log/musicbox_startup.log` and the Mopidy log
  can be found at :file:`/var/log/mopidy/mopidy.log`. If you enable Mopidy's
  more detailed debug logging (via the settings webpage) you'll find that log
  file at :file:`/tmp/mopidy-debug.log`. Note that this debug log will be lost
  when Pi Musicbox is powered off or restarted. When posting in the forum
  please try to provide all relevant log files.

Config file

  If there is a typo, error or corruption in your :file:`settings.ini` config
  file then usually the system will still boot but the Mopidy music server will
  not start. When this occurs you may find you'll be able to connect via SSH,
  use Airplay, Spotify Connect etc. but you'll be unable to access the settings
  webpage, the webclients, or use your MPD client. If this happens, login and
  check :file:`/var/log/mopidy/mopidy.log` for config errors. To display the
  current active config run ``service mopidy run config``; this output has all
  sensitive information such as passwords removed so it is suitable for sharing
  on the forum.
