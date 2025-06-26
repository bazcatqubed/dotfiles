-- SPDX-FileCopyrightText: 2022-2025 Gabriel Arazas <foodogsquared@foodogsquared.one>
--
-- SPDX-License-Identifier: MIT

local config = require("wezterm").config_builder()
config:set_strict_mode(true)

require("config/events").apply_to_config(config)
require("config/base").apply_to_config(config)
require("config/keys").apply_to_config(config)
require("config/appearance").apply_to_config(config)
require("config/mux_server").apply_to_config(config)
require("config/exec_domain").apply_to_config(config)

local wezterm = require("wezterm")

wezterm.plugin
  .require("https://github.com/mikkasendke/sessionizer.wezterm")
  .apply_to_config(config)

wezterm.plugin
  .require("https://github.com/mrjones2014/smart-splits.nvim")
  .apply_to_config(config, {
    direction_keys = { 'h', 'j', 'k', 'l' },
    modifiers = {
      move = 'CTRL',
      resize = 'META',
    },
    log_level = 'info',
  })

return config
