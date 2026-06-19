-- User settings + keybind aliases. Returns a table; consumers do
-- `local v = require("variables")` (each require() is its own scope, so plain
-- `local`s do NOT cross files).

local colors = require("lib.colors")

return {
    colors = colors, -- re-exported so other modules need only one require

    apps = {
        terminal     = "foot",
        browser      = "firefox",
        editor       = "nvim",
        fileExplorer = "dolphin",
        notes        = "cudatext",
        chrome       = "google-chrome-stable",
    },

    touchpad = {
        disableTyping        = true,
        scrollFactor         = 0.3,
        workspaceSwipeFingers = 4,
        gestureFingers       = 3,
        gestureFingersMore   = 4,
    },

    blur = {
        enabled      = true,
        specialWs    = false,
        popups       = true,
        inputMethods = true,
        size         = 8,
        passes       = 2,
        xray         = false,
    },

    shadow = {
        enabled     = true,
        range       = 20,
        renderPower = 3,
        colour      = colors.rgba("surface", "d4"),
    },

    gaps = {
        workspace       = 8,
        windowIn        = 6,
        windowOut       = 8,
        singleWindowOut = 8,
    },

    window = {
        opacity       = 0.95,
        rounding      = 10,
        borderSize    = 2,
        activeBorder   = colors.rgba("primary", "e6"),
        inactiveBorder = colors.rgba("onSurfaceVariant", "11"),
    },

    cursor = {
        theme = "sweet-cursors",
        size  = 24,
    },

    volumeStep = 5, -- percent

    -- Mod-only aliases: combined with a key at the call site, e.g.
    -- `hl.bind(mods.goToWs .. " + 1", ...)`. Mirrors hyprlang `bind = $kbGoToWs, 1`.
    mods = {
        goToWs       = "ALT",
        goToWsGroup  = "CTRL + SUPER",
        moveToWs     = "ALT + SHIFT",
        moveToWsGroup = "CTRL + SUPER + ALT",
    },

    -- Full-combo aliases: complete bind strings, passed straight to hl.bind().
    keys = {
        nextWs           = "CTRL + SUPER + right",
        prevWs           = "CTRL + SUPER + left",
        toggleSpecialWs  = "SUPER + S",

        windowGroupCycleNext = "ALT + Tab",
        windowGroupCyclePrev = "SHIFT + ALT + Tab",
        ungroup              = "SUPER + U",
        toggleGroup          = "SUPER + Comma",

        moveWindow               = "ALT + G",
        resizeWindow             = "ALT + X",
        windowPip                = "SUPER + ALT + Backslash",
        pinWindow                = "SUPER + P",
        windowFullscreen         = "ALT + F",
        windowBorderedFullscreen = "SUPER + ALT + F",
        toggleWindowFloating     = "SUPER + ALT + Space",
        closeWindow              = "ALT + Q",

        systemMonitor = "CTRL + SHIFT + Escape",
        music         = "SUPER + M",
        communication = "SUPER + D",

        terminal     = "ALT + Return",
        browser      = "ALT + B",
        editor       = "ALT + E",
        chrome       = "ALT + C",
        fileExplorer = "ALT + T",
        notes        = "ALT + N",

        session     = "CTRL + ALT + Delete",
        clearNotifs = "CTRL + ALT + C",
        showPanels  = "SUPER + K",
    },
}
