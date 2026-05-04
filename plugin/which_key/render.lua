local M = {}

local ANSI = {
    reset  = '\x1b[0m',
    bold   = '\x1b[1m',
    dim    = '\x1b[2m',
    blue   = '\x1b[34m',
    cyan   = '\x1b[36m',
    yellow = '\x1b[33m',
    green  = '\x1b[32m',
}

local function title_case(s)
    return s:sub(1, 1):upper() .. s:sub(2):lower()
end

local function format_key_label(key, mods)
    local parts = {}
    if mods and mods ~= '' then
        for mod in mods:gmatch('[^|]+') do
            table.insert(parts, title_case(mod))
        end
    end
    table.insert(parts, key)
    return table.concat(parts, '+')
end

local function format_row(key, mods, desc, label_width, key_color)
    local label = format_key_label(key, mods)
    local pad = string.rep(' ', math.max(0, label_width - #label))
    return string.format(
        '  %s[%s]%s%s  %s',
        key_color, label, ANSI.reset, pad, desc or ''
    )
end

local function compute_label_width(rows_groups)
    local max = 0
    for _, group in ipairs(rows_groups) do
        for _, r in ipairs(group) do
            local label = format_key_label(r.key, r.mods)
            if #label > max then max = #label end
        end
    end
    return max
end

function M.build_cheatsheet(mappings, defaults)
    local lines = {}

    -- Header
    table.insert(lines, ANSI.bold .. ANSI.blue .. '╔════════════════════════════════════╗' .. ANSI.reset)
    table.insert(lines, ANSI.bold .. ANSI.blue .. '║         WEZTERM WHICH KEY          ║' .. ANSI.reset)
    table.insert(lines, ANSI.bold .. ANSI.blue .. '╚════════════════════════════════════╝' .. ANSI.reset)
    table.insert(lines, '')

    local groups = { mappings }
    if defaults then table.insert(groups, defaults) end
    local label_width = compute_label_width(groups) + 2

    -- User mappings
    for _, m in ipairs(mappings) do
        table.insert(lines, format_row(m.key, m.mods, m.desc, label_width, ANSI.cyan))
    end

    -- Defaults section (opt-in)
    if defaults and #defaults > 0 then
        table.insert(lines, '')
        table.insert(lines, ANSI.dim .. '──────────── Defaults ────────────' .. ANSI.reset)
        table.insert(lines, '')
        for _, d in ipairs(defaults) do
            table.insert(lines, format_row(d.key, d.mods, d.desc, label_width, ANSI.green))
        end
    end

    -- Footer
    table.insert(lines, '')
    table.insert(lines, ANSI.dim .. '  [Esc] cancel' .. ANSI.reset)

    -- Terminal line endings (CRLF) so inject_output renders cleanly
    return table.concat(lines, '\r\n') .. '\r\n'
end

return M
