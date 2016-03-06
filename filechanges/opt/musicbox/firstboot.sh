#!/bin/bash
#
# MusicBox configuration to do once on first boot
#

. /opt/musicbox/utils.sh

echo "Regenerating SSH keys..."
rm -rf /etc/ssh/ssh_host_*
rm -rf /etc/dropbear/*_host_key
dpkg-reconfigure dropbear

echo "Expanding filesystem..."
raspi-config --expand-rootfs 2>/dev/null

set_reboot_needed
