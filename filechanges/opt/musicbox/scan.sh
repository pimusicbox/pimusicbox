#!/bin/bash
#
# MusicBox local scan
#

SCAN_LOCKFILE=/run/musicbox/scan.lock

if [ -f SCAN_LOCKFILE ]
then
	printf "Warning: Scan already in progress ($SCAN_LOCKFILE)"
	return 1
fi

touch $SCAN_LOCKFILE
mopidyctl -o logging/config_file= local scan "$@"
rm $SCAN_LOCKFILE
