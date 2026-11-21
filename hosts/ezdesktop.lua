-- Desktop-only overrides (hostname "ezdesktop"), loaded after user.lua.

-- The Acer ultrawide advertises 60 Hz as preferred; run it at its full 165 Hz.
hl.monitor({
    output   = "desc:Acer Technologies ED343CUR V 140800D5A2X00",
    mode     = "3440x1440@165",
    position = "auto",
    scale    = "1",
})

hl.config({
    misc = {
        vrr = 2, -- fullscreen only; always-on flickers on the VA ultrawide's desktop
    },
})
