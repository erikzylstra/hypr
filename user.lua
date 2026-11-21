-- Personal overrides, loaded last. Put any machine-specific tweaks here.

hl.config({
    misc = {
        vrr = 0,
    },
})

-- Laptop only.
local hf = io and io.open and io.open("/etc/hostname", "r")
local host = hf and hf:read("*l") or ""
if hf then hf:close() end

if host == "ezlaptop" then
    -- 14" 1920x1200 panel: 1.25 gives a 1536x960 workspace.
    hl.monitor({ output = "eDP-1", mode = "preferred", position = "auto", scale = "1.25" })
    hl.config({ xwayland = { force_zero_scaling = true } })
end
