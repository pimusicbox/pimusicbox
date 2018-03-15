#!/bin/bash
if [ "$PLAYER_EVENT" == "start" ]
then
    /usr/bin/mpc -q stop
fi
