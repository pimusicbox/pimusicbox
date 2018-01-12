#!/bin/bash
export APT_PROXY=localhost:3142
cp pimusicbox-0.6.0/musicbox0.6.img .
./pimusicbox/makeimage.sh musicbox0.6.img bigger
./pimusicbox/chroot.sh musicbox0.6.img create_musicbox0.7.sh
