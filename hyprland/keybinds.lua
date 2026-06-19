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

local function caelestia(name) return hl.dsp.global("caelestia:" .. name) end

-- resize/move "exact" used to take percentages; native hl.dsp.window.resize/move
-- take absolute pixel numbers (no "%" strings), so derive them from the active
-- monitor's logical size.
local function active_logical_size()
    local m = hl.get_active_monitor()
    if not m then return nil end
    return m.width / m.scale, m.height / m.scale
end

local function resize_pct(fw, fh)
    return function()
        local w, h = active_logical_size()
        if w then hl.dispatch(hl.dsp.window.resize(
            { x = math.floor(w * fw), y = math.floor(h * fh), relative = false })) end
    end
end

local function move_pct(fx, fy)
    return function()
        local w, h = active_logical_size()
        if w then hl.dispatch(hl.dsp.window.move(
            { x = math.floor(w * fx), y = math.floor(h * fy), relative = false })) end
    end
end

local LOCKED        = { locked = true }
local LOCKED_REPEAT = { locked = true, repeating = true }
local REPEAT        = { repeating = true }
local RELEASE       = { release = true }
local MOUSE         = { mouse = true }
local INTERRUPT     = { ignore_mods = true, non_consuming = true } -- was `bindin`

----------------------------------------------------------------------
-- Shell: launcher + launcher-interrupt
----------------------------------------------------------------------

hl.bind("SUPER + L", caelestia("launcher"))

-- While the launcher is open, any of these (with SUPER held) interrupt it
-- without being consumed. The literal `catchall` key (match any key) is only
-- allowed inside a submap, so it lives in a one-bind submap marked
-- submap_universal so it stays active in the default map too.
hl.define_submap("launcher-interrupt", function()
    hl.bind("SUPER", caelestia("launcherInterrupt"),
        { ignore_mods = true, non_consuming = true, submap_universal = true })
end)

local interrupt_keys = {
    "mouse:272", "mouse:273", "mouse:274", "mouse:275", "mouse:276", "mouse:277",
    "mouse_up", "mouse_down",
}
for _, k in ipairs(interrupt_keys) do
    hl.bind("SUPER + " .. k, caelestia("launcherInterrupt"), INTERRUPT)
end

hl.bind("SUPER + T", hl.dsp.exec_cmd(
    [[tofi-run | xargs -r -I{} hyprctl dispatch 'hl.dsp.exec_cmd("{}")']]))

----------------------------------------------------------------------
-- Shell: misc + media (caelestia globals)
----------------------------------------------------------------------

hl.bind(v.keys.session, caelestia("session"))
hl.bind(v.keys.clearNotifs, caelestia("clearNotifs"), LOCKED)
hl.bind(v.keys.showPanels, caelestia("showall"))
hl.bind("SUPER + C", caelestia("calendarPopup"))

local media = {
    { "XF86MonBrightnessUp",   "brightnessUp" },
    { "XF86MonBrightnessDown", "brightnessDown" },
    { "CTRL + SUPER + Space",  "mediaToggle" },
    { "XF86AudioPlay",         "mediaToggle" },
    { "XF86AudioPause",        "mediaToggle" },
    { "CTRL + SUPER + Equal",  "mediaNext" },
    { "XF86AudioNext",         "mediaNext" },
    { "CTRL + SUPER + Minus",  "mediaPrev" },
    { "XF86AudioPrev",         "mediaPrev" },
    { "XF86AudioStop",         "mediaStop" },
}
for _, m in ipairs(media) do
    hl.bind(m[1], caelestia(m[2]), LOCKED)
end

-- Kill/restart quickshell
hl.bind("CTRL + SUPER + SHIFT + R", hl.dsp.exec_cmd("qs kill"), RELEASE)
hl.bind("CTRL + SUPER + ALT + R", hl.dsp.exec_cmd("qs kill; qs -d"), RELEASE)

----------------------------------------------------------------------
-- Workspaces (inlined wsaction.fish group-math, no subprocess)
--   nth_in_group: the Nth workspace within the current group of 10
--   nth_group:    group N, keeping the same position within the group
----------------------------------------------------------------------

