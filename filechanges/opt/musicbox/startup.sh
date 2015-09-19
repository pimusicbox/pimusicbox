#!/bin/sh
#
# MusicBox startup script
#

. /opt/musicbox/helpers.sh

USER_CONFIG=/boot/config/settings.ini

pre_init()
{
    SYS_CPUFREQ_GOVERNOR=/sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
    if [ -e $SYS_CPUFREQ_GOVERNOR ]; then
        log_action_begin_msg "Switching to performance scaling governor"
        echo "performance" > $SYS_CPUFREQ_GOVERNOR
        log_action_end_msg $?
    fi
}

post_init()
{
    # check and clean dirty bit of vfat partition if not safely removed
    fsck /dev/mmcblk0p1 -v -a -w -p > /dev/null 2>&1 || true
}

init()
{
    REBOOT=false
    INI_READ=false

    load_settings $USER_CONFIG    

    if [ "$INI__musicbox__resize_once" == "1" ]
    then
        #set resize_once=false in ini file
        sed -i -e "/^\[musicbox\]/,/^\[.*\]/ s|^\(resize_oncecc[ \t]*=[ \t]*\).*$|\1false\r|" $USER_CONFIG
        log_action_begin_msg "Resizing filesystem to full size..."
        raspi-config --expand-rootfs
        log_action_end_msg $?
        REBOOT=true
    fi

    #get name of device and trim
    HOSTNM=`cat /etc/hostname | tr -cd "[:alnum:]"`
    #get name in ini and trim
    CLEAN_NAME=$(echo $INI__network__name | tr -cd "[:alnum:]")
    #max 9 characters (max netbios length = 15, + '.local')
    CLEAN_NAME=$(echo $CLEAN_NAME | cut -c 1-9)
    if [ "$INI__network__name" != "$CLEAN_NAME" -a "$INI__network__name" != "" ]
    then
        log_warning_msg "The new name of your MusicBox, $INI__network__name, is not ok! It should be max. 9 alphanumerical characters."
    fi
    if [ "$CLEAN_NAME" == "" ]
    then
        CLEAN_NAME="MusicBox"
    fi
    if [ "$CLEAN_NAME" != "$HOSTNM" ]
    then
        #if devicename is not the same as ini, change and reboot<-->
        log_action_begin_msg "Changing hostname to $CLEAN_NAME"
        echo "$CLEAN_NAME" > /etc/hostname
        echo "127.0.0.1       localhost $CLEAN_NAME" > /etc/hosts
        log_action_end_msg $?
        REBOOT=true
    fi

    # do the change password stuff
    if [ "$INI__musicbox__root_password" != "" ]
    then
        log_action_begin_msg "Setting root user password"
        echo "root:$INI__musicbox__root_password" | chpasswd
        log_action_end_msg $?
        #remove password
        sed -i -e "/^\[musicbox\]/,/^\[.*\]/ s|^\(root_password[ \t]*=[ \t]*\).*$|\1\r|" $USER_CONFIG
    fi

    if $REBOOT
    then
        log_action_msg "Will now restart to continue"
        sync
        reboot
    fi

    log_action_msg "MusicBox name is $CLEAN_NAME"

    if [ "$INI__network__wifi_network" != "" ]
    then
        #put wifi settings for wpa roaming
        if [ "$INI__network__wifi_password" != "" ]
        then
            log_action_msg "Using secured wireless network $INI__network__wifi_network"
            cat >/etc/wpa.conf <<EOF
            ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev
            update_config=1
            network={
                ssid="$INI__network__wifi_network"
                psk="$INI__network__wifi_password"
                scan_ssid=1
            }
EOF
        else
            #if no password is given, set key_mgmt to NONE
            log_action_msg "Using unsecured wireless network $INI__network__wifi_network"
            cat >/etc/wpa.conf <<EOF
            ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev
            update_config=1
            network={
                ssid="$INI__network__wifi_network"
                key_mgmt=NONE
                scan_ssid=1
            }
EOF
        fi

        #enable wifi
    #    ifdown wlan0
        ifup wlan0
        service networking restart
    fi

    #include code from setsound script
    . /opt/musicbox/setsound.sh

    if [ "$INI__network__workgroup" != "" ]
    then
        sed -i "s/workgroup = .*$/workgroup = $INI__network__workgroup/ig" /etc/samba/smb.conf
        service samba restart
    fi

    #redirect 6680 to 80
    iptables -t nat -A PREROUTING -p tcp --dport 80 -j REDIRECT --to-port 6680 > /dev/null 2>&1 || true

    # start SSH if enabled
    if [ "$INI__network__enable_ssh" == "1" ]
    then
        #create private keys for dropbear if they don't exist
        if [ ! -f "/etc/dropbear/dropbear_dss_host_key" ]
        then
            log_action_begin_msg "Create dss-key for dropbear..."
            dropbearkey -t dss -f /etc/dropbear/dropbear_dss_host_key
            log_action_end_msg $?
        fi
        if [ ! -f "/etc/dropbear/dropbear_rsa_host_key" ]
        then 
            log_action_begin_msg "Create rsa-key for dropbear..."
            dropbearkey -t rsa -f /etc/dropbear/dropbear_rsa_host_key
            log_action_end_msg $?
        fi

        service dropbear start
        #open ssh port
        iptables -A INPUT -p tcp --dport 22 -j ACCEPT > /dev/null 2>&1 || true
    else
        #close ssh port
        iptables -A INPUT -p tcp --dport 22 -j DENY > /dev/null 2>&1 || true
    fi

    # start upnp if enabled
    if [ "$INI__musicbox__enable_upnp" == "1" ]
    then
        log_action_begin_msg "Starting upmpdcli"
        service upmpdcli start
        log_action_end_msg $?
        ln -s /etc/monit/monitrc.d/upmpdcli /etc/monit/conf.d/upmpdcli > /dev/null 2>&1 || true
    else
        rm /etc/monit/conf.d/upmpdcli > /dev/null 2>&1 || true
    fi

    # start shairport if enabled
    if [ "$INI__musicbox__enable_shairport" == "1" ]
    then
        log_action_begin_msg "Starting shairport-sync"
        service shairport-sync start
        log_action_end_msg $?
        ln -s /etc/monit/monitrc.d/shairport /etc/monit/conf.d/shairport > /dev/null 2>&1 || true
    else
        rm /etc/monit/conf.d/shairport > /dev/null 2>&1 || true
    fi

    #check networking, sleep for a while
    MYIP=$(hostname -I)
    while [ "$MYIP" == "" -a "$INI__network__wait_for_network" != "0" ]
    do
        log_action_msg "Waiting 30 more seconds for network.."
        service networking restart
        sleep 30
        MYIP=$(hostname -I)
    done

    # set date/time
    ntpdate ntp.ubuntu.com > /dev/null 2>&1 || true

    #mount windows share
    if [ "$INI__network__mount_address" != "" ]
    then
        #mount samba share, readonly
        log_action_begin_msg "Mounting Windows Network drive $INI__network__mount_address"
        if [ "$INI__network__mount_user" != "" ]
        then
            SMB_CREDENTIALS=user=$INI__network__mount_user,password=$INI__network__mount_password
        else
            SMB_CREDENTIALS=guest
        fi
        mount -t cifs -o sec=ntlm,ro,$SMB_CREDENTIALS "$INI__network__mount_address" /music/Network/
        #mount -t cifs -o sec=ntlm,ro,rsize=2048,wsize=4096,cache=strict,user=$INI__network__mount_user,password=$INI__network__mount_password $INI__network__mount_address /music/Network/
        #add rsize=2048,wsize=4096,cache=strict because of usb (from raspyfi)
        mountpoint -q /music/Network/ 
        log_action_end_msg $?
    fi

    # scan local music files once
    if [ "$INI__musicbox__scan_once" == "1" ]
    then
        #set SCAN_ONCE = false
        sed -i -e "/^\[musicbox\]/,/^\[.*\]/ s|^\(scan_once[ \t]*=[ \t]*\).*$|\1false\r|" $USER_CONFIG
    fi

    # scan local/networked music files if setting is true
    if [ "$INI__musicbox__scan_always" == "1" -o "$INI__musicbox__scan_once" == "1" ]
    then
        log_action_msg "Scanning music files, please wait.."
        mopidyctl local scan
        #if somehow mopidy is not killed ok. kill manually
        killall -9 mopidy > /dev/null 2>&1 || true
    fi

    #start mopidy
    log_action_begin_msg "Starting mopidy"
    service mopidy start
    log_action_end_msg $?

    # Print the IPv4 address
    _IP=$(ip route get 1 | awk '{print $NF;exit}') || true
    if [ "$_IP" ]; then
        log_action_msg "My IP address is ${_IP}. Connect to me in your browser at http://$CLEAN_NAME.local or http://${_IP}"
    fi

    # renice mopidy to 19, to have less stutter when playing tracks from spotify (at the start of a track)
    renice 19 `pgrep mopidy`

    if [ "$INI__musicbox__autoplay" -a "$INI__musicbox__autoplaymaxwait" ]
    then
        if ! [[ $INI__musicbox__autoplaymaxwait =~ ^[0-9]*+$ ]] ; then
            log_warning_msg "Value specified for 'autoplaymaxwait' is not a number, defaulting to 60"
            INI__musicbox__autoplaymaxwait=60
        fi
        log_action_begin_msg "Waiting for Mopidy to accept connections.."
        waittime=0
        while ! nc -q 1 localhost 6600 </dev/null;
            do
                sleep 1;
                waittime=$((waittime+1));
                if [ $waittime -gt $INI__musicbox__autoplaymaxwait ]
                    then
                        log_action_end_msg 1 "timeout"
                        break;
                fi
            done
        if [ $waittime -le $INI__musicbox__autoplaymaxwait ]
            then
                log_action_end_msg $?
                log_action_msg "Autoplaying $INI__musicbox__autoplay" "$NAME"
                mpc add "$INI__musicbox__autoplay"
                mpc play
        fi
    fi
}
