-- Keybinds.
--
-- The legacy `submap = global` block is dropped (it was a no-op holdover).
--
-- All binds use native hl.dsp.* dispatchers. The legacy string form
-- `hyprctl dispatch <name> <args>` does NOT work under a Lua config: Hyprland
-- evaluates the argument as a Lua expression (`hl.dispatch(<arg>)`), so e.g.
-- `hyprctl dispatch fullscreen 0` is a Lua syntax error that silently no-ops.
-- Window-state actions therefore call hl.dsp.window.* / hl.dsp.group.* directly.

local v = require("variables")

----------------------------------------------------------------------
-- Helpers / flag presets
----------------------------------------------------------------------

-- Send a command to the running Noctalia shell (see `noctalia msg --help`).
local function noctalia(cmd)
	return hl.dsp.exec_cmd("noctalia msg " .. cmd)
end

-- resize/move "exact" used to take percentages; native hl.dsp.window.resize/move
-- take absolute pixel numbers (no "%" strings), so derive them from the active
-- monitor's logical size.
local function active_logical_size()
	local m = hl.get_active_monitor()
	if not m then
		return nil
	end
	return m.width / m.scale, m.height / m.scale
end

local function resize_pct(fw, fh)
	return function()
		local w, h = active_logical_size()
		if w then
			hl.dispatch(hl.dsp.window.resize({ x = math.floor(w * fw), y = math.floor(h * fh), relative = false }))
		end
	end
end

local function move_pct(fx, fy)
	return function()
		local w, h = active_logical_size()
		if w then
			hl.dispatch(hl.dsp.window.move({ x = math.floor(w * fx), y = math.floor(h * fy), relative = false }))
		end
	end
end

local LOCKED = { locked = true }
local LOCKED_REPEAT = { locked = true, repeating = true }
local REPEAT = { repeating = true }
local RELEASE = { release = true }
local MOUSE = { mouse = true }

-- Bind options with a label for the SUPER+H cheat sheet: desc("Volume up", LOCKED)
local function desc(text, opts)
	local t = { desc = text }
	for k, x in pairs(opts or {}) do
		t[k] = x
	end
	return t
end

----------------------------------------------------------------------
-- Shell (Noctalia)
----------------------------------------------------------------------

hl.bind("SUPER + L", noctalia("panel-toggle launcher"), desc("App launcher"))
-- Curated action menu (power, Wi-Fi, toggles...); edit the list in the script.
hl.bind("SUPER + T", hl.dsp.exec_cmd([[pkill tofi || ~/.config/hypr/scripts/tofi-menu.sh]]), desc("Action menu: power, Wi-Fi, toggles (tofi)"))

hl.bind(v.keys.session, noctalia("panel-toggle session"), desc("Session menu: power off, reboot, lock"))
hl.bind(v.keys.clearNotifs, noctalia("notification-clear-history"), LOCKED)
hl.bind(v.keys.showPanels, noctalia("panel-toggle control-center"))
hl.bind("SUPER + C", noctalia("panel-toggle control-center"))
hl.bind("ALT + W", noctalia("panel-toggle wallpaper"))
-- Pin the bar visible / return it to show-on-hover
hl.bind("SUPER + B", hl.dsp.exec_cmd([[bash -c '~/.config/hypr/scripts/bar-toggle.sh']]), desc("Pin/unpin the bar"))

local media = {
	{ "XF86MonBrightnessUp", "brightness-up" },
	{ "XF86MonBrightnessDown", "brightness-down" },
	{ "CTRL + SUPER + Space", "media toggle" },
	{ "XF86AudioPlay", "media toggle" },
	{ "XF86AudioPause", "media toggle" },
	{ "CTRL + SUPER + Equal", "media next" },
	{ "XF86AudioNext", "media next" },
	{ "CTRL + SUPER + Minus", "media previous" },
	{ "XF86AudioPrev", "media previous" },
	{ "XF86AudioStop", "media stop" },
}
for _, m in ipairs(media) do
	hl.bind(m[1], noctalia(m[2]), LOCKED)
end

