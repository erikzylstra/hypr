-- Colour scheme loader.
--
-- `scheme/current.conf` is generated externally (by quickshell/caelestia today,
-- and seeded from `scheme/default.conf`). It is hyprlang `$key = hexvalue` lines,
-- NOT Lua, so we parse it at config-eval time. Colours therefore refresh on a
-- manual `hyprctl reload` after a theme change (live re-theming is intentionally
-- not wired up — caelestia is being phased out).
--
-- The old hyprlang configs used string-concatenation inside rgba(), e.g.
-- `rgba($surfaced4)` meant `$surface` ("0b0f10") + alpha "d4" -> "rgba(0b0f10d4)".
-- `rgb()`/`rgba()` below reproduce exactly that.

local config_dir = (os.getenv("XDG_CONFIG_HOME") or ((os.getenv("HOME") or "~") .. "/.config")) .. "/hypr"

---Parse a hyprlang `$key = hexvalue` colour file into a name->hex table.
---@param path string
---@return table<string,string>|nil
local function parse(path)
    if not (io and io.open) then return nil end
    local f = io.open(path, "r")
    if not f then return nil end
    local map = {}
    for line in f:lines() do
        local k, v = line:match("^%s*%$([%w_]+)%s*=%s*(%x+)%s*$")
        if k then map[k] = v end
    end
    f:close()
    return map
end

local map = parse(config_dir .. "/scheme/current.conf")
    or parse(config_dir .. "/scheme/default.conf")

if not map then
    error("hypr colors: could not read scheme/current.conf or scheme/default.conf "
        .. "(is io available in the Hyprland Lua sandbox?)")
end

local M = { c = map }

---@param name string  colour key from the scheme (e.g. "primary")
---@return string      e.g. "rgb(9fcede)"
function M.rgb(name)
    local hex = map[name]
    if not hex then error("hypr colors: unknown colour '" .. tostring(name) .. "'") end
    return "rgb(" .. hex .. ")"
end

---@param name  string  colour key from the scheme (e.g. "primary")
---@param alpha string  two-hex-digit alpha suffix (e.g. "e6")
---@return string       e.g. "rgba(9fcedee6)"
function M.rgba(name, alpha)
    local hex = map[name]
    if not hex then error("hypr colors: unknown colour '" .. tostring(name) .. "'") end
    return "rgba(" .. hex .. alpha .. ")"
end

return M
