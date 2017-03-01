IMG_FILE=$1
RUN_SCRIPT=$2
IMG_MIN_SIZE=${IMG_MIN_SIZE:-1900000000}
SRC_FILES=$(cd $(dirname $0) ; pwd -P)
ROOTFS_DIR=${ROOTFS_DIR:-rootfs}
CHROOT_CMD=/bin/bash
SECTOR_SIZE=512

if [ "$RUN_SCRIPT" != "" ]; then
    if [ ! -f "$SRC_FILES/$RUN_SCRIPT" ]; then
        echo "ERROR: Can't find script file '$SRC_FILES/$RUN_SCRIPT'"
        exit 1
    fi
    CHROOT_CMD+=" -c ./tmp/${RUN_SCRIPT}"
fi
if [ ! -f "$IMG_FILE" ]; then
    echo "ERROR: No musicbox image found"
    exit 1
fi
sudo echo "Info: Checking have root access to mount the disk images."

# Ensure image has enough space.
IMG_SIZE=$(ls -l $IMG_FILE | cut -d" " -f5)
IMG_MIN_SIZE=$(expr $IMG_MIN_SIZE / $SECTOR_SIZE \* $SECTOR_SIZE)
if [ $IMG_SIZE -lt $IMG_MIN_SIZE ]; then
    SIZE_INCR=$(expr $IMG_MIN_SIZE - $IMG_SIZE)
    echo "Enlarging image by $SIZE_INCR bytes..."
    truncate --size +${SIZE_INCR} $IMG_FILE
    OFFSET=$(sudo fdisk -l $IMG_FILE  | grep Linux | awk -F" "  '{ print $2 }')
    LOOP_DEV=$(sudo losetup -fP --show $IMG_FILE)
    cat <<EOF | sudo fdisk $LOOP_DEV
d
2
n
p
2
$OFFSET

w
EOF

    sudo e2fsck -f ${LOOP_DEV}p2
    sudo resize2fs ${LOOP_DEV}p2
    sudo losetup -D $LOOP_DEV
fi

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
sudo losetup -D $IMG_FILE
