#! /bin/sh

################
# The blablabla

# Author:	Thomas DEBESSE <bidouille (ad) illwieckz.net>
# Last update:	2013-09-04
# Licence:	WTFPL http://www.wtfpl.net/about/

# Howto:
# Run this script on each side after modifying the hostnames and other options at your convenience.
# Interrupt it with ^C.

# Useful informations:
# Much of this options are unnecessary, but their use here shows their potential.
# DISTANT_HOSTNAME is the target hostname.
# LOCAL_HOSTNAME is usefull to bind a specific network interface for listening when you have multiple network interface.
# Pay attention to audio format, some high-end sound cards do not support S16_LE but S32_LE for example.
# Opus does not support a bitrate of 44100, you can use your audio soundcard with a bitrate of 44100 thanks to audioresample Gstreamer module.
# Beware, this is a proof of concept, use it at your own risk.

# Known bugs with or without fix:
# * If you use Debian Squeeze, put "net.ipv6.bindv6only = 0" in "/etc/sysctl.d/bindv6only.conf" and reboot before running this script if you want to use IPv4 adress.
# * There is a bug with alsa modules when used continuously for hours or days continuously, see https://bugzilla.gnome.org/show_bug.cgi?id=692953 for more information.

#############
# The options

# Common
AUDIO_CHANNELS=2		# 1 3 4
OPUS_RATE=48000			# 8000 16000

# Sender
INPUT_AUDIO_DEVICE="hw:0"	# default dnsoop:hw:0 hw:Live hw:Juli
INPUT_AUDIO_RATE=48000		# 44100
INPUT_AUDIO_FORMAT="S16LE"	# S32LE
OPUS_BITRATE=128000		# 64000 96000 192000
OPUS_CBR=true			# false
OPUS_DTX=false			# true
OPUS_FEC=false			# true
OPUS_PLC=0			# 10 50 100
DISTANT_HOSTNAME="127.0.0.1"	# example.com
DISTANT_PORT=5004		# 4950 5005

# Receiver
OUTPUT_AUDIO_DEVICE="hw:0"	# default dmix:hw:0 hw:Live hw:Juli
OUTPUT_AUDIO_RATE=48000		# 44100
OUTPUT_AUDIO_FORMAT="S16LE"	# S32LE
OPUS_BITRATE=128000		# 64000 96000 192000
OPUS_CBR=true			# false
OPUS_DTX=false			# true
OPUS_FEC=false			# true
OPUS_PLC=0			# 10 50 100
LATENCY=60			# 200
LOCAL_HOSTNAME="127.0.0.1"	# example.com
LOCAL_PORT=5004			# 4950 5005

##########
# The code

colorize() {
	prefix=${1}
	color=${2}
	while read -r line
	do /bin/echo -e '\033[01;30m'$(date '+%Y%m%d-%H%M%S')' \033[01;3'${color}'m'${prefix}': \033[00;3'${color}'m'${line}'\033[00m'
	done
}


export GST_DEBUG=3

# The sender pipeline
gst-launch-1.0 -v alsasrc device=${INPUT_AUDIO_DEVICE} \
	! capsfilter caps="audio/x-raw, format=${INPUT_AUDIO_FORMAT}, rate=${INPUT_AUDIO_RATE}, channels=${AUDIO_CHANNELS}" \
	! audioconvert \
	! audioresample \
	! capsfilter caps="audio/x-raw, format=S16LE, rate=${OPUS_RATE}, channels=${AUDIO_CHANNELS}" \
	! opusenc cbr=${OPUS_CBR} bitrate=${OPUS_BITRATE} dtx=${OPUS_DTX} inband-fec=${OPUS_FEC} packet-loss-percentage=${OPUS_PLC} \
	! rtpopuspay \
	! udpsink host=${DISTANT_HOSTNAME} port=${DISTANT_PORT} \
	2>&1 | colorize "sender" 4 & PID_SENDER=${!}

# The receiver pipeline
gst-launch-1.0 -v udpsrc uri="udp://${LOCAL_HOSTNAME}:${LOCAL_PORT}" \
	! capsfilter caps='application/x-rtp, media=(string)audio, clock-rate=(int)'${OPUS_RATE}', payload=(int)96, caps=(string)"audio/x-opus"' \
	! rtpjitterbuffer latency=${LATENCY} drop-on-latency=true \
	! rtpopusdepay \
	! opusdec \
	! audioconvert \
	! audioresample \
	! capsfilter caps="audio/x-raw, format=${OUTPUT_AUDIO_FORMAT}, rate=${OUTPUT_AUDIO_RATE}, channels=${AUDIO_CHANNELS}" \
	! alsasink device=${OUTPUT_AUDIO_DEVICE} sync=false \
	2>&1 | colorize "receiver" 6 & PID_RECEIVER=${!}

trap "kill ${PID_SENDER} ${PID_RECEIVER}; exit" 2

while true
do read -r nothing
done

#########
# The end
#EOF
