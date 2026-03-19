-- SPDX-FileCopyrightText: 2026 Gabriel Arazas <foodogsquared@foodogsquared.one>
--
-- SPDX-License-Identifier: MIT

-- Ankh is my custom session manager implementation for Wezterm that gives more
-- of your current setup (e.g., workspaces, tab) to life. (Eh, eh, get it.).
--
-- The way Ankh works is simply a bunch of session-related utilities for you to
-- integrate this into your Wezterm configuration.
--
-- Inspired from already existing session managers such as
-- - https://github.com/mikkasendke/sessionizer.wezterm
-- - https://github.com/tmux-plugins/tmux-resurrect

local wezterm = require("wezterm")
local fds_xdg = require("foodogsquared.xdg")

local M = {}

--- @alias AnkhSource AnkhCallback[]
--- @alias ResolvedAnkhSource string[]
--- @alias AnkhOptions { state_directory: string, set_default_keybindings: boolean, sources: AnkhSource }
--- @alias AnkhCallback string | table | function(AnkhOptions, Wezterm.Window, Wezterm.Pane)

--- Convert a [AnkhSet] to a table of suitable parameters for Wezterm's input
--- selector.
---
--- @param c AnkhSet
--- @return table
local function convert_to_choices(c)
  local r = {}

  for k, v in c:ordered_pairs() do
    table.insert(r, { label = v.label, id = k })
  end

  return r
end

--- Set the configuration alongside the given plugin option.
---
--- @param config any
--- @param opts AnkhOptions
function M.apply_to_config(config, opts)
  local state_directory = opts.state_directory
    or (fds_xdg.xdg_user_dir("XDG_STATE_HOME") .. "/foodogsquared/ankh")

  if opts.set_default_keybindings or false then
    config.keys = config.keys or {}

    local default_keybinds = {
      {
        key = "s",
        mods = "LEADER",
        action = M.show(opts),
      },
    }

    for _, value in pairs(default_keybinds) do
      table.insert(config.keys, value)
    end
  end

  return config
end

--- Creates an input selector.
---
--- @param opts AnkhOptions
--- @return WeztermCallback
function M.show(opts)
  return wezterm.action_callback(function(window, pane)
    local choices = {}

    -- No worrying too much for the outputs, they'll be normalized at the end
    -- of the process anyways. Values with a function/table are expected to be
    -- normalized already though.
    for _, v in pairs(opts.sources or {}) do
      local t = type(v)
      if t == "string" then
        table.insert(choices, v)
      elseif t == "function" then
        local cc = v(opts, window, pane)
        for _, vl in ipairs(cc) do
          table.insert(choices, vl)
        end
      elseif t == "table" then
        for _, vl in ipairs(v) do
          table.insert(choices, vl)
        end
      end
    end
    choices = M.normalize(choices)

    return window:perform_action(
      wezterm.action.InputSelector {
        action = wezterm.action_callback(function(inner_window, inner_pane, id, label)
          if not label and not id then
            return
          end

          local choice = choices[id]
          local action = choice.action or nil
          local t = type(action)

          if t == "function" then
            choice.action(opts, window, pane)
          else
            inner_window:perform_action(
              action,
              inner_pane
            )
          end
        end),
        title = 'Select a menu item',
        choices = convert_to_choices(choices),
        fuzzy = true,
        fuzzy_description = "Search: ",
        description = 'Launch a menu item',
      },
      pane
    )
  end)
end

function M.normalize(entries)
  local Label = require("foodogsquared.ankh.set").Label
  local r = require("foodogsquared.ankh.set").Set:new()

  for _, value in pairs(entries) do
    local t = type(value)
    if t == "string" then
      r[value] = Label:new()
    elseif t == "table" then
      local id = value["id"] or value["label"]
      value["id"] = nil

      r[id] = Label:new(value)
    end
  end

  return r
end

return M
