-- SPDX-FileCopyrightText: 2022-2025 Gabriel Arazas <foodogsquared@foodogsquared.one>
--
-- SPDX-License-Identifier: MIT

local wezterm = require("wezterm")
local config = wezterm.config_builder() ---@type Config

xdg_env = require("foodogsquared/xdg").parse_xdg_user_dirs()

config:set_strict_mode(true)

require("config/appearance").apply_to_config(config)
require("config/events").apply_to_config(config)
require("config/base").apply_to_config(config)
require("config/keys").apply_to_config(config)
require("config/mux_server").apply_to_config(config)
require("config/exec_domain").apply_to_config(config)

do
  local helpers = require("foodogsquared.foobazbar.helpers")
  require("foodogsquared.foobazbar").apply_to_config(config, {
    prefixes = {
      { xdg_env["PROJECTS"], "$PROJ" },
      { xdg_env["DOCUMENTS"], "$DOC" },
      { xdg_env["PICTURES"], "$PICS" },
      { xdg_env["DOWNLOAD"], "$DOWN" },
      { wezterm.home_dir, "~" },
    },

    left_cells = {
      helpers.mode_indicator,
      helpers.mux_position_indicator,
      helpers.working_dir_indicator,
      helpers.process_info,
    },

    right_cells = {
      helpers.clock_block,
      helpers.user_indicator,
      helpers.workspace_and_domain_indicator,
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
end

do
  local ankh_generators = require("foodogsquared.ankh.generators")

  local ankh_options = {
    set_default_keybindings = true,
    sources = {
      ankh_generators.nuzlocke_paths,
      ankh_generators.ankh_scripts,
      ankh_generators.default_workspace,
      ankh_generators.spawn_domain_tabs,
    },
  }

  require("foodogsquared.ankh").apply_to_config(config, ankh_options)
end

return config
