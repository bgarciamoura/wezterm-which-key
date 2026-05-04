local wezterm = require 'wezterm'

local M = {}

local function describe(action)
    -- WezTerm action objects don't expose a clean introspection API.
    -- Best-effort: stringify and clip to keep the panel readable.
    local s = tostring(action)
    if #s > 50 then s = s:sub(1, 47) .. '...' end
    return s
end

function M.load()
    local out = {}
    local ok, defaults = pcall(wezterm.gui.default_keys)
    if not ok or type(defaults) ~= 'table' then
        return out
    end
    for _, item in ipairs(defaults) do
        table.insert(out, {
            key = item.key,
            mods = item.mods or '',
            desc = describe(item.action),
        })
    end
    return out
end

return M
