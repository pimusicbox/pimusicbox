#!/bin/bash
set -e

INPUT_IMG=$1

SRC_FILES=$(cd $(dirname $0) ; pwd -P)

SRC_VERSION_LONG=$(cd $SRC_FILES && git describe)
SRC_VERSION_SHORT=$(cd $SRC_FILES && git describe --abbrev=0)
VERSION=${VERSION:-${SRC_VERSION_SHORT}}
ZIP_NAME=musicbox_${VERSION}.zip
IMG_NAME=musicbox_${VERSION}.img

BUILD_DIR=${BUILD_DIR:-${SRC_FILES}/_build}
ROOTFS_DIR=${ROOTFS_DIR:-${BUILD_DIR}/rootfs}

if [ ! -f "$INPUT_IMG" ]; then
    echo "ERROR: No musicbox image found"
    exit 1
fi
sudo echo "Info: Checking have permission to mount the disk images."

echo "Info: Creating $ZIP_NAME release from $INPUT_IMG..."

rm -rf ${BUILD_DIR}
mkdir -p ${BUILD_DIR}
cp $INPUT_IMG ${BUILD_DIR}/${IMG_NAME}
cd ${BUILD_DIR}

OFFSET=$(sudo fdisk -l $IMG_NAME  | grep Linux | awk -F" "  '{ print $2 }')
LOOP_DEV=$(sudo losetup -fP --show $IMG_NAME)
ROOT_PART=${LOOP_DEV}p2
mkdir -p ${ROOTFS_DIR}
sudo mount ${ROOT_PART} ${ROOTFS_DIR}

echo "Musicbox ${SRC_VERSION_LONG}" | sudo tee ${ROOTFS_DIR}/etc/issue
sudo rm -rf ${ROOTFS_DIR}/var/lib/apt/lists/* 
sudo rm -rf ${ROOTFS_DIR}/var/cache/apt/*
sudo rm -rf ${ROOTFS_DIR}/var/lib/apt/*
sudo rm -rf ${ROOTFS_DIR}/etc/dropbear/*key
sudo rm -rf ${ROOTFS_DIR}/tmp/*
sudo find ${ROOTFS_DIR}/var/log -type f | sudo xargs rm -f
OTHER_HOMES=$(sudo ls ${ROOTFS_DIR}/home/ | grep -v mopidy)
sudo rm -rf ${ROOTFS_DIR}/home/${OTHER_HOMES}
sudo find ${ROOTFS_DIR}/home/ -type f -name *.log | xargs rm -f
sudo find ${ROOTFS_DIR}/home/ -type f -name *_history | xargs rm -f
sync

sudo umount $ROOTFS_DIR
sudo e2fsck -fy $ROOT_PART

###
# TODO: Shrink image to fit on smaller SD cards? Who still uses 1G SD cards?!
# ROOT_SIZE=`used` + 100M breathing space
#sudo resize2fs ${ROOT_PART} $ROOT_SIZE
#cat <<EOF | sudo fdisk ${LOOP_DEV}
#d
#2
#n
#p
#2
#$OFFSET

#w
#EOF

sudo zerofree -v $ROOT_PART
sudo losetup -D $IMG_NAME
#truncate -s $IMG_SIZE $IMG_NAME

rm -rf $ROOTFS_DIR
cd $SRC_FILES/docs
make text latexpdf
cp _build/text/{changes,faq}.txt  $BUILD_DIR/
cp _build/latex/PiMusicBox.pdf  $BUILD_DIR/
cd $BUILD_DIR
md5sum * > MD5SUMS
zip -9 $ZIP_NAME *

echo "** Success **"
