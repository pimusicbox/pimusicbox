.. _raspberrypi-installation:

****************************
Installation on Raspberry Pi
****************************

Running Mopidy on a `Raspberry Pi <http://www.raspberrypi.org/>`_ is possible, but it's sometimes difficult to install. This document is intended to help you get
Mopidy running on your Raspberry Pi.

This document describes the way you can install Mopidy on a Raspberry Pi by yourself. An easy to use image already exists. It's called Pi MusicBox. Most difficulties (and there are some!) have been handled in that image. You can download it `over here <http://www.woutervanwijk.nl/pimusicbox/>`_.

Mopidy will run with Spotify support on both the armel (soft-float) and armhf (hard-float) architectures, which includes the Raspbian distribution.

.. image:: /_static/raspberry-pi-by-jwrodgers.jpg
    :width: 640
    :height: 427

.. _raspi-wheezy:

How to for Debian 7 (Wheezy) and Raspbian
=========================================

1. Download the latest wheezy disk image from
   http://downloads.raspberrypi.org 
   You can also try `Moebius Linux <http://moebiuslinux.sourceforge.net/>`_, a stripped
   version of Raspbian.
 
2. Flash the OS image to your SD card. See
   http://elinux.org/RPi_Easy_SD_Card_Setup for help.

3. If you have an SD card that's >2 GB, you don't have to resize the file
   systems on another computer. Just boot up your Raspberry Pi with the
   unaltered partitions, and it will boot right into the ``raspi-config`` tool,
   which will let you grow the root file system to fill the SD card. This tool
   will also allow you do other useful stuff, like turning on the SSH server.

4. You can login to the
   default user using username ``pi`` and password ``raspberry``. To become
   root, just enter ``sudo -i``.

5. To avoid a couple of potential problems with Mopidy, turn on IPv6 support:

   - Load the IPv6 kernel module now::

         sudo modprobe ipv6

   - Add ``ipv6`` to ``/etc/modules`` to ensure the IPv6 kernel module is
     loaded on boot::

         echo ipv6 | sudo tee -a /etc/modules

6. Installing Mopidy and its dependencies from `apt.mopidy.com
   <http://apt.mopidy.com/>`_, as described in :ref:`installation`. In short::

       wget -q -O - http://apt.mopidy.com/mopidy.gpg | sudo apt-key add -
       sudo wget -q -O /etc/apt/sources.list.d/mopidy.list http://apt.mopidy.com/mopidy.list
       sudo apt-get update && sudo apt-get upgrade && sudo apt-get install mopidy

Configuration
=============

Now that you have installed Mopidy, a little configuration is necessary, depending on what you want.

1. When you have a HDMI cable connected, but want the sound on the analog sound
   connector, you have to run::

       amixer cset numid=3 1

   to force it to use analog output. ``1`` means analog, ``0`` means auto, and
   is the default, while ``2`` means HDMI. You can test sound output
   independent of Mopidy by running::

       aplay /usr/share/sounds/alsa/Front_Center.wav

   If you hear a voice saying "Front Center", then your sound is working. Don't
   be concerned if this test sound includes static. Test your sound with
   GStreamer to determine the sound quality of Mopidy.

   To make the change to analog output stick, you can add the ``amixer``
   command to e.g. ``/etc/rc.local``, which will be executed when the system is
   booting.

2. 



Audio quality issues
====================

The Raspberry Pi's audio quality can be flat through the analog output. This
is known and unlikely to be fixed as including any higher-quality hardware
would increase the cost of the board. If you experience crackling/hissing or
skipping audio, you may want to try a USB sound card. Additionally, you could
lower your default ALSA sampling rate to 22KHz, though this will lead to a
substantial decrease in sound quality.

As of January 2013, some reports also indicate that pushing the audio through
PulseAudio may help. We hope to, in the future, provide a complete set of
instructions here leading to acceptable analog audio quality.


Support
=======

If you had trouble with the above or got Mopidy working a different way on
Raspberry Pi, please send us a pull request to update this page with your new
information. As usual, the folks at ``#mopidy`` on ``irc.freenode.net`` may be
able to help with any problems encountered.