-- Kill/restart the shell
hl.bind("CTRL + SUPER + SHIFT + R", hl.dsp.exec_cmd("pkill -x noctalia"), desc("Kill Noctalia shell", RELEASE))
hl.bind("CTRL + SUPER + ALT + R", hl.dsp.exec_cmd("pkill -x noctalia; noctalia"), desc("Restart Noctalia shell", RELEASE))

----------------------------------------------------------------------
-- Workspaces (inlined wsaction.fish group-math, no subprocess)
--   nth_in_group: the Nth workspace within the current group of 10
--   nth_group:    group N, keeping the same position within the group
----------------------------------------------------------------------

local function active_id()
	return hl.get_active_workspace().id
end
local function nth_in_group(n)
	return math.floor((active_id() - 1) / 10) * 10 + n
end
local function nth_group(n)
	return (n - 1) * 10 + (active_id() % 10)
end

for n = 1, 10 do
	local key = n % 10 -- 10 -> "0"
	hl.bind(v.mods.goToWs .. " + " .. key, function()
		hl.dispatch(hl.dsp.focus({ workspace = nth_in_group(n) }))
	end, desc("Go to workspace " .. n .. " (this group)"))
	hl.bind(v.mods.goToWsGroup .. " + " .. key, function()
		hl.dispatch(hl.dsp.focus({ workspace = nth_group(n) }))
	end, desc("Go to workspace group " .. n))
	hl.bind(v.mods.moveToWs .. " + " .. key, function()
		hl.dispatch(hl.dsp.window.move({ workspace = nth_in_group(n) }))
	end, desc("Move window to workspace " .. n .. " (this group)"))
	hl.bind(v.mods.moveToWsGroup .. " + " .. key, function()
		hl.dispatch(hl.dsp.window.move({ workspace = nth_group(n) }))
	end, desc("Move window to workspace group " .. n))
end

-- Go to workspace -1/+1
hl.bind("SUPER + mouse_down", hl.dsp.focus({ workspace = "-1" }))
hl.bind("SUPER + mouse_up", hl.dsp.focus({ workspace = "+1" }))
hl.bind(v.keys.prevWs, hl.dsp.focus({ workspace = "-1" }), REPEAT)
hl.bind(v.keys.nextWs, hl.dsp.focus({ workspace = "+1" }), REPEAT)
hl.bind("SUPER + Page_Up", hl.dsp.focus({ workspace = "-1" }), REPEAT)
hl.bind("SUPER + Page_Down", hl.dsp.focus({ workspace = "+1" }), REPEAT)
-- Go to workspace group -1/+1
hl.bind("CTRL + SUPER + mouse_down", hl.dsp.focus({ workspace = "-10" }))
hl.bind("CTRL + SUPER + mouse_up", hl.dsp.focus({ workspace = "+10" }))
-- Toggle special workspace
hl.bind(v.keys.toggleSpecialWs, hl.dsp.workspace.toggle_special("special"))

-- Move window to workspace -1/+1
hl.bind("SUPER + ALT + Page_Up", hl.dsp.window.move({ workspace = "-1" }), REPEAT)
hl.bind("SUPER + ALT + Page_Down", hl.dsp.window.move({ workspace = "+1" }), REPEAT)
hl.bind("SUPER + ALT + mouse_down", hl.dsp.window.move({ workspace = "-1" }))
hl.bind("SUPER + ALT + mouse_up", hl.dsp.window.move({ workspace = "+1" }))
hl.bind("CTRL + SUPER + SHIFT + right", hl.dsp.window.move({ workspace = "+1" }), REPEAT)
hl.bind("CTRL + SUPER + SHIFT + left", hl.dsp.window.move({ workspace = "-1" }), REPEAT)
-- Move window to/from special workspace
hl.bind("CTRL + SUPER + SHIFT + up", hl.dsp.window.move({ workspace = "special:special" }))
hl.bind("CTRL + SUPER + SHIFT + down", hl.dsp.window.move({ workspace = "e+0" }), desc("Move window out of special workspace"))
hl.bind("SUPER + ALT + S", hl.dsp.window.move({ workspace = "special:special" }))

----------------------------------------------------------------------
-- Window groups
----------------------------------------------------------------------

