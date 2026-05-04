# wezterm-which-key

Which-key style cheat-sheet panel for [WezTerm](https://wezterm.org), inspired by [which-key.nvim](https://github.com/folke/which-key.nvim).

Press a leader key + activator, see a panel listing the next available keys. Press one to fire the action; press Esc to dismiss.

## How it works

WezTerm has no native overlay API. The panel is a temporary pane that splits off from the active one, runs `sh -c "cat <cheatsheet>; sleep …"` so the content stays put without a shell prompt clearing it, and is killed via `wezterm cli kill-pane` when the user dismisses.

Three things drive the architecture:

1. **`wezterm cli split-pane` instead of `MuxPane:split{}`.** The Lua API silently ignores the `command` field on the wezterm versions we tested (20240203), falling back to the user's default shell — which immediately scrolls past or clears the injected content. The CLI honors the command, so we shell out via `wezterm.run_child_process`.
2. **`sh -c "cat …; while :; do sleep 3600; done"`** as the panel command. `cmd /c …` exits immediately under wezterm's ConPTY (even with `/k`), and any interactive shell renders a prompt that destroys our content. A bare `sh` with a sleep loop keeps the buffer pristine.
3. **Centralized cleanup via `update-status`.** Each key_table exit path (mapped key, Esc, timeout) is covered without per-entry hooks. A 500ms grace window prevents an immediate close due to `ActivateKeyTable` not having settled when the watcher first fires.

## Install

For local development (current state of this repo), see `example/modules-which_key.lua`.

When published to GitHub, the canonical install will be:

```lua
local wezterm = require 'wezterm'
local config = wezterm.config_builder()

local which_key = wezterm.plugin.require('https://github.com/<owner>/wezterm-which-key')

which_key.apply_to_config(config, {
    leader = { key = 'b', mods = 'CTRL', timeout_milliseconds = 2000 },
    activator = { key = 'Space' },
    mappings = {
        { key = 'f', desc = 'Find',        action = wezterm.action.Search { CaseInSensitiveString = '' } },
        { key = 'v', desc = 'Split right', action = wezterm.action.SplitPane { direction = 'Right' } },
    },
})

return config
```

## Options

| Option | Type | Default | Description |
|---|---|---|---|
| `leader` | `{ key, mods, timeout_milliseconds? }` | required | Leader key. Same shape as `config.leader`. |
| `activator` | `{ key, mods? }` | required | Key pressed after the leader to open the panel. |
| `panel.position` | `'right' \| 'left' \| 'top' \| 'bottom'` | `'right'` | Where the panel splits. |
| `panel.size` | `{ Percent = N }` or `{ Cells = N }` | `{ Percent = 40 }` | Size of the split. |
| `show_defaults` | `boolean` | `false` | If true, appends WezTerm default keybindings to the panel. |
| `mappings` | array of `{ key, desc, action, mods? }` | required | Your bindings. |

The `mappings[i]` schema reserves `group` and `mappings` fields for future nested groups (planned for v2 — opening `<leader>p` would surface a "Pane" sub-panel). Top-level `mappings` is the flat list for now.

## Tested platforms

- **Windows host + WSL default domain** (Ubuntu 24.04, nushell): works.
- **Linux / macOS native**: untested. The `sh -c "cat …"` command should work natively without the path conversion to `/mnt/c/…`. Code paths exist; smoke-test before relying on it.
- **Pure Windows (no WSL)**: not supported. `sh` isn't available; would need a PowerShell or `.bat` equivalent.

## Limitations

- Single global state — running multiple WezTerm windows that both trigger the panel will fight over `state.panel_pane_id`. Acceptable for now since you typically only have one which-key panel open at a time.
- Defaults rendered via `wezterm.gui.default_keys()` produce rough descriptions because action objects don't expose a clean introspection API.
- Nested groups not implemented yet — the schema reserves the fields but v1 ignores them.
- Cleanup relies on `wezterm cli kill-pane`. If the `wezterm` binary isn't on PATH, panes can leak.
- The CLI-based spawn means each panel open shells out twice (split-pane + activate-pane). Sub-second on local machines, but a measurable cost on slower hardware.

## Architecture

```
plugin/
├── init.lua                 entrypoint — re-exports which_key for wezterm.plugin.require
├── which_key.lua            apply_to_config — validates opts, registers keys + key_table + watcher
└── which_key/
    ├── state.lua            module-level state (panel pane id, opened_at)
    ├── render.lua           builds the ANSI-formatted cheat-sheet text
    ├── pane.lua             open/close the panel pane via wezterm cli
    ├── keytable.lua         turns mappings into a key_table
    └── defaults.lua         loads WezTerm defaults via wezterm.gui.default_keys()
```

## Why some things are the way they are

These are notes from the dev process, kept in case future work reopens any of them.

- **`until_unknown` is intentionally off.** Turning it on caused the activator key (Space) to be re-dispatched against the just-activated table and pop it before the panel was visible. Without it, the table only exits via `Esc` or a mapped key.
- **The `package.path` cache-buster lives in `M.apply`, not at module load.** WezTerm caches `modules.which_key` in `package.loaded` across config reloads; the only reliable hook to flush stale plugin code on `Ctrl+Shift+R` is to clear it inside `apply` itself, which re-runs each reload. This is purely a dev-mode concern — the published path via `wezterm.plugin.require` doesn't need it.
- **Focus is explicitly restored to the source pane after split.** Otherwise wezterm focuses the new (cheat-sheet) pane, and a subsequent `act.SplitPane` would split off of *that* pane in *that* domain (sh, in our case), so users would get a sh subprocess instead of their normal shell.

## Roadmap

- [ ] Publish as a git repo and exercise the `wezterm.plugin.require('https://...')` install path.
- [ ] Cross-platform testing (Linux native, macOS, pure Windows).
- [ ] Nested groups (`<leader>p` opens a "Pane" sub-panel).
- [ ] Cleaner `defaults.lua` formatting (parse the action structure instead of `tostring`).
- [ ] Customization knobs: ANSI colors, header text, padding.
- [ ] Optional: a single-process spawn (e.g. embed `cat` content via `inject_output` reliably) to avoid the double `wezterm cli` shell-out.