local function active_id() return hl.get_active_workspace().id end
local function nth_in_group(n) return math.floor((active_id() - 1) / 10) * 10 + n end
local function nth_group(n) return (n - 1) * 10 + (active_id() % 10) end

for n = 1, 10 do
    local key = n % 10 -- 10 -> "0"
    hl.bind(v.mods.goToWs .. " + " .. key,
        function() hl.dispatch(hl.dsp.focus({ workspace = nth_in_group(n) })) end)
    hl.bind(v.mods.goToWsGroup .. " + " .. key,
        function() hl.dispatch(hl.dsp.focus({ workspace = nth_group(n) })) end)
    hl.bind(v.mods.moveToWs .. " + " .. key,
        function() hl.dispatch(hl.dsp.window.move({ workspace = nth_in_group(n) })) end)
    hl.bind(v.mods.moveToWsGroup .. " + " .. key,
        function() hl.dispatch(hl.dsp.window.move({ workspace = nth_group(n) })) end)
end

-- Go to workspace -1/+1
hl.bind("SUPER + mouse_down", hl.dsp.focus({ workspace = "-1" }))
hl.bind("SUPER + mouse_up",   hl.dsp.focus({ workspace = "+1" }))
hl.bind(v.keys.prevWs,        hl.dsp.focus({ workspace = "-1" }), REPEAT)
hl.bind(v.keys.nextWs,        hl.dsp.focus({ workspace = "+1" }), REPEAT)
hl.bind("SUPER + Page_Up",    hl.dsp.focus({ workspace = "-1" }), REPEAT)
hl.bind("SUPER + Page_Down",  hl.dsp.focus({ workspace = "+1" }), REPEAT)
-- Go to workspace group -1/+1
hl.bind("CTRL + SUPER + mouse_down", hl.dsp.focus({ workspace = "-10" }))
hl.bind("CTRL + SUPER + mouse_up",   hl.dsp.focus({ workspace = "+10" }))
-- Toggle special workspace
hl.bind(v.keys.toggleSpecialWs, hl.dsp.workspace.toggle_special("special"))

-- Move window to workspace -1/+1
hl.bind("SUPER + ALT + Page_Up",   hl.dsp.window.move({ workspace = "-1" }), REPEAT)
hl.bind("SUPER + ALT + Page_Down", hl.dsp.window.move({ workspace = "+1" }), REPEAT)
hl.bind("SUPER + ALT + mouse_down", hl.dsp.window.move({ workspace = "-1" }))
hl.bind("SUPER + ALT + mouse_up",   hl.dsp.window.move({ workspace = "+1" }))
hl.bind("CTRL + SUPER + SHIFT + right", hl.dsp.window.move({ workspace = "+1" }), REPEAT)
hl.bind("CTRL + SUPER + SHIFT + left",  hl.dsp.window.move({ workspace = "-1" }), REPEAT)
-- Move window to/from special workspace
hl.bind("CTRL + SUPER + SHIFT + up",   hl.dsp.window.move({ workspace = "special:special" }))
hl.bind("CTRL + SUPER + SHIFT + down", hl.dsp.window.move({ workspace = "e+0" }))
hl.bind("SUPER + ALT + S",             hl.dsp.window.move({ workspace = "special:special" }))

----------------------------------------------------------------------
-- Window groups
----------------------------------------------------------------------

-- ALT+Tab / SHIFT+ALT+Tab window cycle
hl.bind(v.keys.windowGroupCycleNext, hl.dsp.window.cycle_next(), REPEAT)
hl.bind(v.keys.windowGroupCyclePrev, hl.dsp.window.cycle_next({ next = false }), REPEAT)
hl.bind("CTRL + ALT + Tab",       hl.dsp.group.next(), REPEAT)
hl.bind("CTRL + SHIFT + ALT + Tab", hl.dsp.group.prev(), REPEAT)
hl.bind(v.keys.toggleGroup, hl.dsp.group.toggle())
hl.bind(v.keys.ungroup,     hl.dsp.window.move({ out_of_group = true }))
hl.bind("SUPER + SHIFT + Comma", hl.dsp.group.lock_active({ action = "toggle" }))

