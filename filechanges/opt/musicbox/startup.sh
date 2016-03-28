#!/bin/bash
#
# MusicBox startup script
#

. /opt/musicbox/utils.sh

configure_audio()
{
    if [ $INI__musicbox__output  != "" ]
    then
        . /opt/musicbox/setsound.sh
    fi
}

mount_shares()
{
    if [ "$INI__network__mount_address" != "" ]
    then
        echo "Mounting Windows Network drive $INI__network__mount_address"
        if [ "$INI__network__mount_user" != "" ]
        then
            MOUNT_CREDS=user=$INI__network__mount_user,password=$INI__network__mount_password
        else
            MOUNT_CREDS=guest
        fi
        MOUNT_OPTS=${INI__network__mount_options:-ro,sec=ntlm,$MOUNT_CREDS}
        MOUNT_TYPE=${INI__network__mount_type:-cifs}
        mount -t "$MOUNT_TYPE" -o "$MOUNT_OPTS" "$INI__network__mount_address" /music/Network/
        if mountpoint -q /music/Network/
        then
            echo "Successfully mounted '$INI__network__mount_address' at /music/Network"
        else
            echo "Failed to mount '$INI__network__mount_address' at /music/Network"
        fi
    fi
}

configure_network()
{
    # Configure the firewall
    # TODO: Use iptables-persistent and make edits to /etc/iptables/rules.v4
    if [ $(is_service_enabled ssh) = 1 ]    
    then
        iptables -A INPUT -p tcp --dport 22 -j ACCEPT > /dev/null 2>&1 || true
    else
        iptables -A INPUT -p tcp --dport 22 -j DENY > /dev/null 2>&1 || true
    fi

    if [ "$INI__musicbox__webclient" != "" ]
    then
        echo "set \$webclient $INI__musicbox__webclient;" | tee /etc/nginx/conf.d/musicbox > /dev/null
        systemctl --quiet reload nginx
    fi

    if [ "$INI__network__workgroup" != "" ]
    then
        WORKGROUP=$(awk -F "=" '/workgroup/ && NF > 1 {print $2}' /etc/samba/smb.conf | tr -d ' ')
        if [ "$WORKGROUP" != "$INI__network__workgroup" ]
        then
            echo "Changing network workgroup to $INI__network__workgroup"
            sed -i "s/workgroup = .*$/workgroup = $INI__network__workgroup/ig" /etc/samba/smb.conf
            # TODO: Need to restart both?
            systemctl --quiet restart smbd nmbd
        fi
    fi

    # set date/time
    # TODO Remove and ensure fake-hwclock handles this
    ntpdate ntp.ubuntu.com > /dev/null 2>&1 || true
}

configure_wifi()
{
    if [ "$INI__network__wifi_network" != "" ]
    then
        if [ "$INI__network__wifi_password" != "" ]
        then
            WPA_PSK_FIELD=psk=\"$INI__network__wifi_password\"
            echo "Using secured wireless network '$INI__network__wifi_network'"
        else
            echo "Using unsecured wireless network '$INI__network__wifi_network'"
            WPA_PSK_FIELD=key_mgmt=NONE
        fi
        cat >/etc/wpa_supplicant/wpa_supplicant.conf <<EOF
ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev
update_config=1
network={
    ssid="$INI__network__wifi_network"
    $WPA_PSK_FIELD
    scan_ssid=1
}
EOF
        # wpa-supplicant doesn't seem to reload on file changes.
        wpa_cli reconfigure
        # Otherwise...
        #ifdown wlan0
        #ifup wlan0
    fi
}

configure_service_ssh()
{
    return
    #TODO: Use iptables-persistent?
    if [ "$1" == "1" ]
    then
        sed -i '/--dport 22/ s/DENY/ACCEPT/g' /etc/iptables/rules.v4
    else
        sed -i '/--dport 22/ s/ACCEPT/DENY/g' /etc/iptables/rules.v4
    fi
}

