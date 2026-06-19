-- general + dwindle layout.

local v = require("variables")

hl.config({
    general = {
        layout = "dwindle",

        allow_tearing = false, -- lets the `immediate` window rule work

        gaps_workspaces = v.gaps.workspace,
        gaps_in         = v.gaps.windowIn,
        gaps_out        = v.gaps.windowOut,
        border_size     = v.window.borderSize,

        col = {
            active_border   = v.window.activeBorder,
            inactive_border = v.window.inactiveBorder,
        },
    },

    dwindle = {
        preserve_split = true,
        smart_split    = false,
        smart_resizing = true,
    },
})
