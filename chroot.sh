RUN_SCRIPT=$1
MY_PATH=$(cd $(dirname $0) ; pwd -P)
SRC_FILES=${2:-$MY_PATH}
MUSICBOX_IMG=$(ls musicbox*.img)
RASPBIAN_IMG=$(ls *-raspbian-jessie-lite.img)
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

# Mount the Musicbox image
LOOP_DEV=$(sudo losetup -fP --show $MUSICBOX_IMG)
mkdir -p ${ROOTFS_DIR}
sudo mount ${LOOP_DEV}p2 ${ROOTFS_DIR}
sudo mount ${LOOP_DEV}p1 ${ROOTFS_DIR}/boot

if [ -f "$RASPBIAN_IMG" ]; then
    # Mount Raspbian image boot directory only
    LOOP_DEV2=$(sudo losetup -fP --show $RASPBIAN_IMG)
    sudo mount ${LOOP_DEV2}p1 ${ROOTFS_DIR}/tmp

    echo "Copying boot files from $RASPBIAN_IMG"
    sudo cp ${ROOTFS_DIR}/tmp/{bootcode.bin,*.elf} ${ROOTFS_DIR}/boot/

    # Unmount Raspbian image
    sudo umount ${ROOTFS_DIR}/tmp
    sudo losetup -D $RASPBIAN_IMG
fi

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

echo "Doing 'chroot ${ROOTFS_DIR} ${CHROOT_CMD}'"
sudo chroot ${ROOTFS_DIR} ${CHROOT_CMD}

sudo mv ${ROOTFS_DIR}/etc/ld.so.preload.bak ${ROOTFS_DIR}/etc/ld.so.preload
sudo rm ${ROOTFS_DIR}/usr/bin/qemu-arm-static

# Unmount everything
CHROOT_MOUNTS=$(mount | grep "${ROOTFS_DIR}" | cut -f 3 -d ' ' | sort -r)
for m in $CHROOT_MOUNTS
do
    echo "Unmounting $m"
    sudo umount $m
done
sudo losetup -D $MUSICBOX_IMG
