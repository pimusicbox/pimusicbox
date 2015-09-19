#!/bin/bash
#
# MusicBox helper functions
#

. /lib/lsb/init-functions

load_settings()
{
    $INI_READ && return
    log_action_begin_msg "Loading settings from $1"
    if [ ! -r $1 ]; then
        log_action_end_msg 1 "cannot read settings file"
        return
    fi

    READ_CONFIG=/tmp/settings.ini
    # convert windows ini to unix
    dos2unix -n $1 $READ_CONFIG > /dev/null 2>&1 || true

    # import ini parser
    . /opt/musicbox/read_ini.sh
    #declare $INI before reading ini https://github.com/rudimeier/bash_ini_parser/issues/2
    unset INI
    declare -A INI
    read_ini $READ_CONFIG
    rm -f $READ_CONFIG
    INI_READ=true
    log_action_end_msg 0
}
