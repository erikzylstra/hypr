-- misc + debug. NOTE: vrr = 1 here is the base; user.lua (loaded last) overrides
-- it to 0.

local v = require("variables")

hl.config({
    misc = {
        vrr = 1,

        animate_manual_resizes       = false,
        animate_mouse_windowdragging = false,

        disable_hyprland_logo   = true,
        force_default_wallpaper = 0,

        allow_session_lock_restore = true,
        middle_click_paste         = false,
        focus_on_activate          = true,
        session_lock_xray          = false,

        mouse_move_enables_dpms = true,
        key_press_enables_dpms  = true,

        background_color = v.colors.rgb("surfaceContainer"),
    },

    debug = {
        vfr            = true,
        error_position = 1,
        -- Keep the runtime log (focus/layer events) so scripts/focus-debug.sh
        -- has something to capture when input breaks. Lives in tmpfs.
        disable_logs   = false,
    },
})
