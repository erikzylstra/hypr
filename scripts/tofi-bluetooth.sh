#!/bin/bash
# Bluetooth picker (SUPER+ALT+B): connect or disconnect a paired device.
# ● = connected. Turns Bluetooth on first if it is off.

declare -A mac_of
lines=()
while read -r _ mac name; do
	if bluetoothctl info "$mac" | grep -q "Connected: yes"; then
		label="●  $name"
	else
		label="○  $name"
	fi
	mac_of[$label]=$mac
	lines+=("$label")
done < <(bluetoothctl devices Paired)

if ((${#lines[@]} == 0)); then
	notify-send -i bluetooth "Bluetooth" "No paired devices"
	exit 0
fi

choice=$(printf '%s\n' "${lines[@]}" | tofi --prompt-text "  ") || exit 0
mac=${mac_of[$choice]}
name=${choice#*  }
[[ -n $mac ]] || exit 0

if [[ $choice == ●* ]]; then
	bluetoothctl disconnect "$mac" >/dev/null && msg="Disconnected from $name" || msg="Could not disconnect $name"
else
	bluetoothctl show | grep -q "Powered: yes" || bluetoothctl power on >/dev/null
	notify-send -i bluetooth "Bluetooth" "Connecting to $name…"
	bluetoothctl --timeout 15 connect "$mac" >/dev/null && msg="Connected to $name" || msg="Could not connect to $name"
fi
notify-send -i bluetooth "Bluetooth" "$msg"
