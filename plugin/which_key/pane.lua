local wezterm = require 'wezterm'

local M = {}

local function is_windows()
    return wezterm.target_triple:find('windows') ~= nil
end

local function temp_path()
    local dir = os.getenv('TEMP') or os.getenv('TMP') or '/tmp'
    local sep = is_windows() and '\\' or '/'
    return dir .. sep .. 'wezterm_which_key_panel.txt'
end

local function write_content_file(content)
    local path = temp_path()
    local f, err = io.open(path, 'wb')
    if not f then
        wezterm.log_error('which_key: failed to open temp file: ' .. tostring(err))
        return nil
    end
    f:write(content)
    f:close()
    return path
end

-- Convert "C:\Users\foo\bar" -> "/mnt/c/Users/foo/bar" so a WSL-side `sh -c cat`
-- can read a file that Lua wrote to Windows TEMP. No-op on non-Windows hosts.
local function to_pty_path(path)
    if not is_windows() then return path end
    local drive, rest = path:match('^([A-Za-z]):\\?(.*)$')
    if not drive then return path end
    rest = rest:gsub('\\', '/')
    return '/mnt/' .. drive:lower() .. '/' .. rest
end

local function size_to_percent(size)
    if type(size) == 'number' then return math.floor(size * 100) end
    if type(size) == 'table' and size.Percent then return math.floor(size.Percent) end
    return 40
end

local function valid_position(pos)
    pos = (pos or 'right'):lower()
    local valid = { right = true, left = true, top = true, bottom = true }
    if not valid[pos] then return 'right' end
    return pos
end

function M.open(_window, src_pane, panel_opts, content)
    panel_opts = panel_opts or {}

    local content_path = write_content_file(content)
    if not content_path then return nil end

    local pty_path = to_pty_path(content_path)
    local position = valid_position(panel_opts.position)
    local pct = size_to_percent(panel_opts.size)
    local src_id = src_pane:pane_id()

    -- Use `wezterm cli split-pane` instead of MuxPane:split{} because the
    -- Lua API silently ignores the `command` field on this version of wezterm,
    -- falling back to default_prog (the user's shell) which immediately
    -- clears our cheatsheet with its own prompt. The CLI honors `command`.
    local args = {
        'wezterm', 'cli', 'split-pane',
        '--pane-id', tostring(src_id),
        '--' .. position,
        '--percent', tostring(pct),
        '--',
        'sh', '-c',
        "cat '" .. pty_path .. "'; while :; do sleep 3600; done",
    }

    local ok, stdout, stderr = wezterm.run_child_process(args)
    if not ok then
        wezterm.log_error('which_key: split-pane failed: '
            .. tostring(stderr) .. ' stdout=' .. tostring(stdout))
        return nil
    end

    -- Restore focus to the source pane so user's mapped actions target it,
    -- not the cheat-sheet pane (which would otherwise inherit focus and cause
    -- e.g. SplitPane to split off the cheat-sheet pane in the wrong domain).
    wezterm.run_child_process({
        'wezterm', 'cli', 'activate-pane', '--pane-id', tostring(src_id),
    })

    return tonumber((stdout or ''):match('%d+'))
end

function M.close(pane_id)
    if not pane_id then return end
    wezterm.run_child_process({
        'wezterm', 'cli', 'kill-pane', '--pane-id', tostring(pane_id),
    })
end

return M
