-- SPDX-FileCopyrightText: 2026 Gabriel Arazas <foodogsquared@foodogsquared.one>
--
-- SPDX-License-Identifier: MIT

local M = {}

local LEADER_CHAR_INDICATOR = utf8.char(0x21A5)
local ZOOMED_CHAR_INDICATOR = "+"

--- A callback for the mode indicator inspired from Neovim's very own.
---
--- @return string?
function M.mode_indicator(opts, window, _)
  if window:leader_is_active() then
    return "LEADER"
  end

  local mode_indicator = window:active_key_table() or "normal"
  if mode_indicator then
    return mode_indicator:gsub("_mode", ""):upper()
  end
end

--- A callback for the position indicator. The notation is also inspired from
--- Neovim's version where it is basically the equivalent of
--- (TAB:PANE/TOTAL_PANE[PANE_STATUS_INDICATORS]).
---
--- The pane status indicators should be just a single character, here's an
--- exhaustive list of the conditions:
--- * If the active pane is zoomed
---
--- @return string?
function M.mux_position_indicator(opts, window, pane)
  local tab = pane:tab()
  local location_indicator
  if tab then
    local panes = tab:panes_with_info()

    for _, tab_with_info in pairs(window:mux_window():tabs_with_info()) do
      if tab_with_info.is_active then
        location_indicator = tab_with_info.index + 1 .. ":"
        break
      end
    end

    for _, pane_with_info in pairs(panes) do
      if pane_with_info.is_active then
        local active_pane = pane_with_info

        if active_pane then
          location_indicator = location_indicator .. active_pane.index + 1 .. "/" .. #panes

          if active_pane.is_zoomed or false then
            location_indicator = location_indicator .. ZOOMED_CHAR_INDICATOR
          end
        end
        break
      end
    end
  end

  return location_indicator
end

--- Component for showing the working directory through OSC7.
---
--- @return string?
function M.working_dir_indicator(opts, window, pane)
  local fds_strings = require("foodogsquared.utils.strings")

  local cwd_uri = pane:get_current_working_dir()
  if cwd_uri then
    local cwd

    if type(cwd_uri) == "userdata" then
      cwd = cwd_uri.file_path
    else
      cwd_uri = cwd_uri:sub(8)
      local slash = cwd_uri:find("/")
      if slash then
        cwd = cwd_uri:sub(slash):gsub("%%(%x%x)", function(hex)
          return string.char(tonumber(hex, 16))
        end)
      end
    end

    for _, dirtuple in ipairs(opts.prefixes or {}) do
      local dir = dirtuple[1]
      local prefix = dirtuple[2]
      if cwd:starts_with(dir) then
        cwd = cwd:gsub(fds_strings.escape_pattern(dir), prefix)
        break
      end
    end

    return cwd
  end
end

--- Return the user and the host.
---
--- @return string?
function M.user_indicator(_, _, pane)
  local fds_utils = require("foodogsquared.utils")
  local wezterm = require("wezterm")

  local user_string
  local cwd_uri = pane:get_current_working_dir()
  if type(cwd_uri) == "userdata" then
    user_string = fds_utils.cond(cwd_uri.username ~= "", cwd_uri.username, fds_utils.get_user())
      .. "@"
      .. (cwd_uri.host or wezterm.hostname())
  end

  return user_string
end

--- An optional clock component. Excluded to appear in default desktop
--- environments denylist where the clock is considered redundant (e.g., GNOME,
--- KDE Plasma).
---
--- @return string?
function M.clock_block(opts, window, pane)
  local fds_xdg = require("foodogsquared.xdg")
  local wezterm = require("wezterm")

  if fds_xdg.is_in_desktop_denylist() then
    return wezterm.strftime("%c")
  end
end

--- An optional component showing the executable name. Only appears when the
--- `default_title` plugin option is set.
---
--- @return string?
function M.process_info(opts, window, pane)
  local process_info = pane:get_foreground_process_info()
  if opts.default_title and process_info then
    return process_info.name
  end
end

--- The workspace and domain indicator formatted as "WORKSPACE:DOMAIN" inline
--- with the other components.
---
--- @return string?
function M.workspace_and_domain_indicator(opts, _, pane)
  return require("wezterm").mux.get_active_workspace() .. utf8.char(0x1CC90) .. pane:get_domain_name()
end

--- Optional battery component.
---
--- @return string?
function M.battery_component(opts, window, pane)
  for _, b in ipairs(require("wezterm").battery_info()) do
    return string.format("%.0f%%", b.state_of_charge * 100)
  end
end
return M