-- ALT+Tab / SHIFT+ALT+Tab window cycle
hl.bind(v.keys.windowGroupCycleNext, hl.dsp.window.cycle_next(), REPEAT)
hl.bind(v.keys.windowGroupCyclePrev, hl.dsp.window.cycle_next({ next = false }), desc("Cycle windows (reverse)", REPEAT))
hl.bind("CTRL + ALT + Tab", hl.dsp.group.next(), REPEAT)
hl.bind("CTRL + SHIFT + ALT + Tab", hl.dsp.group.prev(), REPEAT)
hl.bind(v.keys.toggleGroup, hl.dsp.group.toggle())
hl.bind(v.keys.ungroup, hl.dsp.window.move({ out_of_group = true }), desc("Remove window from group"))
hl.bind("SUPER + SHIFT + Comma", hl.dsp.group.lock({ action = "toggle" }))

----------------------------------------------------------------------
-- Window focus / move (directional)
----------------------------------------------------------------------

local dirs = {
	left = "left",
	right = "right",
	up = "up",
	down = "down",
	h = "left",
	l = "right",
	k = "up",
	j = "down",
}
for key, dir in pairs(dirs) do
	hl.bind("ALT + " .. key, hl.dsp.focus({ direction = dir }))
	hl.bind("ALT + SHIFT + " .. key, hl.dsp.window.move({ direction = dir }))
end

-- Mouse drag/resize
hl.bind("ALT + mouse:272", hl.dsp.window.drag(), MOUSE)
hl.bind(v.keys.moveWindow, hl.dsp.window.drag(), MOUSE)
hl.bind("ALT + mouse:273", hl.dsp.window.resize(), MOUSE)
hl.bind(v.keys.resizeWindow, hl.dsp.window.resize(), MOUSE)

----------------------------------------------------------------------
-- Window actions
----------------------------------------------------------------------

hl.bind("CTRL + SUPER + Backslash", hl.dsp.window.center())
hl.bind("CTRL + SUPER + ALT + Backslash", resize_pct(0.55, 0.70), desc("Resize window to 55% x 70% and center"))
hl.bind("CTRL + SUPER + ALT + Backslash", hl.dsp.window.center())

-- Picture-in-picture macro (4 dispatches on one key)
hl.bind(v.keys.windowPip, hl.dsp.window.float({ action = "toggle" }), desc("Picture-in-picture (float, shrink, corner, pin)"))
hl.bind(v.keys.windowPip, resize_pct(0.25, 0.25))
hl.bind(v.keys.windowPip, move_pct(0.73, 0.73))
hl.bind(v.keys.windowPip, hl.dsp.window.pin())

hl.bind(v.keys.pinWindow, hl.dsp.window.pin())
hl.bind(v.keys.windowFullscreen, hl.dsp.window.fullscreen({ mode = "fullscreen" }))
hl.bind(v.keys.windowBorderedFullscreen, hl.dsp.window.fullscreen({ mode = "maximized" }))
hl.bind(v.keys.toggleWindowFloating, hl.dsp.window.float({ action = "toggle" }))
hl.bind(v.keys.closeWindow, hl.dsp.window.close())

----------------------------------------------------------------------
-- Special workspace toggles
----------------------------------------------------------------------

hl.bind(v.keys.systemMonitor, hl.dsp.workspace.toggle_special("sysmon"))
hl.bind(v.keys.music, hl.dsp.workspace.toggle_special("music"))
hl.bind(v.keys.communication, hl.dsp.workspace.toggle_special("communication"))

----------------------------------------------------------------------
-- App launchers
----------------------------------------------------------------------

hl.bind(v.keys.terminal, hl.dsp.exec_cmd(v.apps.terminal))
hl.bind(v.keys.browser, hl.dsp.exec_cmd(v.apps.browser))
hl.bind(v.keys.notes, hl.dsp.exec_cmd(v.apps.notes))
hl.bind(v.keys.chrome, hl.dsp.exec_cmd(v.apps.chrome))
hl.bind(v.keys.editor, hl.dsp.exec_cmd(v.apps.editor))
hl.bind("SUPER + G", hl.dsp.exec_cmd("github-desktop"))
hl.bind(v.keys.fileExplorer, hl.dsp.exec_cmd(v.apps.fileExplorer))
hl.bind("SUPER + ALT + E", hl.dsp.exec_cmd("nemo"))
hl.bind("CTRL + ALT + Escape", hl.dsp.exec_cmd("qps"))
hl.bind("CTRL + ALT + V", hl.dsp.exec_cmd("pavucontrol"))