----------------------------------------------------------------------
-- Window focus / move (directional)
----------------------------------------------------------------------

local dirs = {
    left = "left", right = "right", up = "up", down = "down",
    h = "left", l = "right", k = "up", j = "down",
}
for key, dir in pairs(dirs) do
    hl.bind("ALT + " .. key,         hl.dsp.focus({ direction = dir }))
    hl.bind("ALT + SHIFT + " .. key, hl.dsp.window.move({ direction = dir }))
end

-- Mouse drag/resize
hl.bind("ALT + mouse:272", hl.dsp.window.drag(),   MOUSE)
hl.bind(v.keys.moveWindow, hl.dsp.window.drag(),   MOUSE)
hl.bind("ALT + mouse:273", hl.dsp.window.resize(), MOUSE)
hl.bind(v.keys.resizeWindow, hl.dsp.window.resize(), MOUSE)

----------------------------------------------------------------------
-- Window actions
----------------------------------------------------------------------

hl.bind("CTRL + SUPER + Backslash",       hl.dsp.window.center())
hl.bind("CTRL + SUPER + ALT + Backslash", resize_pct(0.55, 0.70))
hl.bind("CTRL + SUPER + ALT + Backslash", hl.dsp.window.center())

-- Picture-in-picture macro (4 dispatches on one key)
hl.bind(v.keys.windowPip, hl.dsp.window.float({ action = "toggle" }))
hl.bind(v.keys.windowPip, resize_pct(0.25, 0.25))
hl.bind(v.keys.windowPip, move_pct(0.73, 0.73))
hl.bind(v.keys.windowPip, hl.dsp.window.pin())

hl.bind(v.keys.pinWindow,                hl.dsp.window.pin())
hl.bind(v.keys.windowFullscreen,         hl.dsp.window.fullscreen({ mode = "fullscreen" }))
hl.bind(v.keys.windowBorderedFullscreen, hl.dsp.window.fullscreen({ mode = "maximized" }))
hl.bind(v.keys.toggleWindowFloating,     hl.dsp.window.float({ action = "toggle" }))
hl.bind(v.keys.closeWindow,              hl.dsp.window.close())

----------------------------------------------------------------------
-- Special workspace toggles
----------------------------------------------------------------------

hl.bind(v.keys.systemMonitor, hl.dsp.workspace.toggle_special("sysmon"))
hl.bind(v.keys.music,         hl.dsp.workspace.toggle_special("music"))
hl.bind(v.keys.communication, hl.dsp.workspace.toggle_special("communication"))

----------------------------------------------------------------------
-- App launchers
----------------------------------------------------------------------

hl.bind(v.keys.terminal,     hl.dsp.exec_cmd(v.apps.terminal))
hl.bind(v.keys.browser,      hl.dsp.exec_cmd(v.apps.browser))
hl.bind(v.keys.notes,        hl.dsp.exec_cmd(v.apps.notes))
hl.bind(v.keys.chrome,       hl.dsp.exec_cmd(v.apps.chrome))
hl.bind(v.keys.editor,       hl.dsp.exec_cmd(v.apps.editor))
hl.bind("SUPER + G",         hl.dsp.exec_cmd("github-desktop"))
hl.bind(v.keys.fileExplorer, hl.dsp.exec_cmd(v.apps.fileExplorer))
hl.bind("SUPER + ALT + E",   hl.dsp.exec_cmd("nemo"))
hl.bind("CTRL + ALT + Escape", hl.dsp.exec_cmd("qps"))
hl.bind("CTRL + ALT + V",    hl.dsp.exec_cmd("pavucontrol"))

----------------------------------------------------------------------
-- Utilities: screenshots, recording, picker, voice, wallpaper
----------------------------------------------------------------------

hl.bind("Print", hl.dsp.exec_cmd("grim - | wl-copy"), LOCKED) -- full screen -> clipboard
-- Region -> clipboard
hl.bind("SUPER + SHIFT + S", hl.dsp.exec_cmd(
    [[bash -c 'f=$(mktemp /tmp/screenshot-XXXXX.png) && grim -g "$(slurp)" "$f" && wl-copy < "$f" && notify-send -i "$f" "Screenshot" "Copied to clipboard"']]))
