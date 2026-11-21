#!/bin/bash
# Curated action menu (SUPER+T). Each entry is "Label|command"; add a line to
# add an action. Entries you pick most often float to the top (history file).
# Commands run detached so they outlive this script.

entries=(
	"Power off|systemctl poweroff"
	"Reboot|systemctl reboot"
	"Reboot to BIOS|systemctl reboot --firmware-setup"
	"Suspend|noctalia msg session lock; sleep 0.5; systemctl suspend-then-hibernate"
	"Lock|noctalia msg session lock"
	"Log out|noctalia msg session logout"
	"Wi-Fi (nmtui)|foot -T nmtui nmtui"
	"Bluetooth on/off|noctalia msg bluetooth-toggle"
	"Caffeine (stay awake) on/off|noctalia msg caffeine-toggle"
	"Screenshot region to clipboard|f=\$(mktemp /tmp/screenshot-XXXXX.png) && grim -g \"\$(slurp)\" \"\$f\" && wl-copy < \"\$f\" && notify-send -i \"\$f\" Screenshot 'Copied to clipboard'"
	"Draw on screen|noctalia msg annotate"
	"Pin/unpin bar|~/.config/hypr/scripts/bar-toggle.sh"
	"Restart Noctalia|pkill -x noctalia; sleep 0.3; noctalia"
	"Reload Hyprland config|hyprctl reload"
)

choice=$(printf '%s\n' "${entries[@]%%|*}" | tofi \
	--prompt-text "  " \
	--history-file "${XDG_STATE_HOME:-$HOME/.local/state}/tofi-menu-history") || exit 0

for e in "${entries[@]}"; do
	if [[ ${e%%|*} == "$choice" ]]; then
		setsid -f bash -c "${e#*|}" >/dev/null 2>&1
		exit 0
	fi
done
