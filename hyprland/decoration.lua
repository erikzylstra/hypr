-- decoration: rounding, blur, shadow.

local v = require("variables")

hl.config({
    decoration = {
        rounding = v.window.rounding,

        blur = {
            enabled           = v.blur.enabled,
            xray              = v.blur.xray,
            special           = v.blur.specialWs,
            ignore_opacity    = true, -- allows opacity blurring
            new_optimizations = true,
            popups            = v.blur.popups,
            input_methods     = v.blur.inputMethods,
            size              = v.blur.size,
            passes            = v.blur.passes,
        },

        shadow = {
            enabled      = v.shadow.enabled,
            range        = v.shadow.range,
            render_power = v.shadow.renderPower,
            color        = v.shadow.colour,
        },
    },
})
