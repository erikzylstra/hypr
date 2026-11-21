#!/bin/bash
# Keybind cheat sheet (SUPER+H): search every Hyprland keybind; Enter runs it.
# The list is written by ~/.config/hypr/lib/cheatsheet.lua on each config load;
# label a bind better by giving it desc("...") in hyprland/keybinds.lua.

f="${XDG_RUNTIME_DIR:-/tmp}/hypr-keybinds.tsv"
if [[ ! -s $f ]]; then
	notify-send "Keybind cheat sheet" "No keybind list yet. Reload Hyprland."
	exit 0
fi

w=$(cut -f2 "$f" | awk '{ if (length > m) m = length } END { print m }')
mapfile -t rows < <(awk -F'\t' -v w="$w" '{ printf "%s\t%-*s   %s\n", $1, w, $2, $3 }' "$f")

choice=$(printf '%s\n' "${rows[@]#*$'\t'}" | tofi --prompt-text "  " --width 65%) || exit 0

for r in "${rows[@]}"; do
	if [[ ${r#*$'\t'} == "$choice" ]]; then
		sleep 0.1 # let focus return to the previous window first
		hyprctl eval "hypr_cheatsheet_run(${r%%$'\t'*})" >/dev/null
		exit 0
	fi
done
