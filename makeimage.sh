#!/bin/bash
set -e

SECTOR_SIZE=512


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
        echo "** ERROR: No image file found **"
        return
    fi
    if [ IMG_SIZE -lt $NEW_SIZE_SAFE ]; then
        echo "** ERROR: Requested new size ($NEW_SIZE_SAFE) is larger than current size ($IMG_SIZE) **"
        return
    fi
    sudo echo "Shrinking $IMG_FILE from $IMG_SIZE to $NEW_SIZE_SAFE bytes..."
    #ROOT_SIZE=`used` + 100M breathing space
    local LOOP_DEV=$(sudo losetup -fP --show $IMG_FILE)
    local ROOT_PART=${LOOP_DEV}p2
    sudo e2fsck -f ${LOOP_DEV}p2
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

    echo "** Success **"
}


release() {
    local INPUT_IMG=$1
    local SRC_FILES=$(cd $(dirname $0) ; pwd -P)

    local SRC_VERSION_LONG=$(cd $SRC_FILES && git describe)
    local SRC_VERSION_SHORT=$(cd $SRC_FILES && git describe --abbrev=0)
    local VERSION=${VERSION:-${SRC_VERSION_SHORT}}
    local ZIP_NAME=musicbox_${VERSION}.zip
    local IMG_NAME=musicbox_${VERSION}.img

    local BUILD_DIR=${MKIMG_BUILD_DIR:-${SRC_FILES}/_build}
    local ROOTFS_DIR=${MKIMG_ROOTFS_DIR:-${BUILD_DIR}/rootfs}
    local KERNEL=4.4.50

    if [ ! -f "$INPUT_IMG" ]; then
        echo "** ERROR: No musicbox image found **"
        exit 1
    fi
    sudo echo "Info: Checking have permission to mount the disk images."

    echo "Info: Creating $ZIP_NAME release in $BUILD_DIR from $INPUT_IMG..."

    rm -rf ${BUILD_DIR}
    mkdir -p ${BUILD_DIR}
    cp $INPUT_IMG ${BUILD_DIR}/${IMG_NAME}
    cd ${BUILD_DIR}

    local OFFSET=$(fdisk -l $IMG_NAME  | grep Linux | awk -F" "  '{ print $2 }')
    local LOOP_DEV=$(sudo losetup -fP --show $IMG_NAME)
    local ROOT_PART=${LOOP_DEV}p2
    mkdir -p ${ROOTFS_DIR}
    sudo mount ${ROOT_PART} ${ROOTFS_DIR}

    echo "Musicbox ${SRC_VERSION_LONG}" | sudo tee ${ROOTFS_DIR}/etc/issue
    sudo rm -rf ${ROOTFS_DIR}/var/lib/apt/lists/*
    sudo rm -rf ${ROOTFS_DIR}/var/cache/apt/*
    sudo rm -rf ${ROOTFS_DIR}/var/lib/apt/*
    sudo rm -rf ${ROOTFS_DIR}/etc/dropbear/*key
    sudo rm -rf ${ROOTFS_DIR}/tmp/*
    # Remove old kernel modules.
    sudo find ${ROOTFS_DIR}/lib/modules -maxdepth 1 -mindepth 1 -type d \! -name ${KERNEL}* | sudo xargs rm -rf
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
    sudo losetup -D $IMG_NAME

    ###
    # TODO: Shrink image to fit on smaller SD cards? Who still uses 1G SD cards?!
    ###
    #smaller $IMG_NAME $(expr 1024 \* 1024 \* 1024)

    rm -rf $ROOTFS_DIR
    cd $SRC_FILES/docs
    make text latexpdf
    cp _build/text/{changes,faq}.txt  $BUILD_DIR/
    cp _build/latex/PiMusicBox.pdf  $BUILD_DIR/
    cd $BUILD_DIR
    md5sum * > MD5SUMS
    zip -9 $ZIP_NAME *

    echo "** Success **"
}


if [ "${BASH_SOURCE[0]}" == "${0}" ]; then
    # Not sourced
    case "$1" in
        bigger)
            bigger "${@:2}"
            ;;
        smaller)
            echo TODO smaller "${@:2}"
            ;;
        release)
            release "${@:2}"
            ;;
        *)
            echo "Usage: $0 bigger|smaller|release <args>"
            ;;
    esac
fi
