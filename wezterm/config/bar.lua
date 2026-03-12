-- SPDX-FileCopyrightText: 2025-2026 Gabriel Arazas <foodogsquared@foodogsquared.one>
--
-- SPDX-License-Identifier: MIT

-- The local bar configuration. This is based from
-- https://github.com/wezterm/wezterm/issues/500#issuecomment-792202306 or
-- https://wezterm.org/config/lua/window/set_right_status.html.
local M = {}
local wezterm = require("wezterm")
local utils = require("foodogsquared.utils.init")
local fds_strings = require("foodogsquared.utils.strings")
local fds_lists = require("foodogsquared.utils.lists")

local LEADER_CHAR_INDICATOR = utf8.char(0x21A5)
local ZOOMED_CHAR_INDICATOR = "+"
local SOLID_LEFT_ARROW = utf8.char(0xe0b2)
local SOLID_RIGHT_ARROW = utf8.char(0xe0b0)

function convert_to_elements(is_left, separator, colors, text_fg, cells)
  local elements = {}
  local string_len = 0
  local num_cells = 0

  function push(text, is_last)
    local cell_no = num_cells + 1
    local separator_color = utils.cond(is_left, colors[cell_no], colors[cell_no + 1])
    table.insert(elements, { Foreground = { Color = text_fg } })
    table.insert(elements, { Background = { Color = colors[cell_no] } })

    local content = " " .. text .. " "
    table.insert(elements, { Text = content })
    string_len = string_len + wezterm.column_width(content)

    if not is_last then
      if is_left then
        table.insert(elements, { Background = { Color = colors[cell_no + 1] } })
      end
      table.insert(elements, { Foreground = { Color = separator_color } })
      table.insert(elements, { Text = separator })
      string_len = string_len + wezterm.column_width(separator)
    end
    num_cells = num_cells + 1
  end

  while #cells > 0 do
    local cell = table.remove(cells, 1)
    push(cell, #cells == 0)
  end

  return elements, string_len
end

--- The entrypoint of the module.
--- @param config any
--- @param opts any
function M.apply_to_config(config, opts)
  config.show_tabs_in_tab_bar = true
  config.show_new_tab_button_in_tab_bar = false

  config.status_update_interval = 1000

  wezterm.on("format-tab-title", function(tab, tabs, panes, config, hover, max_width)
    local pane = tab.active_pane
    local title = utils.basename(pane.foreground_process_name)
    local replacements = opts.title_replacements or {}
    return {
      { Text = " " .. (replacements[title] or opts.default_title or title) .. " " },
    }
  end)

  wezterm.on("update-status", function(window, pane)
    -- Each element holds the text for a cell in a "powerline" style << fade
    local cells = {}
    local left_cells = {}

    -- The mode indicator inspired from Neovim's very own. It also features if
    -- the leader key is active.
    local mode_indicator = window:active_key_table() or "normal"
    if mode_indicator then
      table.insert(left_cells, mode_indicator:gsub("_mode", ""):upper())
    end
    ::end_mode_indicator::

    -- The position indicator. The notation is also inspired from Neovim's
    -- version where it is basically the equivalent of
    -- (TAB:PANE/TOTAL_PANE[PANE_STATUS_INDICATORS]).
    --
    -- The pane status indicators should be just a single character, here's an
    -- exhaustive list of the conditions:
    -- * If the active pane is zoomed
    -- * If the leader key is active
    local tab = pane:tab()
    local location_indicator
    if tab then
      local panes = tab:panes_with_info()

      local active_pane, active_tab

      for _, pane_with_info in pairs(panes) do
        if pane_with_info.is_active then
          active_pane = pane_with_info
          goto end_pane
        end
      end
      ::end_pane::

      for _, tab_with_info in pairs(window:mux_window():tabs_with_info()) do
        if tab_with_info.is_active then
          active_tab = tab_with_info
          goto end_tab
        end
      end
      ::end_tab::

      location_indicator = active_tab.index + 1 .. ":" .. active_pane.index + 1 .. "/" .. #panes
      if active_pane.is_zoomed then
        location_indicator = location_indicator .. ZOOMED_CHAR_INDICATOR
      end
    end
    if window:leader_is_active() then
      location_indicator = location_indicator .. LEADER_CHAR_INDICATOR
    end
    table.insert(left_cells, location_indicator)

    -- Figure out the cwd and host of the current pane.
    -- This will pick up the hostname for the remote host if your
    -- shell is using OSC 7 on the remote host.
    local cwd_uri = pane:get_current_working_dir()
    if cwd_uri then
      local cwd = ""
      local user_string = ""

      if type(cwd_uri) == "userdata" then
        cwd = cwd_uri.file_path
        user_string = utils.cond(cwd_uri.username ~= "", cwd_uri.username, utils.get_user())
          .. "@"
          .. (cwd_uri.host or wezterm.hostname())
      else
        cwd_uri = cwd_uri:sub(8)
        local slash = cwd_uri:find("/")
        if slash then
          user_string = cwd_uri:sub(1, slash - 1)
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
          goto end_cwd
        end
      end
      ::end_cwd::

      if user_string == "" then
        user_string = wezterm.hostname()
      end

      table.insert(left_cells, cwd)
      table.insert(cells, user_string)
    end

    local process_info = pane:get_foreground_process_info()
    if (opts.default_title and process_info) then
      table.insert(left_cells, process_info.name)
    end
    ::end_optional_pname::

    -- The optional date component. This is only disabled in certain places
    -- where the time component would be rendered redundant.
    local current_desktop = os.getenv("XDG_CURRENT_DESKTOP") or ""

    -- Pretty much all of the desktop setups I personally use. The ones with
    -- `one.foodogsquared` are basically properly configured custom desktop
    -- sessions configured with a proper session manager and everything.
    local desktop_denylist = { "GNOME", "one%.foodogsquared%.%w+" }
    if
      not fds_lists.any(function(_, desktop)
        return current_desktop:match(desktop)
      end, desktop_denylist)
    then
      local date = wezterm.strftime("%c")
      table.insert(cells, date)
    end

    -- The workspace and domain indicator. We placed it in a separate cell
    -- since they are rarely important in my use case.
    table.insert(cells, wezterm.mux.get_active_workspace() .. ":" .. pane:get_domain_name())

    -- Optional battery component.
    for _, b in ipairs(wezterm.battery_info()) do
      table.insert(cells, string.format("%.0f%%", b.state_of_charge * 100))
    end

    -- Setting up the components themselves.
    local colors = window:effective_config().resolved_palette
    local text_fg = colors.foreground
    local accent_color = wezterm.color.parse(colors.brights[1])
    local accents = wezterm.color.gradient({
      orientation = "Vertical",
      blend = "Oklab",
      colors = {
        accent_color:darken(0.33),
        accent_color:lighten(0.1),
      },
    }, 4)

    local right_widgets, rw_len = convert_to_elements(false, SOLID_LEFT_ARROW, accents, text_fg, cells)
    window:set_right_status(wezterm.format(right_widgets))

    local left_widgets, lw_len = convert_to_elements(true, SOLID_RIGHT_ARROW, accents, text_fg, left_cells)
    local tabs = window:mux_window():tabs();
    local mid_width = 0;
    for idx, tab in ipairs(tabs) do
      local title = tab:get_title();
      mid_width = mid_width + math.floor(math.log(idx, 10)) + 1
      mid_width = mid_width + #title + 2 -- Add the spaces around them.
    end
    local tab_width = window:active_tab():get_size().cols;
    local max_left = ((tab_width - lw_len - rw_len) / 2) - mid_width

    window:set_left_status(
      wezterm.format(left_widgets)
      .. wezterm.pad_left(" ", max_left)
    )
  end)
end

return M
