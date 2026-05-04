-- Drop-in module that matches a typical wezterm config layout
-- (M.apply(config) interface, like modules/keys.lua, modules/font.lua, etc.).
--
-- Local-development variant: bypasses wezterm.plugin.require (which uses
-- libgit2 and rejects UNC URIs + needs a real git repo) and loads the plugin
-- directly via package.path. Once the plugin is published, swap to
-- wezterm.plugin.require('https://github.com/<owner>/wezterm-which-key').

local wezterm = require 'wezterm'
local act = wezterm.action

local M = {}

-- Adjust to where you cloned the repo. WezTerm runs on the Windows host,
-- so the path must be host-resolvable.
local PLUGIN_ROOT = '//wsl.localhost/Ubuntu-24.04/home/bgarciamoura/projects/wezterm-which-key'

package.path = PLUGIN_ROOT .. '/plugin/?.lua;'
    .. PLUGIN_ROOT .. '/plugin/?/init.lua;'
    .. package.path

local function reload_plugin()
    -- Clear cached plugin modules so each wezterm config reload picks up
    -- edits to plugin source. Must run on every apply (not just module init)
    -- because wezterm caches THIS module too — only apply() re-runs per reload.
    for k in pairs(package.loaded) do
        if k == 'which_key' or k:match('^which_key%.') then
            package.loaded[k] = nil
        end
    end
    return require 'which_key'
end

function M.apply(config)
    local which_key = reload_plugin()

    which_key.apply_to_config(config, {
        leader = { key = 'b', mods = 'CTRL', timeout_milliseconds = 2000 },
        activator = { key = 'Space' },
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
end

return M
