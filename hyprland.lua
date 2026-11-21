-- Hyprland config entry point.
-- When this file exists it is loaded INSTEAD OF hyprland.conf (Hyprland 0.55+).
-- See /usr/share/hypr/stubs/hl.meta.lua for the full hl.* API.

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
-- Records every bind for the SUPER+H cheat sheet; must load before any binds.
local cheatsheet = require("lib.cheatsheet")
require("hyprland.keybinds")

-- Personal overrides, last.
require("user")

-- Per-machine overrides: hosts/<hostname>.lua, if one exists for this machine.
do
    local f = io.open("/etc/hostname", "r")
    local host = f and f:read("*l"):match("^[^.]+")
    if f then f:close() end
    if host and package.searchpath("hosts." .. host, package.path) then
        require("hosts." .. host)
    end
end

-- All binds are in; write the cheat sheet list.
cheatsheet.write()
