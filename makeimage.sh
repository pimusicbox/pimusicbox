#!/bin/bash
if [ $(id -u) != "0" ]; then
    echo "You must be the superuser to run this script" >&2
    exit 1
fi

DRIVE='/dev/sdc'
PART1=$DRIVE'1'
PART2=$DRIVE'2'

echo "Version:"
read IMGVERSION

echo "Zero root (y/N)?"
read ZEROROOT

echo "Resize size(MB or no)?"
read RESIZEFS

if [ "$RESIZEFS" != "" ]
then
    umount $PART1
    umount $PART2
    echo "Check..."
    e2fsck -fy $PART2
    echo "Resize to $RESIZEFS..."
    TMP = "M"
    resize2fs $PART2 $RESIZEFS$TMP
    echo "Ready"

  # Get the starting offset of the root partition
  PART_START=$(parted $DRIVE -ms unit s p | grep "^2" | cut -f 2 -d: | tr -cd "[:digit:]")
  [ "$PART_START" ] || exit 1
  # Return value will likely be error for fdisk as it fails to reload the 
  # partition table because the root fs is mounted
  fdisk $DRIVE <<EOF
p
d
2
n
p
2
$PART_START
+910M
p
w
EOF

#wait
    echo "Ok?"
    read TMPINPUT
fi

MNT='/mnt/tmp'$IMGVERSION
MNT2='/mnt/tmp'$IMGVERSION'2'

cd /data/pi

mkdir $MNT
mkdir $MNT2
mount $PART1 $MNT
cp -r $MNT/config /tmp
rm -r $MNT/config
cp -r /data/pi/config $MNT
rm -r $MNT/config/.*

#apple
rm -r $MNT/.Trashes
rm -r $MNT/.fseventsd
rm -r $MNT/.Spotlight-V100
rm -r $MNT/._.Trashes
rm -r $MNT/*.DS_Store
rm -r $MNT/config/.Trashes
rm -r $MNT/config/.fseventsd
rm -r $MNT/config/.Spotlight-V100
rm -r $MNT/config/._.Trashes
rm -r $MNT/config/*.DS_Store

echo "Zero FAT"
dd if=/dev/zero of=$MNT/zero bs=1M
rm $MNT/zero

mount $PART2 $MNT2
#remove network settings
rm $MNT2/var/lib/dhcp/*.leases
rm $MNT2/etc/udev/rules.d/*.rules
#logs
rm -r $MNT2/var/log/*
rm -r $MNT2/var/log/apt/*
#remove spotify/audio settings
rm -r $MNT2/root/.cache/mopidy/*
rm -r $MNT2/root/.gstreamer-0.10
rm -r $MNT2/tmp/*

#put version in login prompt
echo -e 'MusicBox '$IMGVERSION"\n" > $MNT2/etc/issue

#music
rm -r $MNT2/music/local/*

#security
rm $MNT2/root/.bash_history
#rm -r $MNT2/root/.ssh

#old stuff
rm -r $MNT2/boot.bk
rm -r $MNT2/lib/modules.bk

if [ "$ZEROROOT" = "Y" -o "$ZEROROOT" = "y" ]; then
    echo "Zero Root FS"
    dd if=/dev/zero of=$MNT2/zero bs=1M
    rm $MNT2/zero
fi

echo "wait 10 sec for mount"
sleep 10

umount $MNT
umount $MNT2
rmdir $MNT2

if [ "$RESIZEFS" == "" ]
then
#if [ "$RESIZEFS" != "Y" -a "$RESIZEFS" != "y" ]; then
    echo "DD 950 * 1M"
    dd bs=1M if=$DRIVE of=musicbox$IMGVERSION.img count=950
else
    echo "DD $RESIZEFS * 1M"
    dd bs=1M if=$DRIVE of=musicbox$IMGVERSION.img count=$RESIZEFS
fi

echo "Copy Config back"
mount $PART1 $MNT
cp -r /tmp/config $MNT
rm -r /tmp/config

echo "wait 10 sec for umount"
sleep 10
umount $MNT
rmdir $MNT

#echo "cut image"
#dd if=/dev/zero of=musicbox$IMGVERSION.img bs=1 count=0 seek=2G

echo "zip image"
zip -9 musicbox$IMGVERSION.zip musicbox$IMGVERSION.img

echo "copy zip"
cp musicbox$IMGVERSION.zip /www/wouter/pimusicbox

#echo "Enter your Spotify Premium username: "
#read spotify_username
#echo "Enter your Spotify Premium password: "
#stty -echo
#read spotify_password ; echo
#stty echo

#sudo echo "SPOTIFY_USERNAME = '$spotify_username'" >> /root/.config/mopidy/settings.py
#sudo echo "SPOTIFY_PASSWORD = '$spotify_password'" >> /root/.config/mopidy/settings.py

