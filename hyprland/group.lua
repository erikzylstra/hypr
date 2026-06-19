-- Window group + groupbar styling.

local v = require("variables")
local c = v.colors

hl.config({
    group = {
        col = {
            border_active        = v.window.activeBorder,
            border_inactive      = v.window.inactiveBorder,
            border_locked_active = v.window.activeBorder,
            border_locked_inactive = v.window.inactiveBorder,
        },

        groupbar = {
            font_family               = "JetBrains Mono NF",
            font_size                 = 15,
            gradients                 = true,
            gradient_round_only_edges = false,
            gradient_rounding         = 5,
            height                    = 25,
            indicator_height          = 0,
            gaps_in                   = 3,
            gaps_out                  = 3,

            text_color = c.rgb("onPrimary"),
            col = {
                active         = c.rgba("primary", "d4"),
                inactive       = c.rgba("outline", "d4"),
                locked_active  = c.rgba("primary", "d4"),
                locked_inactive = c.rgba("secondary", "d4"),
            },
        },
    },
})
