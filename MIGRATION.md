# Hyprland config: hyprlang → Lua migration plan

Target: Hyprland 0.55+. Once `~/.config/hypr/hyprland.lua` exists it loads
instead of `hyprland.conf`. Old hyprlang format will keep working for 1–2 more
releases but receives no new features.

## API mapping cheat sheet

| Concern | Old (hyprlang) | New (Lua) |
|---|---|---|
| Source another file | `source = file.conf` | `require("file")` — each runs in its own scope |
| Variables | `$myVar = value` | Plain Lua `local myVar = value` |
| Set options | `general { gaps_in = 5 }` | `hl.config({ general = { gaps_in = 5 } })` (`col.active_border` → `col = { active_border = … }`) |
| Monitors | `monitor = ,preferred,auto,1` | `hl.monitor({ output = "", mode = "preferred", position = "auto", scale = "auto" })` |
| Env vars | `env = K,V` | `hl.env("K", "V")` |
| Autostart | `exec-once = cmd` | `hl.on("hyprland.start", function() hl.exec_cmd("cmd") end)` |
| Exec at reload | `exec = cmd` | `hl.exec_cmd("cmd")` at top level |
| Binds | `bind = MOD, KEY, dispatcher, args` | `hl.bind("MOD + KEY", hl.dsp.dispatcher(args))` |
| Bind variants | `bindl`/`bindr`/`bindm`/`binde`/`bindle`/`bindin` | Flag table: `{ locked, release, mouse, repeating, non_consuming, transparent, ignore_mods, long_press, click, drag, submap_universal, description, devices, bypass, separate }` |
| Window rules | `windowrule = match:class …, float on` | `hl.window_rule({ match = { class = "…" }, float = true })` |
| Workspace rules | `workspace = w[tv1]s[false], gapsout:8` | `hl.workspace_rule({ workspace = "w[tv1]s[false]", gaps_out = 8 })` |
| Layer rules | `layerrule = match:namespace …, blur on` | `hl.layer_rule({ match = { namespace = "…" }, blur = true })` |
| Animations | `bezier = …` + `animation = leaf, …` | `hl.curve("name", { type = "bezier", points = {…} })` + `hl.animation({ leaf = "windowsIn", … })` |
| Gestures | `gesture = fingers, direction, action` | `hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })` |
| Per-device | `device { name = …; … }` | `hl.device({ name = "…", … })` |
| Submaps | `submap = name` + binds + `submap = reset` | `hl.define_submap("name", function() hl.bind(…) end)` |

## Dispatchers (hl.dsp.*)

Dispatchers return tables now; they don't fire on their own — they get fed into
`hl.bind()` or `hl.dispatch()`.

- `hl.dsp.exec_cmd(cmd)` — was `exec`. Also `exec_raw` (no `bash -c`).
- `hl.dsp.global("appName:shortcutName")` — DBus global shortcuts (caelestia:* binds).
- `hl.dsp.window.close()`, `kill()`, `float({ action = "toggle" })`,
  `fullscreen({ mode = "maximized" })`, `pseudo()`, `pin()`, `center()`,
  `drag()`, `resize({…})`, `move({ direction = "l" })`,
  `move({ workspace = 2 })`.
- `hl.dsp.focus({ direction = "l"|"r"|"u"|"d" })`,
  `hl.dsp.focus({ workspace = "e-1" })` — replaces `movefocus` and `workspace`.
- `hl.dsp.workspace.toggle_special("name")`, `workspace.move(…)`.
- `hl.dsp.group.toggle()`, `group.next()`, `group.prev()`,
  `group.lock({ action = "toggle" })`.
- `hl.dsp.layout("togglesplit")` — for layout-specific messages.
- `hl.dsp.pass(window)`, `send_shortcut({ mods, key, window })` — passthrough.
- `hl.dsp.event(string)` — write to socket2.
- `hl.dsp.no_op()` — placeholder.

## File-by-file plan

