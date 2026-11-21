#!/usr/bin/env bash
# Toggle a gpu-screen-recorder recording into ~/Videos: the first press starts, the next press stops.
# Usage: screen-record.sh [audio|silent|region]
set -u

if pkill -INT -f '^gpu-screen-recorder'; then
	notify-send "Recording saved" "In ~/Videos"
	exit 0
fi

out=~/Videos/recording-$(date +%Y%m%d_%H%M%S).mp4
case "${1:-audio}" in
	audio) args=(-w screen -a default_output) ;;
	silent) args=(-w screen) ;;
	region)
		region=$(slurp -f '%wx%h+%x+%y') || exit 0
		args=(-w region -region "$region")
		;;
	*)
		echo "usage: $0 [audio|silent|region]" >&2
		exit 2
		;;
esac

notify-send "Recording" "Press the same keys again to stop"
gpu-screen-recorder "${args[@]}" -f 60 -o "$out" ||
	notify-send -u critical "Recording failed" "Run ~/.config/hypr/scripts/screen-record.sh in a terminal to see why"
