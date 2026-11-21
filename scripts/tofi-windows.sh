#!/bin/bash
# Window switcher (SUPER+W): pick an open window and jump to it.
# Listed most-recently-used first, so Enter right away = previous window.
# The current window is moved to the bottom.

mapfile -t rows < <(hyprctl clients -j | jq -r '
	map(select(.mapped))
	| (map(select(.focusHistoryID != 0)) | sort_by(.focusHistoryID)) + map(select(.focusHistoryID == 0))
	| .[] | [.address, "[\(.workspace.name)]  \(.class)  ·  \(.title)"] | @tsv')
((${#rows[@]})) || exit 0

choice=$(printf '%s\n' "${rows[@]#*$'\t'}" | tofi --prompt-text "  ") || exit 0

for r in "${rows[@]}"; do
	if [[ ${r#*$'\t'} == "$choice" ]]; then
		hyprctl dispatch "hl.dsp.focus({window=\"address:${r%%$'\t'*}\"})" >/dev/null
		exit 0
	fi
done
