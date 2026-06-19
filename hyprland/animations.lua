-- Animations. The curves are kept for reference, but every leaf is disabled
-- (the old config set every animation to duration 0), so transitions are instant.

hl.config({
    animations = { enabled = true },
})

-- Animation curves (unused while everything is disabled, kept for easy re-enable).
local curves = {
    { "specialWorkSwitch", { 0.05, 0.7, 0.1, 1 } },
    { "emphasizedAccel",   { 0.3,  0,   0.8, 0.15 } },
    { "emphasizedDecel",   { 0.05, 0.7, 0.1, 1 } },
    { "standard",          { 0.2,  0,   0,   1 } },
}
for _, b in ipairs(curves) do
    local p = b[2]
    hl.curve(b[1], { type = "bezier", points = { { p[1], p[2] }, { p[3], p[4] } } })
end

-- Disabled leaves (was `animation = NAME, 0`).
local disabled = {
    "layersIn", "layersOut", "fadeLayers",
    "windowsIn", "windowsOut", "windowsMove",
    "workspaces", "specialWorkspace",
    "fade", "fadeDim", "border",
}
for _, leaf in ipairs(disabled) do
    hl.animation({ leaf = leaf, enabled = false })
end
