#!/bin/bash
# Project picker (SUPER+O): open a terminal in a project folder.
# Order: folders you open most, then projects (newest first), then folders
# synced with the laptop, then ~/.config (both alphabetical).

# Every folder inside these is a project.
roots=(~/PSO ~/Projects)
# Single project folders elsewhere.
projects=(
	~/aquarist ~/assistant ~/copilot ~/drone ~/la_pavoni
	~/learn ~/nixos-configuration ~/qmk_firmware ~/sprinklers
	~/.config/chocofi ~/notes ~/health
)
# Syncthing folders shared with this device are listed too (read live from its config).
sync_device="Laptop"
sync_config=~/.local/state/syncthing/config.xml

synced() {
	[[ -r $sync_config ]] || return
	python3 -I - "$sync_config" "$sync_device" <<'PY'
import os, sys, xml.etree.ElementTree as ET
root = ET.parse(sys.argv[1]).getroot()
dev = {d.get("name"): d.get("id") for d in root.findall("device")}.get(sys.argv[2])
home = os.path.expanduser("~")
for f in root.findall("folder"):
    if dev not in {d.get("id") for d in f.findall("device")}:
        continue
    p = os.path.expanduser(f.get("path")).rstrip("/")
    # /mnt/data/X is bind-mounted at ~/X: prefer the home path when it's the same folder.
    alt = os.path.join(home, os.path.basename(p))
    try:
        if os.path.samefile(p, alt):
            p = alt
    except OSError:
        pass
    if os.path.isdir(p):
        print(p)
PY
}

tidy() { sed "s|^$HOME|~|"; }
mapfile -t dirs < <(
	{
		{
			find "${roots[@]}" -mindepth 1 -maxdepth 1 -type d ! -name '.*' -printf '%T@\t%p\n'
			find "${projects[@]}" -maxdepth 0 -type d -printf '%T@\t%p\n'
		} 2>/dev/null | sort -rn | cut -f2-
		synced | sort -f
		find ~/.config -mindepth 1 -maxdepth 1 -type d ! -name '.*' | sort -f
	} | tidy | awk '!seen[$0]++'
)
((${#dirs[@]})) || exit 0

choice=$(printf '%s\n' "${dirs[@]}" | tofi --prompt-text "  " \
	--history-file "${XDG_STATE_HOME:-$HOME/.local/state}/tofi-projects-history") || exit 0
dir=${choice/#\~/$HOME}
[[ -d $dir ]] && setsid -f foot -D "$dir" >/dev/null 2>&1
