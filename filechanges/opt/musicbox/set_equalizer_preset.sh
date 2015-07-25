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
flat) curve="65 65 65 65 65 65 65 65 65 65" ;;
default) curve="66 68 70 68 66 66 64 62 60 58" ;;
custom) curve=;;
classical) curve="71 71 71 71 71 71 84 83 83 87" ;;
club) curve="71 71 67 63 63 63 67 71 71 71" ;;
dance) curve="57 61 69 71 71 81 83 83 71 71" ;;
headphones) curve="65 55 64 77 75 70 65 57 52 49" ;;
bass) curve="59 59 59 63 70 78 85 88 89 89" ;;
treble) curve="87 87 87 78 68 55 47 47 47 45" ;;
large_hall) curve="56 56 63 63 71 79 79 79 71 71" ;;
live) curve="79 71 66 64 63 63 66 68 68 69" ;;
party) curve="61 61 71 71 71 71 71 71 61 61" ;;
pop) curve="74 65 61 60 64 73 75 75 74 74" ;;
reggae) curve="71 71 72 81 71 62 62 71 71 71" ;;
rock) curve="58 63 80 84 77 66 58 55 55 55" ;;
ska) curve="75 79 78 72 66 63 58 57 55 57" ;;
soft_rock) curve="66 66 69 72 78 80 77 72 68 58" ;;
soft) curve="65 70 73 75 73 66 59 57 55 53" ;;
techno) curve="60 63 71 80 79 71 60 57 57 58" ;;
*) echo "Unknown profile ${profile}" >&2 ;;
esac

[ "${curve}" ] && set_equalizer_curve "${curve}"