configure_service()
{
    SERVICE_FUNC=
    case "$1" in
    upnp)
        SERVICE_NAME=upmpdcli
        SETTING_NAME=enable_upnp
        SETTING_ENABLED=INI__musicbox__$SETTING_NAME
        ;;
    shairport)
        SERVICE_NAME=shairport-sync
        SETTING_NAME=enable_shairport
        SETTING_ENABLED=INI__musicbox__$SETTING_NAME
        ;;
    ssh)
        SERVICE_NAME=dropbear
        SETTING_NAME=enable_ssh
        SETTING_ENABLED=INI__network__$SETTING_NAME
        SERVICE_FUNC=configure_service_ssh
        ;;
    *)
        echo "ERROR: Cannot configure unknown service '$1'"
        return
    esac
    SETTING_ENABLED="${!SETTING_ENABLED:-0}"
    [ -f $MUSICBOX_STATE/$SETTING_NAME ] && IS_ENABLED=1 || IS_ENABLED=0
    if [ $SETTING_ENABLED != $IS_ENABLED ]
    then
        if [ $SETTING_ENABLED == 1 ]
        then
            ACTION=start
            echo "Enabling $SERVICE_NAME"
            touch $MUSICBOX_STATE/$SETTING_NAME
            if [ -f /etc/monit/monitrc.d/$SERVICE_NAME ]
            then
                ln -s /etc/monit/monitrc.d/$SERVICE_NAME /etc/monit/conf.d/$SERVICE_NAME
            fi
        else
            ACTION=stop
            echo "Disabling $SERVICE_NAME"
            rm -f $MUSICBOX_STATE/$SETTING_NAME
            rm -f /etc/monit/conf.d/$SERVICE_NAME
        fi
        [ $SETTINGS_UPDATE = 1 ] && systemctl --quiet $ACTION $SERVICE_NAME
        $SERVICE_FUNC $SETTING_ENABLED
    fi
}

change_hostname()
{
    if [ "$INI__network__name" != "" ]
    then
        # Check new hostname is legal.
        NEW_HOSTNAME=$(echo $INI__network__name | tr -cd "[:alnum:]" | cut -c 1-9)
        if [ "$INI__network__name" != "$NEW_HOSTNAME" ]
        then
            echo "ERROR: The new name of your MusicBox '$INI__network__name' is not valid! It should be max. 9 alphanumerical characters."
            return
        fi
        if [ "$NEW_HOSTNAME" != "$CURRENT_HOSTNAME" ]
        then
            #if devicename is not the same as ini, change and reboot<-->
            echo "Changing name from '$CURRENT_HOSTNAME' to '$NEW_HOSTNAME'"
            echo "$NEW_HOSTNAME" > /etc/hostname
            echo "127.0.0.1       localhost $NEW_HOSTNAME" > /etc/hosts
            sed -i "s/friendlyname = .*/friendlyname = $NEW_HOSTNAME/" /etc/upmpdcli.conf
            REBOOT=1
        fi
    fi
}

change_system_password()
{
    #TODO: Change this to system_password
    if [ "$INI__musicbox__root_password" != "" ]
    then
        echo "Changing password for user pi"
        echo "pi:$INI__musicbox__root_password" | chpasswd
        # Strip password from config file.
        save_setting_to_file $USER_CONFIG musicbox root_password
        REBOOT=1
    fi
}

configure_platform()
{
    SYS_CPUFREQ_GOVERNOR=/sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
    if [ -e $SYS_CPUFREQ_GOVERNOR ]; then
        echo "Switching to performance scaling governor"
        echo "performance" > $SYS_CPUFREQ_GOVERNOR
    fi
}

post_init()
{
    # check and clean dirty bit of vfat partition if not safely removed
    fsck /dev/mmcblk0p1 -v -a -w -p > /dev/null 2>&1 || true
}

configure_scan()
{
    # scan local music files once
    if [ "$INI__musicbox__scan_once" == "1" ]
    then
        save_setting_to_file $USER_CONFIG musicbox scan_once false
        touch $MUSICBOX_STATE/scan_once
    else
        rm -f $MUSICBOX_STATE/scan_once
    fi

    if [ "$INI__musicbox__scan_always" == "1" ]
    then
        touch $MUSICBOX_STATE/scan_always
    else
        rm -f $MUSICBOX_STATE/scan_always
    fi
}

show_system_info()
{
    echo "MusicBox name is ${CURRENT_HOSTNAME}"

    # Print the IPv4 address
    MY_IP=$(ip route get 1 | awk '{print $NF;exit}') || true
    if [ "$MY_IP" ]; then
        echo "My IP address is ${MY_IP}"
        echo "Connect to me in your browser at http://${CURRENT_HOSTNAME}.local or http://${MY_IP}"
    fi
}

do_init()
{
    REBOOT=0
    CURRENT_HOSTNAME=`cat /etc/hostname | tr -cd "[:alnum:]"`

    load_settings

    change_system_password
    change_hostname
    configure_audio

    # Depending on changes performned so far, a reboot may be required.
    reboot_musicbox $REBOOT

    configure_platform
    configure_service ssh
    configure_service upnp
    #configure_service shairport
    configure_wifi
    configure_network
    mount_shares
    configure_scan

    show_system_info
}

case "$1" in
  start)
    do_init
    ;;
  update)
    SETTINGS_UPDATE=1
    do_init
    ;;
  audio)
    configure_audio
    ;;
  status)
    echo "YEHHH!"
    ;;
  *)
    echo "Unrecognised command"
    exit 3
    ;;
esac  
