#!/bin/bash

SECTOR_SIZE=512

SRC_FILES=$(cd $(dirname $0) ; pwd -P)

SRC_VERSION=$(cd $SRC_FILES && git describe)
TIMESTAMP=$(date)
VERSION=${VERSION:-${SRC_VERSION}}
ZIP_NAME=musicbox_${VERSION}.zip
IMG_NAME=musicbox_${VERSION}.img

BUILD_DIR=${MKIMG_BUILD_DIR:-musicbox_build}
ROOTFS_DIR=${MKIMG_ROOTFS_DIR:-${BUILD_DIR}/rootfs}
OUTPUT_IMG=${BUILD_DIR}/${IMG_NAME}

bigger() {
    local IMG_FILE=$1
    local NEW_SIZE=${2:-2200000000}
    local NEW_SIZE_SAFE=$(echo "$NEW_SIZE / $SECTOR_SIZE * $SECTOR_SIZE" | bc)
    local IMG_SIZE=$(ls -l $IMG_FILE | cut -d' ' -f5)
    if [ ! -f "$IMG_FILE" ]; then
        echo "** ERROR: No image file found **"
        return
    fi
    if [ $NEW_SIZE_SAFE -lt $IMG_SIZE ]; then
        echo "** ERROR: Requested new size ($NEW_SIZE_SAFE) is smaller than current size ($IMG_SIZE) **"
        return
    fi
    local OLD_SIZE=$(ls -lh $IMG_FILE | cut -d' ' -f5)
    sudo echo "INFO: Enlarging $IMG_FILE..."
    truncate --size $NEW_SIZE_SAFE $IMG_FILE
    local OFFSET=$(fdisk -l $IMG_FILE  | grep Linux | awk -F' '  '{print $2}')
    local LOOP_DEV=$(sudo losetup -fP --show $IMG_FILE)
    cat <<EOF | sudo fdisk $LOOP_DEV
d
2
n
p
2
$OFFSET

w
EOF

    sync
    sleep 1
    sudo partprobe $LOOP_DEV

    sudo e2fsck -yf ${LOOP_DEV}p2
    sudo resize2fs ${LOOP_DEV}p2
    sudo losetup -D $LOOP_DEV

    local NEW_SIZE=$(ls -lh $IMG_FILE | cut -d' ' -f5)
    echo "INFO: Increased $IMG_FILE from $OLD_SIZE to $NEW_SIZE"
    return 0
}


smaller() {
    local IMG_FILE=$1
    local OLD_SIZE=$(ls -lh $IMG_FILE | cut -d' ' -f5)

    if [ ! -f "$IMG_FILE" ]; then
        echo "** FATAL: No image file found **"
        exit 1
    fi
    sudo echo "INFO: Shrinking $IMG_FILE..."
    local LOOP_DEV=$(sudo losetup -fP --show $IMG_FILE)
    local PART_NUM=2
    local ROOT_PART=${LOOP_DEV}p${PART_NUM}
    sudo e2fsck -fy $ROOT_PART

    local BLOCK_SIZE=$(sudo tune2fs -l $ROOT_PART | grep 'Block size' | awk '{print $3}')
    local MIN_BLOCKS=$(sudo resize2fs -P $ROOT_PART | awk -F': '  '{print $2}')
    # 20MB of extra free space
    local EXTRA_BLOCKS=$(echo "1024 * 1024 * 20 / $BLOCK_SIZE" | bc)
    local SIZE_BLOCKS=$(echo "$MIN_BLOCKS + $EXTRA_BLOCKS" | bc)
    sudo resize2fs $ROOT_PART $SIZE_BLOCKS
    sync && sleep 1
    sudo losetup -D $LOOP_DEV

    local SIZE_BYTES=$(echo "$SIZE_BLOCKS * $BLOCK_SIZE" | bc)
    local FIRST_BYTE=$(sudo parted -m $IMG_FILE unit B print | tail -1 | cut -d':' -f2 | tr -d 'B')
    local LAST_BYTE=$(echo "$FIRST_BYTE + $SIZE_BYTES" | bc)

    sudo parted $IMG_FILE rm $PART_NUM
    sudo parted $IMG_FILE unit B mkpart primary $FIRST_BYTE $LAST_BYTE
    local FINAL_SIZE=$(sudo parted -m $IMG_FILE unit B print free | tail -1 | cut -d':' -f2 | tr -d 'B')
    truncate --size $FINAL_SIZE $IMG_FILE
    sync && sleep 1

    local NEW_SIZE=$(ls -lh $IMG_FILE | cut -d' ' -f5)
    echo "INFO: Reduced $IMG_FILE from $OLD_SIZE to $NEW_SIZE"
    return 0
}


