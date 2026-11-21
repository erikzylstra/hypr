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
require("hyprland.keybinds")

-- Personal overrides, last.
require("user")
