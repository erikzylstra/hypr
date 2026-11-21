#!/bin/bash
# Toggle the Noctalia bar between pinned-visible and auto-hide (show on hover).
# Noctalia has no auto-hide toggle and doesn't expose the runtime state, so
# track it here, keyed to the shell's PID: a restarted shell is back to
# auto-hide (bar.toml), which makes a stale flag read as "not pinned".
flag="${XDG_RUNTIME_DIR:-/tmp}/noctalia-bar-pinned"
pid=$(pgrep -x noctalia | head -n1)

if [[ -n $pid && $(cat "$flag" 2>/dev/null) == "$pid" ]]; then
	noctalia msg bar-auto-hide-set on && rm -f "$flag"
else
	noctalia msg bar-auto-hide-set off && echo "$pid" > "$flag"
fi
