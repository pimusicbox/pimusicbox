#!/bin/bash
# $1 is the service which sent the request

if [ "$1" != "mp" ]
then
  #stop mopidy
  mpc stop
fi

AIRPLAY=$(netstat -atunp | grep ESTABLISHED | grep 5002)
UPNP=$(netstat -atunp | grep gmediarender | grep "CLOSE_WAIT\|ESTABLISHED")

if [ "$1" != "gm" ]
then
  # check gmediarender state with:  netstat -atunp | grep gmediarender | grep "CLOSE_WAIT\|ESTABLISHED"
  if [ "$UPNP" ]
  then
    /etc/init.d/gmediarenderer stop
    killall -9 gmediarender
    #stop gmediarender (a bit rude, but I don't know how else...)
    /etc/init.d/gmediarenderer start
  fi
fi

if [ "$1" != "sp" ]
then
  # check airplay state with: netstat -atunp | grep ESTABLISHED | grep 5002
  if [ "$AIRPLAY" ]
  then
    killall -9 shairport
    #stop shairport (a bit rude, but I don't know how else...)
    /etc/init.d/shairportinit restart
  fi
fi
