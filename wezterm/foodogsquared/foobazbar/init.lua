--- A custom bar that comes with a bunch of niceties including:
--- - An ala-Vim indicator for the mode.
--- - An indicator for the current working directory including the ability to make aliases of them.
--- - The centered tab bar.
--- - An optional clock (only appears in certain desktop environments).
--- - An indicator for the scope, user, and the workspace.
---
--- This is based from
--- https://github.com/wezterm/wezterm/issues/500#issuecomment-792202306 or
--- https://wezterm.org/config/lua/window/set_right_status.html.

-- SPDX-FileCopyrightText: 2025-2026 Gabriel Arazas <foodogsquared@foodogsquared.one>
--
-- SPDX-License-Identifier: MIT

local M = {}
local wezterm = require("wezterm")
local utils = require("foodogsquared.utils.init")
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
  config.use_fancy_tab_bar = true

  -- Configuring the appearance of the tab bar.
  config.window_frame = {
    font = config.font,
    font_size = config.font_size,
  }

  config.status_update_interval = 1000

  wezterm.on("format-tab-title", function(tab)
    local pane = tab.active_pane
    local title = utils.basename(pane.foreground_process_name)
    local replacements = opts.title_replacements or {}
    return {
      { Text = " " .. (replacements[title] or opts.default_title or title) .. " " },
    }
  end)

  wezterm.on("update-status", function(window, pane)
    local function normalize(sources)
      local r = {}
      for _, ele in ipairs(sources) do
        if type(ele == "function") then
          local v = ele(opts, window, pane)
          table.insert(r, v)
        else
          table.insert(r, ele)
        end
      end

      return r
    end

    -- Each element holds the text for a cell in a "powerline" style << fade
    local right_cells = normalize(opts.right_cells)
    local left_cells = normalize(opts.left_cells)

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

    local right_widgets, rw_len = convert_to_elements(false, SOLID_LEFT_ARROW, accents, text_fg, right_cells)
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
