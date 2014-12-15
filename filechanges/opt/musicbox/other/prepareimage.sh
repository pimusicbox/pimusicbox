#!/bin/bash
#
# MusicBox image clean and preparation script
#
apt-get remove build-essential git gcc cpp debian-reference-common g++ make ttf-bitstream-vera linux-libc-dev python-dev
apt-get remove .*-dev
apt-get autoremove
apt-get autoclean
apt-get clean

#fix stream link
rm /usr/local/lib/python2.7/dist-packages/mopidy_musicbox_webclient/static/js/streamuris.js
ln -s /boot/config/streamuris.js /usr/local/lib/python2.7/dist-packages/mopidy_musicbox_webclient/static/js/streamuris.js