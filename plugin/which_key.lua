local wezterm  = require 'wezterm'
local state    = require 'which_key.state'
local render   = require 'which_key.render'
local pane_mod = require 'which_key.pane'
local keytable = require 'which_key.keytable'
local defaults = require 'which_key.defaults'

local M = {}

local function validate(opts)
    assert(opts, 'wezterm-which-key: opts table is required')
    assert(opts.leader, 'wezterm-which-key: opts.leader is required')
    assert(opts.leader.key, 'wezterm-which-key: opts.leader.key is required')
    assert(opts.activator, 'wezterm-which-key: opts.activator is required')
    assert(opts.activator.key, 'wezterm-which-key: opts.activator.key is required')
    assert(opts.mappings and type(opts.mappings) == 'table',
        'wezterm-which-key: opts.mappings must be a table (array of {key, desc, action})')

    local panel = opts.panel
    if panel and panel.position then
        local valid = { right = true, left = true, top = true, bottom = true }
        assert(valid[panel.position:lower()],
            'wezterm-which-key: panel.position must be right|left|top|bottom')
    end
end

local function build_callback(opts)
    local panel_opts = opts.panel or { position = 'right', size = { Percent = 40 } }

    return wezterm.action_callback(function(window, pane)
        -- Defensive: kill a stale panel before opening a new one,
        -- e.g. if the user re-triggers the leader before the watcher cleaned up.
        if state.panel_pane_id then
            pane_mod.close(state.panel_pane_id)
            state.panel_pane_id = nil
        end

        local def_list = opts.show_defaults and defaults.load() or nil
        local content = render.build_cheatsheet(opts.mappings, def_list)

        state.panel_pane_id = pane_mod.open(window, pane, panel_opts, content)
        state.opened_at = os.clock()

        window:perform_action(
            wezterm.action.ActivateKeyTable({
                name = state.root_table_name,
                one_shot = false,
                -- until_unknown intentionally OFF: it would re-dispatch the
                -- activator key against the freshly-activated table and pop
                -- it before the user could see anything.
            }),
            pane
        )
    end)
end

local function build_activator_mods(activator)
    local mods = 'LEADER'
    if activator.mods and activator.mods ~= '' then
        mods = mods .. '|' .. activator.mods
    end
    return mods
end

function M.apply_to_config(config, opts)
    validate(opts)

    config.leader = {
        key = opts.leader.key,
        mods = opts.leader.mods or '',
        timeout_milliseconds = opts.leader.timeout_milliseconds or 2000,
    }

    config.key_tables = config.key_tables or {}
    config.key_tables[state.root_table_name] = keytable.build(opts.mappings)

    config.keys = config.keys or {}
    table.insert(config.keys, {
        key = opts.activator.key,
        mods = build_activator_mods(opts.activator),
        action = build_callback(opts),
    })

    -- Centralized cleanup: covers all key_table exit paths (mapped key,
    -- Esc, timeout) without duplicating logic per entry. Grace window
    -- avoids racing ActivateKeyTable, which is still processing when
    -- update-status fires right after the callback returns.
    local GRACE_SECONDS = 0.5
    wezterm.on('update-status', function(window, _pane)
        if not state.panel_pane_id then return end
        if state.opened_at and (os.clock() - state.opened_at) < GRACE_SECONDS then
            return
        end
        if window:active_key_table() ~= state.root_table_name then
            pane_mod.close(state.panel_pane_id)
            state.panel_pane_id = nil
            state.opened_at = nil
        end
    end)
end

return M
