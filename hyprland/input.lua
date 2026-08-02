-- input + binds + cursor.

local v = require("variables")

hl.config({
    input = {
        kb_layout          = "us",
        numlock_by_default = false,
        repeat_delay       = 250,
        repeat_rate        = 35,

        focus_on_close = 1,

        touchpad = {
            natural_scroll       = true,
            disable_while_typing = v.touchpad.disableTyping,
            scroll_factor        = v.touchpad.scrollFactor,
        },
    },

    binds = {
        scroll_event_delay = 0,
    },

    cursor = {
        hotspot_padding = 1,
    },
})

-- Chocofi only: US-Intl AltGr variant so its French layer's AltGr chords
-- produce accented characters. Every other keyboard keeps plain "us".
hl.device({
    name       = "beekeeb-corne",
    kb_layout  = "us",
    kb_variant = "altgr-intl",
})