| Current file | New file | Notes |
|---|---|---|
| `hyprland.conf` | `hyprland.lua` | Top-level entry; `require()` modules. |
| `variables.conf` | `variables.lua` | Returns a Lua table; modules `local vars = require("variables")`. |
| `hyprland/env.conf` | `hyprland/env.lua` | `hl.env(...)` calls. |
| `hyprland/general.conf` | `hyprland/general.lua` | One `hl.config({ general = …, dwindle = … })`. |
| `hyprland/input.conf` | `hyprland/input.lua` | `hl.config({ input = …, binds = …, cursor = … })`. |
| `hyprland/misc.conf` | `hyprland/misc.lua` | `hl.config({ misc = …, debug = … })`. |
| `hyprland/animations.conf` | `hyprland/animations.lua` | `hl.curve(...)` + `hl.animation({ leaf = …, enabled = false })`. |
| `hyprland/decoration.conf` | `hyprland/decoration.lua` | `hl.config({ decoration = { blur = {…}, shadow = {…} } })`. |
| `hyprland/group.conf` | `hyprland/group.lua` | `group = { groupbar = {…} }`. |
| `hyprland/execs.conf` | `hyprland/execs.lua` | `hl.on("hyprland.start", function() … end)`. |
| `hyprland/rules.conf` | `hyprland/rules.lua` | `hl.window_rule(...)`, `hl.workspace_rule(...)`, `hl.layer_rule(...)`. |
| `hyprland/gestures.conf` | `hyprland/gestures.lua` | `hl.config({ gestures = … })` + `hl.gesture({...})`. |
| `hyprland/keybinds.conf` | `hyprland/keybinds.lua` | The 20× `wsaction.fish` lines collapse into a `for i = 1,10` loop. |

## Gotchas

1. **`scheme/current.conf` is externally generated** in hyprlang format
   (`$primary = c2c1ff`) by quickshell/caelestia. Plan: keep it as-is and write
   a small Lua loader that parses `$key = value` lines into a colors table.
2. **`~/.config/caelestia/hypr-vars.conf` and `hypr-user.conf`** — same story
   as above. Parse from Lua, don't try to make caelestia emit Lua.
3. **`scripts/wsaction.fish`** uses `hyprctl dispatch workspace N`. Old-style
   dispatch may regress on Lua builds (cf. Waybar issue 5008). Either reshape
   the script to use `hyprctl dispatch 'hl.dsp.focus({ workspace = N })'`, or
   retire the script entirely by computing the target workspace in Lua and
   skipping the subprocess.
4. **`background_color = rgb($surfaceContainer)`** in `misc.conf` — becomes
   string concat once colors are a table.
5. **`bindin = Super, catchall, …`** for the caelestia launcher interrupt =
   `bind` with `ignore_mods` + `non_consuming` flags. The `catchall` keyword is
   documented for submaps in the new docs; verify it still works at top level.
6. **`exec = hyprctl dispatch submap global`** in `keybinds.conf` is a leftover
   from the old explicit-submap syntax; just drop it in Lua.
7. **Voxd keybinds** — `bash -c 'voxd --trigger-record'` wrapper must stay;
   removing it breaks the keybind.
8. **Legacy `hyprctl dispatch <name> <args>` is dead under a Lua config.** Hyprland
   evaluates the dispatch argument as a Lua expression (`return hl.dispatch(<arg>)`),
   so `hyprctl dispatch fullscreen 0` parses as `hl.dispatch(fullscreen 0)` — a Lua
   syntax error that silently no-ops. This broke ALT+F and every other shelled-out
   window-state bind. Fix: call native `hl.dsp.window.*` / `hl.dsp.group.*` directly in
   `keybinds.lua`. If you must shell out (e.g. piping into a launcher), use the new
   Lua-expression form: `hyprctl dispatch 'hl.dsp.exec_cmd("…")'`. Note native
   `window.resize`/`window.move` take absolute pixel numbers (no `%`), and `window.center`
   takes no args (the old `centerwindow 1` reserved-area flag is not exposed).

## Staged migration

Each step is independently verifiable.

1. Scaffold `hyprland.lua` and `variables.lua`, plus a colors loader that
   parses `current.conf` so external tools don't break.
2. Port env / general / input / misc / decoration / group / animations /
   gestures (mechanical `hl.config` translations).
3. Port `rules.lua` (window/workspace/layer rules — watch regex escaping).
4. Port `keybinds.lua` (collapse 20 wsaction lines into a loop, port caelestia
   globals, preserve voxd wrapper).
5. Port `execs.lua` via `hl.on("hyprland.start", …)`.
6. Optionally rewrite or retire `wsaction.fish`.
7. Decide: keep `.conf` files as fallback or delete.

## Sources

- [Lua-ification announcement](https://hypr.land/news/26_lua/)
- [Configuring/Start](https://wiki.hypr.land/Configuring/Start/)
- [Binds wiki](https://wiki.hypr.land/Configuring/Basics/Binds/)
- [Dispatchers wiki](https://wiki.hypr.land/Configuring/Basics/Dispatchers/)
- [Window Rules wiki](https://wiki.hypr.land/Configuring/Basics/Window-Rules/)
- [Official example hyprland.lua](https://github.com/hyprwm/Hyprland/blob/main/example/hyprland.lua)