----------------------------------------------------------------------
-- Utilities: screenshots, recording, picker, voice, wallpaper
----------------------------------------------------------------------

hl.bind("Print", hl.dsp.exec_cmd("grim - | wl-copy"), desc("Screenshot full screen to clipboard", LOCKED)) -- full screen -> clipboard
-- Region -> clipboard
hl.bind(
	"SUPER + SHIFT + S",
	hl.dsp.exec_cmd(
		[[bash -c 'f=$(mktemp /tmp/screenshot-XXXXX.png) && grim -g "$(slurp)" "$f" && wl-copy < "$f" && notify-send -i "$f" "Screenshot" "Copied to clipboard"']]
	), desc("Screenshot region to clipboard")
)
-- Region -> file
hl.bind(
	"SUPER + SHIFT + ALT + S",
	hl.dsp.exec_cmd(
		[[bash -c 'f=~/Pictures/Screenshots/$(date +%Y%m%d_%H%M%S).png && grim -g "$(slurp)" "$f" && notify-send -i "$f" "Screenshot" "Saved to $f"']]
	), desc("Screenshot region to ~/Pictures/Screenshots")
)
-- Region -> swappy (annotate); annotated image is written on exit
hl.bind(
	"SUPER + SHIFT + E",
	hl.dsp.exec_cmd(
		[[bash -c 'f=~/Pictures/Screenshots/swappy-$(date +%Y%m%d_%H%M%S).png && grim -g "$(slurp)" - | swappy -f - -o "$f"']]
	), desc("Screenshot region and annotate (swappy)")
)

-- Screen recording into ~/Videos; press the same keys again to stop
hl.bind("SUPER + ALT + R", hl.dsp.exec_cmd([[bash -c '~/.config/hypr/scripts/screen-record.sh audio']]), desc("Screen record with audio (press again to stop)"))
hl.bind("CTRL + ALT + R", hl.dsp.exec_cmd([[bash -c '~/.config/hypr/scripts/screen-record.sh silent']]), desc("Screen record, no audio (press again to stop)"))
hl.bind("SUPER + SHIFT + ALT + R", hl.dsp.exec_cmd([[bash -c '~/.config/hypr/scripts/screen-record.sh region']]), desc("Screen record a region (press again to stop)"))
hl.bind("SUPER + SHIFT + C", hl.dsp.exec_cmd("hyprpicker -a"), desc("Color picker (copies hex)"))

-- Voice notes (voxd) — the bash -c wrapper MUST stay (removing it breaks the keybind).
-- voxd-record.sh toggles recording exactly like `voxd --trigger-record`, and also
-- auto-resumes any media that paused itself while the mic was open.
hl.bind("CTRL + SHIFT + ALT + V", hl.dsp.exec_cmd([[bash -c '~/.config/hypr/scripts/voxd-record.sh']]), desc("Voice note start/stop (voxd), then type last clipboard entry"))
hl.bind("SHIFT + ALT + SUPER + f13", hl.dsp.exec_cmd([[bash -c '~/.config/hypr/scripts/voxd-record.sh']]), desc("Voice note start/stop (voxd)"))
hl.bind("SHIFT + ALT + SUPER + f14", hl.dsp.exec_cmd([[bash -c '~/.config/hypr/scripts/voxd-record.sh']]), desc("Voice note start/stop (voxd)"))
-- Laptop push-to-talk: hold Super+Space to record, release to transcribe/type.
hl.bind("SUPER + Space", hl.dsp.exec_cmd([[bash -c '~/.config/hypr/scripts/voxd-record.sh --start']]), desc("Push-to-talk voice note (hold)"))
hl.bind("SUPER + Space", hl.dsp.exec_cmd([[bash -c '~/.config/hypr/scripts/voxd-record.sh --stop']]), RELEASE)

----------------------------------------------------------------------
-- Volume
----------------------------------------------------------------------