finalise() {
    local INPUT_IMG=$1

    if [ -f "$OUTPUT_IMG" ]; then
        echo "INFO: Existing image found at $OUTPUT_IMG. Nothing to do."
        return
    fi

    if [ ! -f "$INPUT_IMG" ]; then
        echo "** FATAL: No image found at $INPUT_IMG **"
        exit 1
    fi
    sudo echo "INFO: Checking permission to mount the disk images."

    echo "INFO: Creating $OUTPUT_IMG from $INPUT_IMG..."

    rm -rf ${BUILD_DIR}
    mkdir -p ${BUILD_DIR}
    cp $INPUT_IMG $OUTPUT_IMG

    if [ ! -f "$OUTPUT_IMG" ]; then
        echo "** FATAL: Could not create output image $OUTPUT_IMG **"
        exit 1
    fi

    local LOOP_DEV=$(sudo losetup -fP --show $OUTPUT_IMG)
    local ROOT_PART=${LOOP_DEV}p2
    mkdir -p ${ROOTFS_DIR}
    sudo mount ${ROOT_PART} ${ROOTFS_DIR}

    echo "Musicbox ${SRC_VERSION} built on ${TIMESTAMP}" | sudo tee ${ROOTFS_DIR}/etc/issue

    echo "INFO: Removing unnecessary files..."
    sudo rm -rf ${ROOTFS_DIR}/var/lib/apt/lists/*
    sudo rm -rf ${ROOTFS_DIR}/var/cache/apt/*
    sudo rm -rf ${ROOTFS_DIR}/var/lib/apt/*
    sudo rm -rf ${ROOTFS_DIR}/etc/dropbear/*key
    sudo rm -rf ${ROOTFS_DIR}/tmp/*
    sudo rm -rf ${ROOTFS_DIR}/usr/share/man/*
    sudo rm -rf ${ROOTFS_DIR}/usr/share/doc
    sudo rm -rf ${ROOTFS_DIR}/boot.bak
    sudo find ${ROOTFS_DIR}/var/log -type f | sudo xargs rm -f
    local OTHER_HOMES=$(sudo ls ${ROOTFS_DIR}/home/ | grep -v mopidy)
    sudo rm -rf ${ROOTFS_DIR}/home/${OTHER_HOMES}
    sudo find ${ROOTFS_DIR}/home/ -type f -name "*.log" | xargs rm -f
    sudo find ${ROOTFS_DIR}/home/ -type f -name "*_history" | xargs rm -f

    sync && sleep 1

    sudo umount $ROOTFS_DIR
    sudo e2fsck -fy $ROOT_PART
    sudo zerofree -v $ROOT_PART
    sudo losetup -D $OUTPUT_IMG
    sleep 1
    rm -rf $ROOTFS_DIR

    smaller $OUTPUT_IMG
    echo "** Success **"
    return 0
}


release() {
    pushd $SRC_FILES/docs
    make text latexpdf > /dev/null
    popd
    cp $SRC_FILES/docs/_build/text/{changes,faq}.txt  $BUILD_DIR/
    cp $SRC_FILES/docs/_build/latex/PiMusicBox.pdf  $BUILD_DIR/
    pushd $BUILD_DIR
    md5sum -- * > MD5SUMS
    zip -9 $ZIP_NAME -- *

    ZIP_SIZE=$(ls -lh $ZIP_NAME | cut -d' ' -f5)
    echo "INFO: Release $ZIP_NAME size is $ZIP_SIZE"
    echo "** Success **"
    return 0
}

if [ "${BASH_SOURCE[0]}" == "${0}" ]; then
    # Not sourced
    case "$2" in
        bigger)
            bigger "$1"
            ;;
        smaller)
            smaller "$1"
            ;;
        finalise)
            finalise "$1"
            ;;
        release)
            finalise "$1"
            release "$1"
            ;;
        *)
            echo "Usage: $0 <image> bigger|smaller|finalise|release <args>"
            ;;
    esac
fi
