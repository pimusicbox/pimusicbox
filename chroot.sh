IMG_FILE=$1
RUN_SCRIPT=$2
SRC_FILES=$(cd $(dirname $0) ; pwd -P)
ROOTFS_DIR=${ROOTFS_DIR:-rootfs}
CHROOT_CMD=/bin/bash


if [ "$RUN_SCRIPT" != "" ]; then
    if [ ! -f "$SRC_FILES/$RUN_SCRIPT" ]; then
        echo "** ERROR: Can't find script file '$SRC_FILES/$RUN_SCRIPT' **"
        exit 1
    fi
    CHROOT_CMD+=" -c ./tmp/${RUN_SCRIPT}"
fi
if [ ! -f "$IMG_FILE" ]; then
    echo "** ERROR: No musicbox image found **"
    exit 1
fi
sudo echo "Info: Checking have root access to mount the disk images."

echo "Mounting $IMG_FILE and preparing arm chroot..."
LOOP_DEV=$(sudo losetup -fP --show $IMG_FILE)
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
if [ -n "$APT_PROXY" ]; then
    echo "Acquire::http { Proxy \"http://$APT_PROXY\"; };" | \
        sudo tee ${ROOTFS_DIR}/etc/apt/apt.conf.d/01proxy
fi

echo "Executing 'chroot ${ROOTFS_DIR} ${CHROOT_CMD}'"
sudo chroot ${ROOTFS_DIR} ${CHROOT_CMD}

echo "Cleaning up chroot and unmounting..."
sudo mv ${ROOTFS_DIR}/etc/ld.so.preload.bak ${ROOTFS_DIR}/etc/ld.so.preload
sudo rm ${ROOTFS_DIR}/usr/bin/qemu-arm-static
sudo rm -f ${ROOTFS_DIR}/etc/apt/apt.conf.d/01proxy

CHROOT_MOUNTS=$(mount | grep "${ROOTFS_DIR}" | cut -f 3 -d ' ' | sort -r)
for m in $CHROOT_MOUNTS
do
    echo "Unmounting $m"
    sudo umount $m
done
sudo losetup -D $IMG_FILE