-- Region -> file
hl.bind("SUPER + SHIFT + ALT + S", hl.dsp.exec_cmd(
    [[bash -c 'f=~/Pictures/Screenshots/$(date +%Y%m%d_%H%M%S).png && grim -g "$(slurp)" "$f" && notify-send -i "$f" "Screenshot" "Saved to $f"']]))
-- Region -> swappy (annotate); annotated image is written on exit
hl.bind("SUPER + SHIFT + E", hl.dsp.exec_cmd(
    [[bash -c 'f=~/Pictures/Screenshots/swappy-$(date +%Y%m%d_%H%M%S).png && grim -g "$(slurp)" - | swappy -f - -o "$f"']]))

hl.bind("SUPER + ALT + R",       hl.dsp.exec_cmd("gpu-screen-recorder -w screen -a default_output -f 60 -o ~/Videos"))
hl.bind("CTRL + ALT + R",        hl.dsp.exec_cmd("gpu-screen-recorder -w screen -f 60 -o ~/Videos"))
hl.bind("SUPER + SHIFT + ALT + R", hl.dsp.exec_cmd("gpu-screen-recorder -w region -f 60 -o ~/Videos"))
hl.bind("SUPER + SHIFT + C",     hl.dsp.exec_cmd("hyprpicker -a"))

-- Voice notes (voxd) — the bash -c wrapper MUST stay (removing it breaks the keybind)
hl.bind("CTRL + SHIFT + ALT + V", hl.dsp.exec_cmd([[bash -c 'voxd --trigger-record']]))
hl.bind("SHIFT + ALT + SUPER + f13", hl.dsp.exec_cmd([[bash -c 'voxd --trigger-record']]))
hl.bind("SHIFT + ALT + SUPER + f14", hl.dsp.exec_cmd([[bash -c 'voxd --trigger-record']]))

hl.bind("ALT + W", hl.dsp.exec_cmd("qs ipc call wallpaperPicker toggle"))

----------------------------------------------------------------------
-- Volume
----------------------------------------------------------------------

hl.bind("XF86AudioMute",   hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), LOCKED)
hl.bind("SUPER + SHIFT + M", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"), LOCKED)
hl.bind("XF86AudioRaiseVolume",
    hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ 0; wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ " .. v.volumeStep .. "%+"),
    LOCKED_REPEAT)
hl.bind("XF86AudioLowerVolume",
    hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ 0; wpctl set-volume @DEFAULT_AUDIO_SINK@ " .. v.volumeStep .. "%-"),
    LOCKED_REPEAT)

----------------------------------------------------------------------
-- Sleep + clipboard/emoji
----------------------------------------------------------------------

hl.bind("SUPER + SHIFT + L", hl.dsp.exec_cmd("systemctl suspend-then-hibernate"))

hl.bind("SUPER + V",       hl.dsp.exec_cmd("pkill tofi || cliphist list | tofi | cliphist decode | wl-copy"))
hl.bind("SUPER + ALT + V", hl.dsp.exec_cmd("pkill tofi || cliphist list | tofi | cliphist delete"))
hl.bind("SUPER + Period",  hl.dsp.exec_cmd([[pkill tofi || BEMOJI_PICKER_CMD="tofi" bemoji -t]]))
-- Alternate paste (same key as voxd voice note above — intentional dual bind)
hl.bind("CTRL + SHIFT + ALT + V",
    hl.dsp.exec_cmd([[sleep 0.5s && ydotool type -d 1 "$(cliphist list | head -1 | cliphist decode)"]]), LOCKED)

----------------------------------------------------------------------
-- Testing
----------------------------------------------------------------------

hl.bind("SUPER + ALT + f12", hl.dsp.exec_cmd(
    [[notify-send -u low -i dialog-information-symbolic 'Test notification' "Here's a really long message to test truncation and wrapping\nYou can middle click or flick this notification to dismiss it!" -a 'Shell' -A "Test1=I got it!" -A "Test2=Another action"]]),
    LOCKED)