hl.bind("XF86AudioMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), desc("Mute/unmute audio", LOCKED))
hl.bind("SUPER + SHIFT + M", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), desc("Mute/unmute audio", LOCKED))
hl.bind(
	"XF86AudioRaiseVolume",
	hl.dsp.exec_cmd(
		"wpctl set-mute @DEFAULT_AUDIO_SINK@ 0; wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ " .. v.volumeStep .. "%+"
	),
	desc("Volume up", LOCKED_REPEAT)
)
hl.bind(
	"XF86AudioLowerVolume",
	hl.dsp.exec_cmd(
		"wpctl set-mute @DEFAULT_AUDIO_SINK@ 0; wpctl set-volume @DEFAULT_AUDIO_SINK@ " .. v.volumeStep .. "%-"
	),
	desc("Volume down", LOCKED_REPEAT)
)

----------------------------------------------------------------------
-- Lock/sleep + clipboard/emoji
----------------------------------------------------------------------

hl.bind("SUPER + ALT + L", noctalia("session lock"))
-- Lock first and let the lock screen finish drawing before suspending.
-- Noctalia's own lock-before-suspend releases the sleep inhibitor as soon as
-- the session reports locked, while its enter transition may still be running;
-- a frame frozen mid-transition shows the desktop on resume. See also
-- ~/.config/noctalia/lockscreen.toml.
hl.bind("SUPER + SHIFT + L", hl.dsp.exec_cmd("noctalia msg session lock; sleep 0.5; systemctl suspend-then-hibernate"), desc("Lock and suspend"))

hl.bind(
	"SUPER + V",
	hl.dsp.exec_cmd(
		[[pkill tofi || cliphist list | sed 's/\t/  /g' | tofi | sed 's/^\([0-9]\+\).*/\1\t/' | cliphist decode | wl-copy]]
	), desc("Clipboard history: paste")
)
hl.bind(
	"SUPER + ALT + V",
	hl.dsp.exec_cmd(
		[[pkill tofi || cliphist list | sed 's/\t/  /g' | tofi | sed 's/^\([0-9]\+\).*/\1\t/' | cliphist delete]]
	), desc("Clipboard history: delete an entry")
)
hl.bind("SUPER + Period", hl.dsp.exec_cmd([[pkill tofi || BEMOJI_PICKER_CMD="tofi" bemoji -t]]), desc("Emoji picker"))

-- tofi pickers (scripts/tofi-*.sh)
hl.bind("SUPER + W", hl.dsp.exec_cmd([[pkill tofi || ~/.config/hypr/scripts/tofi-windows.sh]]), desc("Window switcher"))
hl.bind("SUPER + ALT + B", hl.dsp.exec_cmd([[pkill tofi || ~/.config/hypr/scripts/tofi-bluetooth.sh]]), desc("Bluetooth: connect/disconnect a device"))
hl.bind("SUPER + O", hl.dsp.exec_cmd([[pkill tofi || ~/.config/hypr/scripts/tofi-projects.sh]]), desc("Open a terminal in a project folder"))
hl.bind("SUPER + H", hl.dsp.exec_cmd([[pkill tofi || ~/.config/hypr/scripts/tofi-keybinds.sh]]), desc("Keybind cheat sheet (search and run)"))
-- Alternate paste (same key as voxd voice note above — intentional dual bind)
hl.bind(
	"CTRL + SHIFT + ALT + V",
	hl.dsp.exec_cmd([[sleep 0.5s && ydotool type -d 1 "$(cliphist list | head -1 | cliphist decode)"]]),
	LOCKED
)

----------------------------------------------------------------------
-- Testing
----------------------------------------------------------------------

-- Snapshot focus/layer/shell state while windows are unclickable (see scripts/focus-debug.sh)
hl.bind("CTRL + SUPER + ALT + D", hl.dsp.exec_cmd([[bash -c '~/.config/hypr/scripts/focus-debug.sh']]), desc("Snapshot focus state for debugging", LOCKED))

hl.bind(
	"SUPER + ALT + f12",
	hl.dsp.exec_cmd(
		[[notify-send -u low -i dialog-information-symbolic 'Test notification' "Here's a really long message to test truncation and wrapping\nYou can middle click or flick this notification to dismiss it!" -a 'Shell' -A "Test1=I got it!" -A "Test2=Another action"]]
	),
	desc("Send a test notification", LOCKED)
)
