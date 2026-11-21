#!/bin/bash
# Toggle the Noctalia bar between pinned-visible and auto-hide (show on hover).
# Pinned also reserves the bar's space so windows tile below it; auto-hide
# overlays windows (bar.toml has reserve_space = false).
# Noctalia has no auto-hide or reserve getters, so track the state here, keyed
# to the shell's PID: a restarted shell is back to bar.toml's settings, which
# makes a stale flag read as "not pinned".
flag="${XDG_RUNTIME_DIR:-/tmp}/noctalia-bar-pinned"
pid=$(pgrep -x noctalia | head -n1)

# Order the steps so the bar never overlaps a window mid-resize: when pinning,
# open the gap first and let the bar appear in it; when unpinning, let the bar
# finish its slide-out animation before the windows grow into its space.
if [[ -n $pid && $(cat "$flag" 2>/dev/null) == "$pid" ]]; then
	noctalia msg bar-auto-hide-set on && sleep 0.2 && noctalia msg bar-reserve-toggle && rm -f "$flag"
else
	noctalia msg bar-reserve-toggle && noctalia msg bar-auto-hide-set off && echo "$pid" > "$flag"
fi
