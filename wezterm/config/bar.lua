-- The local bar configuration. This is based from
-- https://github.com/wezterm/wezterm/issues/500#issuecomment-792202306 or
-- https://wezterm.org/config/lua/window/set_right_status.html.
local M = {}
local wezterm = require("wezterm")
local utils = require("foodogsquared.utils.init")
local fds_strings = require("foodogsquared.utils.strings")
local fds_lists = require("foodogsquared.utils.lists")
local fds_wezterm = require("foodogsquared.utils.wezterm")

local SOLID_LEFT_ARROW = utf8.char(0xe0b2)
local SOLID_RIGHT_ARROW = utf8.char(0xe0b0)

function convert_to_elements(is_left, separator, colors, text_fg, cells)
  local elements = {}
  local num_cells = 0

  function push(text, is_last)
    local cell_no = num_cells + 1
    local separator_color = utils.cond(is_left, colors[cell_no], colors[cell_no + 1])
    table.insert(elements, { Foreground = { Color = text_fg } })
    table.insert(elements, { Background = { Color = colors[cell_no] } })
    table.insert(elements, { Text = ' ' .. text .. ' ' })
    if not is_last then
      if is_left then
        table.insert(elements, { Background = { Color = colors[cell_no + 1] } })
      end
      table.insert(elements, { Foreground = { Color = separator_color } })
      table.insert(elements, { Text = separator })
    end
    num_cells = num_cells + 1
  end

  while #cells > 0 do
    local cell = table.remove(cells, 1)
    push(cell, #cells == 0)
  end

  return elements
end

function M.apply_to_config(config)
  config.show_tabs_in_tab_bar = true
  config.show_new_tab_button_in_tab_bar = false

  config.status_update_interval = 1000

  wezterm.on("format-tab-title", function(tab, tabs, panes, config, hover, max_width)
    local pane = tab.active_pane
    local title = utils.basename(pane.foreground_process_name)
    return {
      {Text=" " .. title .. " "},
    }
  end)

  wezterm.on('update-status', function(window, pane)
    -- Each element holds the text for a cell in a "powerline" style << fade
    local cells = {}
    local left_cells = {}

    local keytable = window:active_key_table() or "normal"
    if keytable then
      table.insert(left_cells, keytable:gsub("_mode", ""):upper())
    end

    local tab = pane:tab()
    if tab then
      local active_pane = fds_wezterm.active_pane_with_info(tab)
      local active_tab

      for _, tab_with_info in pairs(window:mux_window():tabs_with_info()) do
        if tab_with_info.is_active then
          active_tab = tab_with_info
          goto end_tab
        end
      end
      ::end_tab::

      local str = active_tab.index + 1 .. ':' .. active_pane.index + 1
      local has_active_zoomed_pane = fds_lists.any(function (_, pane_attr)
        return pane_attr.is_zoomed and pane_attr.is_active
      end, pane:tab():panes_with_info())
      if has_active_zoomed_pane then
        str = str .. '+'
      end

      table.insert(left_cells, str)
    end

    -- Figure out the cwd and host of the current pane.
    -- This will pick up the hostname for the remote host if your
    -- shell is using OSC 7 on the remote host.
    local cwd_uri = pane:get_current_working_dir()
    if cwd_uri then
      local cwd = ''
      local user_string = ''

      if type(cwd_uri) == 'userdata' then
        cwd = cwd_uri.file_path:gsub(fds_strings.escape_pattern(wezterm.home_dir), "~")
        user_string = (cwd_uri.username or utils.get_user()) .. '@' .. cwd_uri.host or wezterm.hostname()
      else
        cwd_uri = cwd_uri:sub(8)
        local slash = cwd_uri:find '/'
        if slash then
          user_string = cwd_uri:sub(1, slash - 1):gsub(fds_strings.escape_pattern(wezterm.home_dir))
          cwd = cwd_uri:sub(slash):gsub('%%(%x%x)', function(hex)
            return string.char(tonumber(hex, 16))
          end)
        end
      end

      if user_string == '' then
        user_string = wezterm.hostname()
      end

      table.insert(left_cells, cwd)
      table.insert(cells, user_string)
    end

    local date = wezterm.strftime '%c'
    table.insert(cells, date)

    if window:leader_is_active() then
      table.insert(cells, "LEADER")
    end

    for _, b in ipairs(wezterm.battery_info()) do
      table.insert(cells, string.format('%.0f%%', b.state_of_charge * 100))
    end

    local colors = window:effective_config().resolved_palette
    local text_fg = colors.foreground
    local accent_color = wezterm.color.parse(colors.brights[1])
    local accents = wezterm.color.gradient({
      orientation = "Vertical",
      blend = "Oklab",
      colors = {
        accent_color:darken(0.33),
        accent_color:lighten(0.1),
      }
    }, 4)

    window:set_right_status(wezterm.format(convert_to_elements(false, SOLID_LEFT_ARROW, accents, text_fg, cells)))
    window:set_left_status(wezterm.format(convert_to_elements(true, SOLID_RIGHT_ARROW, accents, text_fg, left_cells)))
  end)
end

return M
