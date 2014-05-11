#!/bin/bash
# from http://snippets.khromov.se/raspberry-pi-shairport-build-instructions/
# find service pids
pgrep shairport

#if we get no pids, service is not running
if [ $? -ne 0 ]
then
 service shairport start
 echo "shairport started or restarted."
fi

# find service pids
pgrep gmediarender

#if we get no pids, service is not running
if [ $? -ne 0 ]
then
 service gmediarenderer start
 echo "gmediarenderer started or restarted."
fi

# find service pids
pgrep mopidy

#if we get no pids, service is not running
if [ $? -ne 0 ]
then
 service mopidy start
 echo "mopidy started or restarted."
fi

