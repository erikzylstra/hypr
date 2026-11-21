-- Autostart (was `exec-once`). hl.exec_cmd is async; commands run once at start.

local v = require("variables")
local theme = v.cursor.theme
local size  = v.cursor.size

local startup = {
    -- Keyring and auth
    "gnome-keyring-daemon --start --components=secrets",
    "/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1",

    -- Clipboard history
    "wl-paste --type text --watch cliphist store",
    "wl-paste --type image --watch cliphist store",

    -- Auto-delete trash older than 30 days
    "trash-empty 30",

    -- Cursors
    "hyprctl setcursor " .. theme .. " " .. size,
    "gsettings set org.gnome.desktop.interface cursor-theme '" .. theme .. "'",
    "gsettings set org.gnome.desktop.interface cursor-size " .. size,

    -- Location provider + night light
    "/usr/lib/geoclue-2.0/demos/agent",
    "sleep 1 && gammastep",

    -- Forward bluetooth media keys to MPRIS
    "mpris-proxy",

    -- Start the shell (Noctalia; restores its own wallpaper) — critical
    "noctalia",
}

hl.on("hyprland.start", function()
    for _, cmd in ipairs(startup) do
        hl.exec_cmd(cmd)
    end
end)
