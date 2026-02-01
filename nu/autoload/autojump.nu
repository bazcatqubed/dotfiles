# SPDX-FileCopyrightText: 2026 Gabriel Arazas <foodogsquared@foodogsquared.one>
#
# SPDX-License-Identifier: MIT

use foodogsquared/nuzlocke.nu

alias z = nuzlocke jump
alias zl = nuzlocke list

$env.config.hooks.env_change = $env.config.hooks.env_change | merge deep --strategy=append {
  PWD: [
    { |before, after| nuzlocke add $after }
  ]
}

$env.config.menus ++= [
  {
    name: jump_menu
    only_buffer_difference: false
    marker: "| "
    type: {
      layout: columnar
      page_size: 20
    }
    style: {
      text: green
      selected_text: green_reverse
      description_text: yellow
    }
    source: { |buffer, position|
      nuzlocke search ($buffer | split words | last)  --limit 20 | each { |o| { value: $o } }
    }
  }
]

$env.config.keybindings ++= [
  {
    name: jump
    modifier: control
    keycode: char_o
    mode: [ emacs, vi_normal, vi_insert ]
    event: {
      until: [
        { send: menu name: jump_menu }
        { send: menupagenext }
      ]
    }
  }
]
