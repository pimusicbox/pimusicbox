#!/bin/sh
#
# MusicBox equalizer presets script.
#

set_equalizer_curve() {
  curve="${*}"
  ctl=0
  for point in ${curve}
  do
    ctl=$(( ${ctl} + 1 ))
    echo cset numid=${ctl} ${point}
  done | amixer -D equal -s
}

profile="${1:-flat}"
case "${profile}" in
    bass) curve="50 50 50 52 56 60 63 65 65 65" ;;
    classical) curve="50 50 50 50 50 50 62 61 61 65" ;;
    club) curve="65 65 58 50 50 50 58 65 65 65" ;;
    dance) curve="50 52 57 58 58 64 65 65 58 58" ;;
    favorite) curve="65 65 65 62 58 53 55 57 62 55" ;;
    flat) curve="58 58 58 58 58 58 58 58 58 58" ;;
    headphones) curve="59 53 58 65 64 61 59 54 52 50" ;;
    large_hall) curve="50 50 55 55 60 65 65 65 60 60" ;;
    live) curve="65 58 53 51 50 50 53 55 55 56" ;;
    party) curve="50 50 65 65 65 65 65 65 50 50" ;;
    perfect) curve="50 56 61 58 56 54 58 61 65 59" ;;
    pop) curve="64 55 51 50 54 63 65 65 64 64" ;;
    reggae) curve="57 57 58 65 57 50 50 57 57 57" ;;
    rock) curve="52 54 63 65 61 56 52 50 50 50" ;;
    ska) curve="63 65 64 61 57 55 52 51 50 51" ;;
    soft) curve="58 62 64 65 64 59 54 53 51 50" ;;
    soft_rock) curve="55 55 58 60 64 65 63 60 57 50" ;;
    techno) curve="52 54 59 65 64 59 52 50 50 51" ;;
    treble) curve="65 65 65 62 58 54 51 51 51 50" ;;
    *) echo "Unknown profile ${profile}" >&2 ;;
esac

[ "${curve}" ] && set_equalizer_curve "${curve}"

# Make sure permissions are correct (in case script is not run as user 'mopidy')
chown mopidy:mopidy /home/mopidy/.alsaequal.bin
