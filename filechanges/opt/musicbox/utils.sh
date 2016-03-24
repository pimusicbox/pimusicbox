#
# MusicBox helper functions
#

DEFAULT_USER_CONFIG=/boot/config/settings.ini
MUSICBOX_STATE=/var/opt/musicbox

load_settings()
{
    USER_CONFIG=${USER_CONFIG:-$DEFAULT_USER_CONFIG}
    INI_READ=false
    load_settings_from_file $USER_CONFIG
}

load_settings_from_file()
{
    $INI_READ && return
    echo "Loading Musicbox settings from $1"
    if [ ! -r $1 ]; then
        echo "ERROR: Unable to read musicbox settings at $1"
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
}

is_service_enabled()
{
    #systemctl is-enabled $1 &>/dev/null && echo 1 || echo 0
    [ -f $MUSICBOX_STATE/enable_$1 ] && echo 1 || echo 0
}

save_setting_to_file()
{
    FILE=$1
    SECTION=$2
    FIELD=$3
    VALUE=$4
    sed -i -e "/^\[$SECTION\]/,/^\[.*\]/ s|^\($FIELD[ \t]*=[ \t]*\).*$|\1$VALUE\r|" $FILE
}

backup_original()
{
    FILE=$1
    KEY="$2"
    if [ -f $1 ]
    then
        ! grep -q "$KEY" $FILE && cp $FILE $FILE.orig
    fi
}

set_reboot_needed()
{
    [ -f /run/musicbox/needreboot ] || echo "A system restart is required..."
    touch /run/musicbox/needreboot
}

reboot_musicbox()
{
    DO_REBOOT=${DO_REBOOT:-0}
    if [ $DO_REBOOT = 1 ] || [ -f /run/musicbox/needreboot ]
    then
        echo "Musicbox is now restarting..."
        sync
        reboot
    fi
}
