-- WezTerm's plugin loader does not add this plugin's `plugin/` directory to
-- package.path, so bare `require 'which_key'` (and the nested
-- `require 'which_key.state'` inside it) fail when the plugin is loaded via
-- wezterm.plugin.require('https://...'). Resolve our own location via
-- wezterm.plugin.list() and prepend it before any internal require. The
-- `debug` standard library is not exposed inside WezTerm's Lua sandbox, so
-- `debug.getinfo` is unavailable here.
local wezterm = require 'wezterm'
local sep = package.config:sub(1, 1)

local plugin_dir
for _, p in ipairs(wezterm.plugin.list()) do
    if p.url and p.url:lower():find('wezterm%-which%-key') then
        plugin_dir = p.plugin_dir .. sep .. 'plugin' .. sep
        break
    end
end

if plugin_dir then
    package.path = plugin_dir .. '?.lua;'
        .. plugin_dir .. '?' .. sep .. 'init.lua;'
        .. package.path
end

return require 'which_key'
