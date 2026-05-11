-- WezTerm's plugin loader does not add this plugin's `plugin/` directory to
-- package.path, so bare `require 'which_key'` (and the nested
-- `require 'which_key.state'` inside it) fail when the plugin is loaded via
-- wezterm.plugin.require('https://...'). Resolve our own location and prepend
-- the directory before any internal require.
local sep = package.config:sub(1, 1)
local plugin_dir = debug.getinfo(1, 'S').source
    :sub(2)
    :match('(.*' .. sep .. ')')
    or ('.' .. sep)
package.path = plugin_dir .. '?.lua;'
    .. plugin_dir .. '?' .. sep .. 'init.lua;'
    .. package.path

return require 'which_key'
