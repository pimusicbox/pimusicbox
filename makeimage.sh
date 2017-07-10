#!/bin/bash

SECTOR_SIZE=512

SRC_FILES=$(cd $(dirname $0) ; pwd -P)

SRC_VERSION_LONG=$(cd $SRC_FILES && git describe)
SRC_VERSION_SHORT=$(cd $SRC_FILES && git describe --abbrev=0)
VERSION=${VERSION:-${SRC_VERSION_SHORT}}
ZIP_NAME=musicbox_${VERSION}.zip
IMG_NAME=musicbox_${VERSION}.img

BUILD_DIR=${MKIMG_BUILD_DIR:-musicbox_build}
ROOTFS_DIR=${MKIMG_ROOTFS_DIR:-${BUILD_DIR}/rootfs}
OUTPUT_IMG=${BUILD_DIR}/${IMG_NAME}

bigger() {
    local IMG_FILE=$1
    local NEW_SIZE=${2:-2200000000}
    local NEW_SIZE_SAFE=$(expr $NEW_SIZE / $SECTOR_SIZE \* $SECTOR_SIZE)
    local IMG_SIZE=$(ls -l $IMG_FILE | cut -d" " -f5)
    if [ ! -f "$IMG_FILE" ]; then
        echo "** ERROR: No image file found **"
        return
    fi
    if [ $NEW_SIZE_SAFE -lt $IMG_SIZE ]; then
        echo "** ERROR: Requested new size ($NEW_SIZE_SAFE) is smaller than current size ($IMG_SIZE) **"
        return
    fi
    sudo echo "Enlarging $IMG_FILE from $IMG_SIZE to $NEW_SIZE_SAFE bytes..."
    truncate --size $NEW_SIZE_SAFE $IMG_FILE
    local OFFSET=$(fdisk -l $IMG_FILE  | grep Linux | awk -F" "  '{ print $2 }')
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

    sudo e2fsck -f ${LOOP_DEV}p2
    sudo resize2fs ${LOOP_DEV}p2
    sudo losetup -D $LOOP_DEV

    echo "** Success **"
}


smaller() {
    local IMG_FILE=$1
    local NEW_SIZE=${2:-0}
    local NEW_SIZE_SAFE=$(expr $NEW_SIZE / $SECTOR_SIZE \* $SECTOR_SIZE)
    local IMG_SIZE=$(ls -l $IMG_FILE | cut -d" " -f5)
    if [ ! -f "$IMG_FILE" ]; then
        echo "** FATAL: No image file found **"
        exit 1
    fi
    if [ $IMG_SIZE -lt $NEW_SIZE_SAFE ]; then
        echo "ERROR: Specifed size ($NEW_SIZE_SAFE) is larger than current size ($IMG_SIZE)"
        return 1
    fi
    sudo echo "INFO: Reducing $IMG_FILE from $IMG_SIZE to $NEW_SIZE_SAFE bytes..."
    #ROOT_SIZE=`used` + 100M breathing space
    local LOOP_DEV=$(sudo losetup -fP --show $IMG_FILE)
    local ROOT_PART=${LOOP_DEV}p2
    sudo e2fsck -f ${ROOT_PART}
    sudo resize2fs ${ROOT_PART} $NEW_SIZE_SAFE
    cat <<EOF | sudo fdisk ${LOOP_DEV}
d
2
n
p
2
$OFFSET

w
EOF

    sync && sleep 1

    sudo losetup -D $LOOP_DEV
    # TODO fix this, needs to include /boot size etc
    #truncate --size $NEW_SIZE_SAFE $IMG_FILE

    IMG_SIZE=$(ls -l $IMG_FILE | cut -d" " -f5)
    IMG_SIZE=$(expr $IMG_SIZE \/ 1024 \/ 1024)
    echo "INFO: Reduced $IMG_FILE size is ${IMG_SIZE}MB"
    echo "** Success **"
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

    local OFFSET=$(fdisk -l $OUTPUT_IMG  | grep Linux | awk -F" "  '{ print $2 }')
    local LOOP_DEV=$(sudo losetup -fP --show $OUTPUT_IMG)
    local ROOT_PART=${LOOP_DEV}p2
    mkdir -p ${ROOTFS_DIR}
    sudo mount ${ROOT_PART} ${ROOTFS_DIR}

    echo "Musicbox ${SRC_VERSION_LONG}" | sudo tee ${ROOTFS_DIR}/etc/issue
    sudo rm -rf ${ROOTFS_DIR}/var/lib/apt/lists/*
    sudo rm -rf ${ROOTFS_DIR}/var/cache/apt/*
    sudo rm -rf ${ROOTFS_DIR}/var/lib/apt/*
    sudo rm -rf ${ROOTFS_DIR}/etc/dropbear/*key
    sudo rm -rf ${ROOTFS_DIR}/tmp/*
    sudo find ${ROOTFS_DIR}/var/log -type f | sudo xargs rm -f
    local OTHER_HOMES=$(sudo ls ${ROOTFS_DIR}/home/ | grep -v mopidy)
    sudo rm -rf ${ROOTFS_DIR}/home/${OTHER_HOMES}
    sudo find ${ROOTFS_DIR}/home/ -type f -name *.log | xargs rm -f
    sudo find ${ROOTFS_DIR}/home/ -type f -name *_history | xargs rm -f

    sync
    sleep 1

    sudo umount $ROOTFS_DIR
    sudo e2fsck -fy $ROOT_PART
    sudo zerofree -v $ROOT_PART
    sudo losetup -D $OUTPUT_IMG
    rm -rf $ROOTFS_DIR

    local IMG_SIZE=$(ls -l $OUTPUT_IMG | cut -d" " -f5)
    IMG_SIZE=$(expr $IMG_SIZE \/ 1024 \/ 1024)
    echo "INFO: Created $OUTPUT_IMG (size: ${IMG_SIZE}MB)"
    echo "** Success **"
    return 0
}


release() {
    finalise $1

    ###
    # TODO: Shrink image to fit on smaller SD cards? Who still uses 1G SD cards?!
    ###
    #smaller $OUTPUT_IMG $(expr 1024 \* 1024 \* 1024)

    pushd $SRC_FILES/docs
    make text latexpdf > /dev/null
    popd
    cp $SRC_FILES/docs/_build/text/{changes,faq}.txt  $BUILD_DIR/
    cp $SRC_FILES/docs/_build/latex/PiMusicBox.pdf  $BUILD_DIR/
    pushd $BUILD_DIR
    md5sum * > MD5SUMS
    zip -9 $ZIP_NAME *

    ZIP_SIZE=$(ls -l $ZIP_NAME | cut -d" " -f5)
    ZIP_SIZE=$(expr $ZIP_SIZE \/ 1024 \/ 1024)
    echo "INFO: Release $ZIP_NAME size is ${ZIP_SIZE}MB"
    echo "** Success **"
    return 0
}

if [ "${BASH_SOURCE[0]}" == "${0}" ]; then
    # Not sourced
    case "$2" in
        bigger)
            bigger "$@"
            ;;
        smaller)
            echo TODO smaller "$@"
            ;;
        finalise)
            finalise "$@"
            ;;
        release)
            release "$@"
            ;;
        *)
            echo "Usage: $0 <image> bigger|smaller|finalise|release <args>"
            ;;
    esac
fi
