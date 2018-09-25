#!/bin/sh 
#
# Automatically resize the filesystem of a Raspberry Pi SD-Card
# is part of raspi-config Copyright (c) 2012 Alex Bradbury <asb@asbradbury.org>
# adapted by Wouter van Wijk 2013
# 

if [ "$1" != "-y" ] 
then
  echo "Do you want to resize the filesystem? A reboot is required. Use at your own risk! (y/N)"
  read -r ASK
  if [ "$ASK" != "y" ] && [ "$ASK" != "Y" ]
  then
    exit 1
  fi
fi

  echo
  echo "Resizing the filesystem. This can take a while, please wait..."
  echo
  # Get the starting offset of the root partition
  PART_START=$(parted /dev/mmcblk0 -ms unit s p | grep "^2" | cut -f 2 -d: | tr -cd "[:digit:]")
  echo "$PART_START"
  [ "$PART_START" ] || exit 1
  # Return value will likely be error for fdisk as it fails to reload the 
  # partition table because the root fs is mounted
  fdisk /dev/mmcblk0 <<EOF
p
d
2
n
p
2
$PART_START

p
w
EOF

echo
echo "Creating startup script..."
echo

# set up an init.d script
cat <<\EOF > /etc/init.d/resize2fs_once &&
#!/bin/sh
### BEGIN INIT INFO
# Provides:          resize2fs_once
# Required-Start:
# Required-Stop:
# Default-Start: 2 3 4 5
# Default-Stop: 0 1 6
# Short-Description: Resize the root filesystem to fill partition
# Description:
### END INIT INFO

. /lib/lsb/init-functions

case "$1" in
  start)
    log_daemon_msg "Starting resize2fs_once" &&
    resize2fs /dev/mmcblk0p2 &&
    rm /etc/init.d/resize2fs_once &&
    update-rc.d resize2fs_once remove &&
    log_end_msg $?
    ;;
  *)
    echo "Usage: $0 start" >&2
    exit 3
    ;;
esac
EOF
  
  chmod +x /etc/init.d/resize2fs_once &&
  update-rc.d resize2fs_once defaults &&

echo
echo "Rebooting the system..."
echo

  reboot

exit 0
