-- Keybind cheat sheet registry, used by scripts/tofi-keybinds.sh (SUPER+H).
--
-- Required from hyprland.lua BEFORE any binds are made. It wraps hl.bind and
-- the hl.dsp.* constructors so every bind is recorded with a readable label,
-- and M.write() (called at the end of hyprland.lua) dumps the list to
-- $XDG_RUNTIME_DIR/hypr-keybinds.tsv as "index<TAB>keys<TAB>label".
-- `hyprctl eval 'hypr_cheatsheet_run(<index>)'` then runs that bind's actions.
--
-- Better label for a bind: pass { desc = "..." } in its options.

local M = {}

-- Keep the real functions across config reloads so they're never double-wrapped.
_G.__cheatsheet_orig = _G.__cheatsheet_orig or { bind = hl.bind, dsp = {} }
local orig = _G.__cheatsheet_orig

local labels = setmetatable({}, { __mode = "k" }) -- dispatcher -> label
local entries, by_key = {}, {}

local friendly = {
	exec_cmd = "Run",
	focus = "Focus",
	["window.move"] = "Move window",
	["window.close"] = "Close window",
	["window.center"] = "Center window",
	["window.pin"] = "Pin window (all workspaces)",
	["window.float"] = "Float window",
	["window.fullscreen"] = "Fullscreen",
	["window.cycle_next"] = "Cycle windows",
	["window.drag"] = "Drag window",
	["window.resize"] = "Resize window",
	["group.toggle"] = "Make/dissolve window group",
	["group.next"] = "Next window in group",
	["group.prev"] = "Previous window in group",
	["group.lock"] = "Lock window group",
	["workspace.toggle_special"] = "Toggle special workspace",
}

local function clean_cmd(cmd)
	cmd = cmd:gsub("^bash %-c '(.*)'$", "%1")
	cmd = cmd:gsub("^pkill tofi || ", "")
	cmd = cmd:gsub("^noctalia msg ", "Noctalia: ")
	cmd = cmd:gsub("~/%.config/hypr/scripts/", "")
	if not cmd:find(" ") and not cmd:find("%.sh$") then
		cmd = "Open " .. cmd -- a bare app name, e.g. "firefox"
	end
	return cmd
end

local function fmt_args(name, ...)
	local parts = {}
	for _, a in ipairs({ ... }) do
		if type(a) == "table" then
			local kv = {}
			for k, v in pairs(a) do
				kv[#kv + 1] = (k == "direction" or k == "action" or k == "mode") and tostring(v)
					or (k .. " " .. tostring(v))
			end
			table.sort(kv)
			parts[#parts + 1] = table.concat(kv, ", ")
		elseif name == "exec_cmd" then
			parts[#parts + 1] = clean_cmd(tostring(a))
		else
			parts[#parts + 1] = tostring(a)
		end
	end
	local base = friendly[name] or name:gsub("[._]", " ")
	if name == "exec_cmd" then
		base = ""
	end
	local args = table.concat(parts, " ")
	if base == "" then
		return args
	end
	return args == "" and base or (base .. ": " .. args)
end

local function wrap(tbl, origtbl, prefix)
	for name, f in pairs(origtbl) do
		local path = prefix .. name
		if type(f) == "function" then
			tbl[name] = function(...)
				local d = f(...)
				if d ~= nil then
					pcall(function(...) labels[d] = fmt_args(path, ...) end, ...)
				end
				return d
			end
		elseif type(f) == "table" then
			wrap(tbl[name], f, path .. ".")
		end
	end
end

local function snapshot(t)
	local s = {}
	for k, v in pairs(t) do
		s[k] = type(v) == "table" and snapshot(v) or v
	end
	return s
end

if next(orig.dsp) == nil then
	orig.dsp = snapshot(hl.dsp)
end
wrap(hl.dsp, orig.dsp, "")

hl.bind = function(keys, action, opts)
	local r = orig.bind(keys, action, opts)
	opts = opts or {}
	if opts.mouse or opts.drag or keys:find("mouse") then
		return r
	end
	local e = by_key[keys]
	if e and opts.release and not e.release then
		return r -- the press half is already listed
	end
	if not e then
		e = { keys = keys, actions = {}, parts = {}, release = opts.release }
		by_key[keys] = e
		entries[#entries + 1] = e
	end
	e.actions[#e.actions + 1] = action
	e.desc = e.desc or opts.desc or opts.description
	e.parts[#e.parts + 1] = type(action) == "function" and "(custom function)" or (labels[action] or tostring(action))
	return r
end

function _G.hypr_cheatsheet_run(i)
	local e = entries[i]
	if not e then
		return
	end
	for _, a in ipairs(e.actions) do
		if type(a) == "function" then
			a()
		else
			hl.dispatch(a)
		end
	end
end

function M.write()
	local dir = os.getenv("XDG_RUNTIME_DIR") or "/tmp"
	local f = io.open(dir .. "/hypr-keybinds.tsv", "w")
	if not f then
		return
	end
	for i, e in ipairs(entries) do
		local label = e.desc or table.concat(e.parts, " + ")
		label = label:gsub("[\t\n]", " ")
		if #label > 90 then
			label = label:sub(1, 87) .. "..."
		end
		f:write(i, "\t", e.keys, "\t", label, "\n")
	end
	f:close()
end

return M
