local wezterm = require 'wezterm'

local M = {}

function M.build(mappings)
    local entries = {}

    for _, m in ipairs(mappings) do
        -- Multiple wraps: dispatch user action AND pop our key_table in one keystroke.
        -- Cleanup of the panel pane is handled by the update-status watcher.
        table.insert(entries, {
            key = m.key,
            mods = m.mods or '',
            action = wezterm.action.Multiple({
                m.action,
                wezterm.action.PopKeyTable,
            }),
        })
    end

    -- Default exit
    table.insert(entries, {
        key = 'Escape',
        action = wezterm.action.PopKeyTable,
    })

    return entries
end

return M
