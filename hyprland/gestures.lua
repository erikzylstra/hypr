-- Gesture settings + touchpad gesture binds.

local v = require("variables")

hl.config({
    gestures = {
        workspace_swipe_distance                 = 700,
        workspace_swipe_cancel_ratio             = 0.15,
        workspace_swipe_min_speed_to_force       = 5,
        workspace_swipe_direction_lock           = true,
        workspace_swipe_direction_lock_threshold = 10,
        workspace_swipe_create_new               = true,
    },
})

-- N-finger horizontal swipe -> switch workspace.
hl.gesture({
    fingers   = v.touchpad.workspaceSwipeFingers,
    direction = "horizontal",
    action    = "workspace",
})

-- 3-finger up -> reveal the special workspace.
hl.gesture({
    fingers       = v.touchpad.gestureFingers,
    direction     = "up",
    action        = "special",
    workspace_name = "special",
})

-- The two below were `gesture = ..., dispatcher, ...` in hyprlang. The Lua
-- `action` field is documented as a string, but a function form is supported
-- (LuaFunctionGesture); these need a live check (see plan, open items).
-- 3-finger down -> toggle the special workspace.
hl.gesture({
    fingers   = v.touchpad.gestureFingers,
    direction = "down",
    action    = function() hl.dispatch(hl.dsp.workspace.toggle_special("special")) end,
})

-- 4-finger down -> suspend.
hl.gesture({
    fingers   = v.touchpad.gestureFingersMore,
    direction = "down",
    action    = function() hl.dispatch(hl.dsp.exec_cmd("systemctl suspend")) end,
})
