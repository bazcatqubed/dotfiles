-- SPDX-FileCopyrightText: 2023-2025 Gabriel Arazas <foodogsquared@foodogsquared.one>
--
-- SPDX-License-Identifier: MIT

vim.pack.add({
  "https://github.com/nvim-tree/nvim-web-devicons",
  "https://github.com/nvim-lualine/lualine.nvim",
  "https://github.com/rebelot/kanagawa.nvim",
})

vim.cmd.colorscheme("kanagawa")

require("lualine").setup({
  icons_enabled = true,
  always_divide_middle = true,
  globalstatus = true,

  -- Disable the section separators.
  section_separators = {
    left = "",
    right = "",
  },

  sections = {
    lualine_a = { "mode" },
    lualine_c = {
      {
        "filename",
        newline_status = true,
        shorting_target = 10,
        path = 1,
      },
    },
    lualine_z = { "location" },
  },
})
