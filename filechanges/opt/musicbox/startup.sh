#!/bin/bash
#
# MusicBox startup script
#

pre_init()
{
    # Raspberry Pi specific pre-initilisation
    USER_CONFIG=/boot/config/settings.ini

    SYS_CPUFREQ_GOVERNOR=/sys/devices/system/cpu/cpu0/cpufreq/scaling_governor
    if [ -e $SYS_CPUFREQ_GOVERNOR ]; then
        log_progress_msg "Switching to performance scaling governor" "$NAME"
        echo "performance" > $SYS_CPUFREQ_GOVERNOR
    fi
}


post_init()
{
    # check and clean dirty bit of vfat partition if not safely removed
    fsck /dev/mmcblk0p1 -v -a -w -p > /dev/null 2>&1 || true
}


sync_working_config() {
    # Update user's config from current working config.
    mv $TMP_CONFIG $USER_CONFIG || true
}

init()
{
    REBOOT=0
    TMP_CONFIG=/tmp/settings.ini
    READ_CONFIG=/tmp/read.ini
    #log_use_fancy_output

    cp $USER_CONFIG $TMP_CONFIG

    # convert windows ini to unix
    dos2unix -n $TMP_CONFIG $READ_CONFIG > /dev/null 2>&1 || true

    # import ini parser
    . /opt/$NAME/read_ini.sh
    #declare $INI before reading ini https://github.com/rudimeier/bash_ini_parser/issues/2
    unset INI
    declare -A INI
    read_ini $READ_CONFIG
    rm $READ_CONFIG
    INI_READ=true

    if [ "$INI__musicbox__resize_once" == "1" ]
    then
        #set resize_once=false in ini file
        sed -i -e "/^\[musicbox\]/,/^\[.*\]/ s|^\(resize_once[ \t]*=[ \t]*\).*$|\1false\r|" $TMP_CONFIG
        log_progress_msg "Resizing filesystem to full size..." "$NAME"
        raspi-config --expand-rootfs
        REBOOT=1
    fi

    #get name of device and trim
    HOSTNM=`cat /etc/hostname | tr -cd "[:alnum:]"`
    #get name in ini and trim
    CLEAN_NAME=$(echo $INI__network__name | tr -cd "[:alnum:]")
    #max 9 characters (max netbios length = 15, + '.local')
    CLEAN_NAME=$(echo $CLEAN_NAME | cut -c 1-9)

    if [ "$CLEAN_NAME" == "" ]
    then
        CLEAN_NAME="MusicBox"
    fi

    if [ "$CLEAN_NAME" != "$HOSTNM" ]
    then
        #if devicename is not the same as ini, change and reboot<-->
        echo "$CLEAN_NAME" > /etc/hostname
        echo "127.0.0.1       localhost $CLEAN_NAME" > /etc/hosts
        log_end_msg "Name of device set..." "$NAME"
        REBOOT=1
    fi

    # do the change password stuff
    if [ "$INI__musicbox__root_password" != "" ]
    then
        log_progress_msg "Setting root user Password" "$NAME"
        echo "root:$INI__musicbox__root_password" | chpasswd
        #remove password
        sed -i -e "/^\[musicbox\]/,/^\[.*\]/ s|^\(root_password[ \t]*=[ \t]*\).*$|\1\r|" $TMP_CONFIG
    fi

    if [ "$REBOOT" == 1 ]
    then
        sync_working_config
        sync
        reboot
    fi

    log_progress_msg "MusicBox name is $CLEAN_NAME" "$NAME"

    if [ "$INI__network__wifi_network" != "" ]
    then
        #put wifi settings for wpa roaming
        if [ "$INI__network__wifi_password" != "" ]
        then
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

        /etc/init.d/networking restart
    fi

    #include code from setsound script
    . /opt/$NAME/setsound.sh

    if [ "$INI__network__workgroup" != "" ]
    then
        #change smb.conf workgroup value
        sed -i "s/workgroup = .*$/workgroup = $INI__network__workgroup/ig" /etc/samba/smb.conf
        #restart samba
        /etc/init.d/samba restart
    fi

    #redirect 6680 to 80
    iptables -t nat -A PREROUTING -p tcp --dport 80 -j REDIRECT --to-port 6680 > /dev/null 2>&1 || true

    # start SSH if enabled
    if [ "$INI__network__enable_ssh" == "1" ]
    then
        #create private keys for dropbear if they don't exist
        if [ ! -f "/etc/dropbear/dropbear_dss_host_key" ]
        then
            echo "Create dss-key for dropbear..."
            dropbearkey -t dss -f /etc/dropbear/dropbear_dss_host_key
        fi
        if [ ! -f "/etc/dropbear/dropbear_rsa_host_key" ]
        then 
            echo "Create rsa-key for dropbear..."
            dropbearkey -t rsa -f /etc/dropbear/dropbear_rsa_host_key
        fi

        /etc/init.d/dropbear start
        #open ssh port
        iptables -A INPUT -p tcp --dport 22 -j ACCEPT > /dev/null 2>&1 || true
    else
        #close ssh port
        iptables -A INPUT -p tcp --dport 22 -j DENY > /dev/null 2>&1 || true
    fi

    # start upnp if enabled
    if [ "$INI__musicbox__enable_upnp" == "1" ]
    then
        /etc/init.d/upmpdcli start
        ln -s /etc/monit/monitrc.d/upmpdcli /etc/monit/conf.d/upmpdcli > /dev/null 2>&1 || true
    else
        rm /etc/monit/conf.d/upmpdcli > /dev/null 2>&1 || true
    fi

    # start shairport if enabled
    if [ "$INI__musicbox__enable_shairport" == "1" ]
    then
        /etc/init.d/shairport-sync start
        ln -s /etc/monit/monitrc.d/shairport /etc/monit/conf.d/shairport > /dev/null 2>&1 || true
    else
        rm /etc/monit/conf.d/shairport > /dev/null 2>&1 || true
    fi

    #check networking, sleep for a while
    MYIP=$(hostname -I)
    while [ "$MYIP" == "" -a "$INI__network__wait_for_network" != "0" ]
    do
        echo "Waiting for network..."
        echo
        /etc/init.d/networking restart
        sleep 30
        MYIP=$(hostname -I)
    done

    # set date/time
    ntpdate ntp.ubuntu.com > /dev/null 2>&1 || true

    #mount windows share
    if [ "$INI__network__mount_address" != "" ]
    then
        #mount samba share, readonly
        log_progress_msg "Mounting Windows Network drive..." "$NAME"
        if [ "$INI__network__mount_user" != "" ]
        then
            SMB_CREDENTIALS=user=$INI__network__mount_user,password=$INI__network__mount_password
        else
            SMB_CREDENTIALS=guest
        fi
        mount -t cifs -o sec=ntlm,ro,$SMB_CREDENTIALS "$INI__network__mount_address" /music/Network/
    #    mount -t cifs -o sec=ntlm,ro,rsize=2048,wsize=4096,cache=strict,user=$INI__network__mount_user,password=$INI__network__mount_password $INI__network__mount_address /music/Network/
    #add rsize=2048,wsize=4096,cache=strict because of usb (from raspyfi)
    fi

    # scan local music files once
    if [ "$INI__musicbox__scan_once" == "1" ]TMP_CONFIG
    then
        #set SCAN_ONCE = false
        sed -i -e "/^\[musicbox\]/,/^\[.*\]/ s|^\(scan_once[ \t]*=[ \t]*\).*$|\1false\r|" $TMP_CONFIG
    fi

    # scan local/networked music files if setting is true
    if [ "$INI__musicbox__scan_always" == "1" -o "$INI__musicbox__scan_once" == "1" ]
    then
        log_progress_msg "Scanning music-files, please wait..."
        /etc/init.d/mopidy run local scan
        #if somehow mopidy is not killed ok. kill manually
        killall -9 mopidy > /dev/null 2>&1 || true
        /etc/init.d/mopidy start
    fi

    sync_working_config

    #start mopidy
    /etc/init.d/mopidy start

    if [ "$INI__network__name" != "$CLEAN_NAME" -a "$INI__network__name" != "" ]
    then
        log_warning_msg "The new name of your MusicBox, $INI__network__name, is not ok! It should be max. 9 alphanumerical characters."
    fi

    # Print the IP address
    _IP=$(hostname -I) || true
    if [ "$_IP" ]; then
        log_progress_msg "My IP address is $_IP. Connect to MusicBox in your browser via http://$CLEAN_NAME.local or http://$_IP "
    fi

    # renice mopidy to 19, to have less stutter when playing tracks from spotify (at the start of a track)
    renice 19 `pgrep mopidy`

    if [ "$INI__musicbox__autoplay" -a "$INI__musicbox__autoplaymaxwait" ]
    then
        if ! [[ $INI__musicbox__autoplaymaxwait =~ ^[0-9]*+$ ]] ; then
            log_progress_msg "Value specified for 'autoplaymaxwait' is not a number, defaulting to 60" "$NAME"
            INI__musicbox__autoplaymaxwait=60
        fi
        log_progress_msg "Waiting for Mopidy to accept connections..." "$NAME"
        waittime=0
        while ! nc -q 1 localhost 6600 </dev/null;
            do
                sleep 1;
                waittime=$((waittime+1));
                if [ $waittime -gt $INI__musicbox__autoplaymaxwait ]
                    then
                        log_progress_msg "Timeout waiting for Mopidy to start, aborting" "$NAME"
                        break;
                fi
            done
        if [ $waittime -le $INI__musicbox__autoplaymaxwait ]
            then
                log_progress_msg "Mopidy startup complete, playing $INI__musicbox__autoplay" "$NAME"
                mpc add "$INI__musicbox__autoplay"
                mpc play
        fi
    fi
}
