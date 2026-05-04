-- Example wezterm config wiring up wezterm-which-key.
-- Copy this to ~/.config/wezterm/wezterm.lua (or %USERPROFILE%\.config\wezterm\wezterm.lua)
-- and adjust the plugin path to match where you cloned/placed the repo.

local wezterm = require 'wezterm'
local act = wezterm.action
local config = wezterm.config_builder()

-- Local dev path. For published use, replace with the GitHub URL:
--   wezterm.plugin.require('https://github.com/<owner>/wezterm-which-key')
local which_key = wezterm.plugin.require(
    'file:///home/bgarciamoura/projects/wezterm-which-key'
)

which_key.apply_to_config(config, {
    leader = { key = 'Space', mods = 'CTRL', timeout_milliseconds = 2000 },
    activator = { key = 'Space', mods = '' },
    panel = { position = 'right', size = { Percent = 40 } },
    show_defaults = false,
    mappings = {
        { key = 'f', desc = 'Find',         action = act.Search { CaseInSensitiveString = '' } },
        { key = 'v', desc = 'Split right',  action = act.SplitPane { direction = 'Right' } },
        { key = 's', desc = 'Split below',  action = act.SplitPane { direction = 'Down' } },
        { key = 'q', desc = 'Close pane',   action = act.CloseCurrentPane { confirm = true } },
        { key = 'z', desc = 'Zoom pane',    action = act.TogglePaneZoomState },
    },
})

return config
