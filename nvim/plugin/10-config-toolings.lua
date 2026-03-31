-- SPDX-FileCopyrightText: 2023-2025 Gabriel Arazas <foodogsquared@foodogsquared.one>
--
-- SPDX-License-Identifier: MIT

vim.pack.add({
  "https://github.com/charm-and-friends/freeze.nvim",
})

require("freeze").setup({
  command = "freeze",
  show_line_numbers = true,
  output = function()
    return vim.env.XDG_PICTURES_DIR .. "/Code/" .. os.date("%F-%T") .. "-freeze.png"
  end,
})

vim.keymap.set("v", "<leader>Cc", "<cmd>Freeze<CR>", { desc = "Screenshot code" })
