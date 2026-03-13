-- SPDX-FileCopyrightText: 2022-2025 Gabriel Arazas <foodogsquared@foodogsquared.one>
--
-- SPDX-License-Identifier: MIT

local config = require("wezterm").config_builder() ---@type Config

local xdg_utils = require("foodogsquared/xdg")
xdg_env = xdg_utils.parse_xdg_user_dirs()

config:set_strict_mode(true)

require("config/events").apply_to_config(config)
require("config/base").apply_to_config(config)
require("config/keys").apply_to_config(config)
require("config/appearance").apply_to_config(config)
require("config/mux_server").apply_to_config(config)
require("config/exec_domain").apply_to_config(config)

require("foodogsquared.foobazbar").apply_to_config(config, {
  prefixes = {
    { xdg_env["PROJECTS"], "$PROJ" },
    { xdg_env["DOCUMENTS"], "$DOC" },
    { xdg_env["PICTURES"], "$PICS" },
    { xdg_env["DOWNLOAD"], "$DOWN" },
    { wezterm.home_dir, "~" },
  },

  default_title = wezterm.nerdfonts.dev_terminal,

  title_replacements = {
    nvim = wezterm.nerdfonts.custom_neovim,
    emacs = wezterm.nerdfonts.custom_emacs,
    lazygit = wezterm.nerdfonts.seti_git,
    lazydocker = wezterm.nerdfonts.fa_docker,
    docker = wezterm.nerdfonts.fa_docker,
    ["docker-compose"] = wezterm.nerdfonts.fa_docker,
    cargo = wezterm.nerdfonts.dev_rust,
    diffoscope = wezterm.nerdfonts.md_coffee,
    nix = wezterm.nerdfonts.md_nix,
  },
})

wezterm.plugin.require("https://github.com/mikkasendke/sessionizer.wezterm").apply_to_config(config)

wezterm.plugin.require("https://github.com/mrjones2014/smart-splits.nvim").apply_to_config(config, {
  direction_keys = { "h", "j", "k", "l" },
  modifiers = {
    move = "CTRL",
    resize = "META",
  },
  log_level = "off",
})

return config
