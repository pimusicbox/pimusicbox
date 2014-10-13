#!/bin/bash
if [ $(id -u) != "0" ]; then
    echo "You must be the superuser to run this script" >&2
    exit 1
fi

#set initial vars
TMPDIR='/tmp/mb'
mkdir $TMPDIR

#device of SD-card
DRIVE='/dev/sdb'

#set partitions variables
PART1=$DRIVE'1'
PART2=$DRIVE'2'

#zero out root partition yes or no (this can take a while
ZEROROOT='y'

#directory to copy the resulting zip to
DESTINATIONDIR='/media/sf_Downloads'

# size 875 (900?), count 975 works...
COUNT=975

umount $PART1
umount $PART2

#ask for version. E.g. 0.5.1alpha2
echo "Version:"
read IMGVERSION

#unmount again, sometimes first time did not work
umount $PART1
umount $PART2

#set vars
ZIPNAME='musicbox'$IMGVERSION'.zip'
IMGNAME='musicbox'$IMGVERSION'.img'

#clean up old stuff
rm $ZIPNAME
rm $IMGNAME
rm $DESTINATIONDIR'/'$ZIPNAME
rm $DESTINATIONDIR'/'$IMGNAME

#check filesystem and repair if broken
fsck -p $PART1
fsck -p $PART2

#echo "Zero root (y/N)?"
#read ZEROROOT

#echo "Resize size to 960 MB(y/N)?"
#read RESIZEFS

#autoresize (not used much)
if [ "$RESIZEFS" == "y" ]
then
    echo "Check..."
    e2fsck -fy $PART2
    echo "Resize to 875MB..."
    resize2fs $PART2 875M
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
+960M
p
w
EOF

#wait
    echo "Ok?"
    read TMPINPUT
fi

MNT=$TMPDIR'/'$IMGVERSION
MNT2=$TMPDIR'/'$IMGVERSION'2'

# mount partitions on $TMPDIR
mkdir $MNT
mkdir $MNT2
mount $PART1 $MNT

#start copying/removing stuff

#backup and delete configuration files on FAT partition (when musicbox is started in /boot/config)
cp -r $MNT/config $TMPDIR
rm -r $MNT/config

# copy clean config to FAT partition
cp -r config $MNT
rm -r $MNT/config/.*

#remove (apple) hidden stuff
rm -r $MNT/.*
rm -r $MNT/config/.*

#clean up the free space of FAT for better compression
echo "Zero FAT"
dd if=/dev/zero of=$MNT/zero bs=1M
rm $MNT/zero

#now do the same cleaning for the root partition
mount $PART2 $MNT2

#copy a backup or root to temp
cp -r $MNT2/root $TMPDIR

#remove network settings, etc
rm $MNT2/var/lib/dhcp/*.leases
touch $MNT2/var/lib/dhcp/dhcpd.leases
rm $MNT2/var/lib/alsa/*
rm $MNT2/var/lib/dbus/*
rm $MNT2/var/lib/avahi-autoipd/*
rm $MNT2/etc/udev/rules.d/*.rules

#logs
rm $MNT2/var/log/*
rm $MNT2/var/log/apt/*
echo "" > $MNT2/var/log/mopidy/mopidy.log

#remove spotify/audio settings
rm -r $MNT2/var/lib/mopidy/*
rm -r $MNT2/home/mopidy/.config/mopidy/spotify
rm -r $MNT2/home/mopidy/.cache/*
rm -r $MNT2/home/mopidy/.local/*
rm -r $MNT2/var/lib/mopidy/.local/share/mopidy/local/*
rm $MNT2/etc/wicd/wireless-settings.conf
rm -r $MNT2/var/lib/wicd/configurations/*
rm -r $MNT2/var/lib/mopidy/*
rm -r $MNT2/var/cache/mopidy/*

#clear caches etc
rm $MNT2/var/cache/apt/archives/*
rm $MNT2/var/cache/apt/archives/partial/*
rm -r $MNT2/var/cache/man/*
rm -r $MNT2/var/backups/*.gz
rm -r $MNT2/var/lib/aptitude/*
rm -r $MNT2/tmp/*
rm -r $MNT2/var/tmp/*

#remove dropbear keys
cp $MNT2/etc/dropbear/dropbear_rsa_host_key $TMPDIR
cp $MNT2/etc/dropbear/dropbear_dss_host_key $TMPDIR
rm $MNT2/etc/dropbear/dropbear_rsa_host_key
rm $MNT2/etc/dropbear/dropbear_dss_host_key

#put version in login prompt
echo -e 'MusicBox '$IMGVERSION"\n" > $MNT2/etc/issue

#remove music files
rm -r $MNT2/music/MusicBox/*

#bash history
rm $MNT2/root/.bash_history
rm $MNT2/root/.ssh/id_*

#config
rm -r $MNT2/home/mopidy/*

#root
rm -r $MNT2/root/*

#old stuff from rpi-update
rm -r $MNT2/boot.bk
rm -r $MNT2/lib/modules.bk

#clean up the free space of root partition for better compression
if [ "$ZEROROOT" = "Y" -o "$ZEROROOT" = "y" ]; then
    echo "Zero Root FS"
    dd if=/dev/zero of=$MNT2/zero bs=1M
    rm $MNT2/zero
fi

sync

#wait for everything to settle
echo "wait 15 sec for mount"
sleep 15

umount $MNT
umount $MNT2

#wait for everything to settle
echo "wait 15 sec for mount"
sleep 15

#unmount again, if first time did not work (it sometimes does)
umount $MNT
umount $MNT2

#echo "wait 15 sec for mount again"
#sleep 15

#echo "Ok?"
#read TST

#unmount again, if first time did not work (it sometimes does)
#umount $MNT
#umount $MNT2

# copy disk using dd, sector-wise
# $COUNT is the number of blocks to copy. It should fit on most 1G cards
# a user reported an SD size of 988286976, which would be 942 blocks of 1M
# $COUNT is larger, sorry
echo "DD $COUNT * 1M"
dd bs=1M if=$DRIVE count=$COUNT | pv -s "$COUNT"m | dd of=musicbox$IMGVERSION.img

#restore old values from image
echo "Copy Config back"
mount $PART1 $MNT
mount $PART2 $MNT2
cp -r $TMPDIR/config $MNT
rm -r $TMPDIR/config

#restore root
cp -r $TMPDIR/root $MNT2
rm -r $TMPDIR/root
chown -R root:root $MNT2/root

#restore dropbear keys
mv $TMPDIR/dropbear_rsa_host_key $MNT2/etc/dropbear
mv $TMPDIR/dropbear_dss_host_key $MNT2/etc/dropbear

#sync files
sync

#wait
echo "wait 15 sec for umount"
sleep 15

#clean up
umount $MNT
umount $MNT2

#copy the new image file to virtualbox shared folder
#echo "copy image"
#cp $IMGNAME $DESTINATIONDIR

#zip the image
echo "zip image"
zip -9 $ZIPNAME $IMGNAME MusicBox_Manual_0.4.pdf

#copy the zip to the virtualbox shared folder
echo "copy zip"
cp $ZIPNAME $DESTINATIONDIR

#remove dd image (a zip is there already)
rm $IMGNAME

sync

#cleanup mounts
umount $MNT
umount $MNT2
rmdir $MNT2
rmdir $MNT

rmdir $TMPDIR
