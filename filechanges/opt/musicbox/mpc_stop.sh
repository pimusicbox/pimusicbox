#!/bin/bash
if [ "$PLAYER_EVENT" == "start" ] || [ "$PLAYER_EVENT" == "stop" ]
then
    /usr/bin/mpc -q stop
fi
