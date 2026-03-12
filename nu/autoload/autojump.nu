# SPDX-FileCopyrightText: 2026 Gabriel Arazas <foodogsquared@foodogsquared.one>
#
# SPDX-License-Identifier: MIT

use foodogsquared/nuzlocke.nu

export alias z = nuzlocke jump
export alias zl = nuzlocke list --link

$env.FDS_NUZLOCKE_EXCLUDE_PATHS = [
  "/nix"
  "/gnu"
  "/dev"
  "/proc"
  ...(nuzlocke config default-exclude-paths)
]

$env.config.menus ++= [
  {
    name: jump_menu
    only_buffer_difference: false
    marker: "↟  "
    type: {
      layout: list
      page_size: 10
    }
    style: {
      text: green
      selected_text: green_reverse
      description_text: yellow
    }
    source: { |buffer, position|
      nuzlocke query $buffer --limit 10 | get path | each { |o| { value: $o } }
    }
  }
]

$env.config.keybindings ++= [
  {
    name: jump
    modifier: control
    keycode: char_y
    mode: [ emacs, vi_normal, vi_insert ]
    event: {
      until: [
        { send: menu name: jump_menu }
        { send: menupagenext }
      ]
    }
  }
]
