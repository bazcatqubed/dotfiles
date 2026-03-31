-- SPDX-FileCopyrightText: 2026 Gabriel Arazas <foodogsquared@foodogsquared.one>
--
-- SPDX-License-Identifier: MIT

vim.pack.add({
  -- Don't forget, I'm with you in the dark.
  { src = "https://github.com/folke/which-key.nvim", version = vim.version.range("^3") },
})

local which_key = require("which-key")

which_key.add({
  { "<leader>f", group = "Pickers" },
  { "<leader>d", group = "Debug" },
})

which_key.setup({
  preset = "helix",
  plugins = {
    presets = { motions = true },
  },
})
