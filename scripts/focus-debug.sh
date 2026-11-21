#!/usr/bin/env bash
# Snapshot compositor + shell state when focus/input breaks. Bound to CTRL+SUPER+ALT+D.
# Works from the keyboard alone (Hyprland handles the bind), so run it WHILE windows are
# unclickable, then press CTRL+SUPER+ALT+R (restart the shell) and note whether that fixes it.
set -u
out=~/.local/state/hypr-debug/$(date +%Y%m%d_%H%M%S)
mkdir -p "$out"
{
	echo "## activewindow";    hyprctl -j activewindow
	echo "## activeworkspace"; hyprctl -j activeworkspace
	echo "## monitors";        hyprctl -j monitors
	echo "## layers";          hyprctl -j layers
	echo "## clients";         hyprctl -j clients
	echo "## binds (submap)";  hyprctl -j binds | head -c 4000
	echo "## cursorpos";       hyprctl cursorpos
	echo "## devices";         hyprctl -j devices | head -c 6000
} > "$out/hyprctl.json" 2>&1
pgrep -a -f 'slurp|tofi|hyprpicker|swappy|gpu-screen-recorder|ydotool|wl-paste|voxd' > "$out/grabbers.txt" 2>&1
timeout 3 noctalia msg log-level-status > "$out/noctalia-msg.txt" 2>&1 || echo "noctalia msg TIMED OUT (shell event loop hung?)" >> "$out/noctalia-msg.txt"
tail -n 400 ~/.cache/noctalia/noctalia.log > "$out/noctalia-log.txt" 2>&1
tail -n 600 "${XDG_RUNTIME_DIR:-/run/user/$UID}"/hypr/*/hyprland.log > "$out/hyprland-log-tail.txt" 2>&1
notify-send "Focus debug captured" "$out" 2>/dev/null || true
echo "$out"
