# SPDX-FileCopyrightText: 2026 Gabriel Arazas <foodogsquared@foodogsquared.one>
#
# SPDX-License-Identifier: MIT

use foodogsquared/utils.nu ['search-paths common-converter']

let env_converter = search-paths common-converter ':'

$env.ENV_CONVERSIONS = $env.ENV_CONVERSIONS | merge deep --strategy=append {
  XDG_DATA_DIRS: $env_converter
  XDG_CONFIG_DIRS: $env_converter
}
