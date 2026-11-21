-- Window / workspace / layer rules.
--
-- Each entry is passed straight to hl.window_rule / hl.workspace_rule /
-- hl.layer_rule. Regex match strings use [[long brackets]] so backslashes are
-- literal. Where the old config had several `windowrule` lines sharing one
-- match, they are merged into a single multi-property rule.

local v = require("variables")

----------------------------------------------------------------------
-- Window rules
----------------------------------------------------------------------

local window_rules = {
    -- App -> workspace
    { match = { class = [[^(firefox)$]] },                   workspace = "2" },
    { match = { class = [[^(outlook-for-linux)$]] },         workspace = "3 silent" },
    { match = { class = [[^(google-chrome|chromium)$]] },    workspace = "1" },
    { match = { class = [[^(spotify)$]] },                   workspace = "3 silent" },
    { match = { class = [[^(Postman)$]] },                   workspace = "5 silent" },
    { match = { class = [[^(org\.telegram\.desktop|TelegramDesktop)$]] }, workspace = "4 silent" },

    -- General
    { match = { fullscreen = false }, opacity = tostring(v.window.opacity) .. " override" },
    { match = { class = [[(foot|equibop|imv|swappy)]] }, opaque = true },
    -- Center floating windows (not xwayland, to avoid popups)
    { match = { float = true, xwayland = false }, center = true },

    -- Float
    { match = { class = "guifetch" },                            float = true }, -- FlafyDev/guifetch
    { match = { class = "yad" },                                 float = true },
    { match = { class = "zenity" },                              float = true },
    { match = { class = "wev" },                                 float = true },
    { match = { class = [[org\.gnome\.FileRoller]] },            float = true },
    { match = { class = "file-roller" },                         float = true },
    { match = { class = "blueman-manager" },                     float = true },
    { match = { class = [[com\.github\.GradienceTeam\.Gradience]] }, float = true },
    { match = { class = "feh" },                                 float = true },
    { match = { class = "imv" },                                 float = true },
    { match = { class = "system-config-printer" },               float = true },

    -- Float, resize and center
    { match = { class = "foot", title = "nmtui" },              float = true, size = "60% 70%", center = true },
    { match = { class = [[org\.gnome\.Settings]] },             float = true, size = "70% 80%", center = true },
    { match = { class = [[(org\.pulseaudio\.pavucontrol|yad-icon-browser)]] }, float = true, size = "60% 70%", center = true },
    { match = { class = "nwg-look" },                           float = true, size = "50% 60%", center = true },

    -- Special workspaces
    { match = { class = "btop" },                                  workspace = "special:sysmon" },
    { match = { class = [[(feishin|Spotify|Supersonic)]] },        workspace = "special:music" },
    { match = { initial_title = [[Spotify( Free)?]] },             workspace = "special:music" }, -- wayland Spotify has no class
    { match = { class = [[(discord|equibop|vesktop|whatsapp)]] },  workspace = "special:communication" },
    { match = { class = "Todoist" },                              workspace = "special:todo" },

    -- Dialogs
    { match = { title = [[(Select|Open)( a)? (File|Folder)(s)?]] }, float = true },
    { match = { title = [[File (Operation|Upload)( Progress)?]] },  float = true },
    { match = { title = [[.* Properties]] },                        float = true },
    { match = { title = "Export Image as PNG" },                    float = true },
    { match = { title = "GIMP Crash Debug" },                       float = true },
    { match = { title = "Save As" },                                float = true },
    { match = { title = "Library" },                                float = true },

    -- Picture in picture (resize/move handled by the PiP keybind macro)
    {
        match             = { title = [[Picture(-| )in(-| )[Pp]icture]] },
        move              = "100%-w-2% 100%-w-3%", -- initial move so it doesn't fly from center
        keep_aspect_ratio = true,
        float             = true,
        pin               = true,
    },

    -- Steam
    { match = { class = "steam", title = [[^$]] },           rounding = 10 },
    { match = { class = "steam", title = "Friends List" },   float = true },
    { match = { class = [[steam_app_[0-9]+]] },              immediate = true, idle_inhibit = "always" },

    -- ATLauncher console
    { match = { class = "com-atlauncher-App", title = "ATLauncher Console" }, float = true },

    -- Autodesk Fusion 360
    { match = { class = [[fusion360\.exe]], title = [[(Fusion360|(Marking Menu))]] }, no_blur = true },

    -- xwayland popups
    { match = { xwayland = true, title = [[win[0-9]+]] }, no_dim = true, no_shadow = true, rounding = 10 },
}

for _, r in ipairs(window_rules) do
    hl.window_rule(r)
end

----------------------------------------------------------------------
-- Workspace rules
----------------------------------------------------------------------

local workspace_rules = {
    { workspace = "w[tv1]s[false]", gaps_out = v.gaps.singleWindowOut },
    { workspace = "f[1]s[false]",   gaps_out = v.gaps.singleWindowOut },
}

for _, r in ipairs(workspace_rules) do
    hl.workspace_rule(r)
end

----------------------------------------------------------------------
-- Layer rules
----------------------------------------------------------------------

local layer_rules = {
    { match = { namespace = "hyprpicker" },     animation = "fade" },
    { match = { namespace = "logout_dialog" },  animation = "fade" },
    { match = { namespace = "selection" },      animation = "fade" },
    { match = { namespace = "wayfreeze" },      animation = "fade" },

    -- Fuzzel / launcher
    { match = { namespace = "launcher" }, animation = "popin 80%", blur = true },

    -- Shell: blur Noctalia's surfaces, as Noctalia's Hyprland guide suggests
    {
        match = { namespace = [[^noctalia-(bar-.+|notification|dock|panel|attached-panel|osd|window-switcher)$]] },
        blur = true,
        ignore_alpha = 0, -- don't blur fully transparent areas (e.g. the auto-hidden bar)
        no_anim = true,
    },
}

for _, r in ipairs(layer_rules) do
    hl.layer_rule(r)
end
