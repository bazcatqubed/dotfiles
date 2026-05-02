-- SPDX-FileCopyrightText: 2023-2025 Gabriel Arazas <foodogsquared@foodogsquared.one>
--
-- SPDX-License-Identifier: MIT

-- A bunch of plugins for programming languages support.
local plugins = {
  -- EditorConfig plugin.
  "https://github.com/editorconfig/editorconfig-vim",

  -- Nix
  "https://github.com/LnL7/vim-nix",

  -- Dhall
  "https://github.com/vmchale/dhall-vim",

  -- Zig
  "https://github.com/ziglang/zig.vim",

  -- Justfiles
  "https://github.com/NoahTheDuke/vim-just",

  -- Tridactyl
  "https://github.com/tridactyl/vim-tridactyl",
}

-- TidalCycles
if os.execute("sclang -v") ~= nil then
  table.insert(plugins, "https://github.com/tidalcycles/vim-tidal")
end

vim.pack.add(plugins)
