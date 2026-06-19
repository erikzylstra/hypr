-- Hyprland config entry point.
-- When this file exists it is loaded INSTEAD OF hyprland.conf (Hyprland 0.55+).
-- See /usr/share/hypr/stubs/hl.meta.lua for the full hl.* API.

local config_dir = (os.getenv("XDG_CONFIG_HOME") or ((os.getenv("HOME") or "~") .. "/.config")) .. "/hypr"

-- Ensure scheme/current.conf exists, seeded from default.conf — the way the old
-- `exec = cp --update=none default.conf current.conf` did. External tools
-- (quickshell/caelestia) read and overwrite this file, so it must be present.
local function ensure_current_scheme()
    if not (io and io.open) then return end
    local cur = config_dir .. "/scheme/current.conf"
    local f = io.open(cur, "r")
    if f then f:close(); return end -- already exists; don't clobber
    local src = io.open(config_dir .. "/scheme/default.conf", "r")
    if not src then return end
    local data = src:read("*a"); src:close()
    local out = io.open(cur, "w")
    if out then out:write(data); out:close() end
end
ensure_current_scheme()

-- Colours + user settings (every other module requires this).
require("variables")

-- Default monitor: preferred mode, auto position, scale 1.
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = "1" })

-- Modules, in the original source order.
require("hyprland.env")
require("hyprland.general")
require("hyprland.input")
require("hyprland.misc")
require("hyprland.animations")
require("hyprland.decoration")
require("hyprland.group")
require("hyprland.execs")
require("hyprland.rules")
require("hyprland.gestures")
require("hyprland.keybinds")

-- Personal overrides, last.
require("user")
