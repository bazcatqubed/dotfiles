# SPDX-FileCopyrightText: 2026 Gabriel Arazas <foodogsquared@foodogsquared.one>
#
# SPDX-License-Identifier: MIT

# A Nushell module that simply deals with XDG base directories.

export def get_data_dir [] {
  $env.XDG_DATA_HOME? | default $'($env.HOME)/.local/share'
}

export def get_config_dir [] {
  $env.XDG_CONFIG_HOME? | default $'($env.HOME)/.config'
}

export def get_cache_dir [] {
  $env.XDG_CACHE_HOME? | default $'($env.HOME)/.cache'
}
