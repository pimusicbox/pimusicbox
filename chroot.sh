RUN_SCRIPT=$1
MY_PATH=$(cd $(dirname $0) ; pwd -P)
SRC_FILES=${2:-$MY_PATH}
MUSICBOX_IMG=$(ls musicbox*.img)
ROOTFS_DIR=${ROOTFS_DIR:-rootfs}
CHROOT_CMD=/bin/bash

if [ "$RUN_SCRIPT" != "" ]; then
    if [ ! -f "$SRC_FILES/$RUN_SCRIPT" ]; then
        echo "ERROR: Can't find script file '$SRC_FILES/$RUN_SCRIPT'"
        exit 1
    fi
    CHROOT_CMD+=" -c ./tmp/${RUN_SCRIPT}"
fi
if [ ! -f "$MUSICBOX_IMG" ]; then
    echo "ERROR: No musicbox disk image found"
    exit 1
fi

sudo echo "Info: Checking have root access to mount the disk images."

IMG_SIZE=$(ls -l $MUSICBOX_IMG | cut -d" " -f5)
if [ $IMG_SIZE -lt 1500000000  ]; then
    echo "Enlarging image..."
    truncate --size +1G $MUSICBOX_IMG
    LOOP_DEV=$(sudo losetup -f --show $MUSICBOX_IMG)
    OFFSET=$(sudo fdisk -l $MUSICBOX_IMG  | grep Linux | awk -F" "  '{ print $2 }')
    cat <<EOF | sudo fdisk $LOOP_DEV
d
2
n
p
2
$OFFSET

w
EOF

    sudo losetup -D $LOOP_DEV
    LOOP_DEV=$(sudo losetup -f -o $(($OFFSET*512)) --show $MUSICBOX_IMG)
    sudo e2fsck -f ${LOOP_DEV}
    sudo resize2fs ${LOOP_DEV}
    sudo losetup -D $LOOP_DEV
fi

echo "Mounting $MUSICBOX_IMG and preparing arm chroot..."
LOOP_DEV=$(sudo losetup -fP --show $MUSICBOX_IMG)
mkdir -p ${ROOTFS_DIR}
sudo mount ${LOOP_DEV}p2 ${ROOTFS_DIR}
sudo mount ${LOOP_DEV}p1 ${ROOTFS_DIR}/boot

CHROOT_MOUNTS="dev proc sys dev/pts"
for x in $CHROOT_MOUNTS
    do sudo mount --bind /$x ${ROOTFS_DIR}/$x/
done
if [ -d "$SRC_FILES" ]; then
    sudo mount --bind $SRC_FILES $ROOTFS_DIR/tmp
fi
# Disable preloaded shared library to get everything including networking to work on x86
sudo mv ${ROOTFS_DIR}/etc/ld.so.preload ${ROOTFS_DIR}/etc/ld.so.preload.bak
sudo cp `which qemu-arm-static` ${ROOTFS_DIR}/usr/bin/

echo "Executing 'chroot ${ROOTFS_DIR} ${CHROOT_CMD}'"
sudo chroot ${ROOTFS_DIR} ${CHROOT_CMD}

echo "Cleaning up chroot and unmounting..."
sudo mv ${ROOTFS_DIR}/etc/ld.so.preload.bak ${ROOTFS_DIR}/etc/ld.so.preload
sudo rm ${ROOTFS_DIR}/usr/bin/qemu-arm-static

CHROOT_MOUNTS=$(mount | grep "${ROOTFS_DIR}" | cut -f 3 -d ' ' | sort -r)
for m in $CHROOT_MOUNTS
do
    echo "Unmounting $m"
    sudo umount $m
done
sudo losetup -D $MUSICBOX_IMG
