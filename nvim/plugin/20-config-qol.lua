-- SPDX-FileCopyrightText: 2025 Gabriel Arazas <foodogsquared@foodogsquared.one>
--
-- SPDX-License-Identifier: MIT

local _fds = require("../foodogsquared")

vim.pack.add({
  -- Forcing your editor to socialize with the langauges more.
  "https://github.com/kkharji/sqlite.lua",
  "https://github.com/Olical/conjure",

  "https://github.com/nvim-tree/nvim-web-devicons",

  -- Run like the red echidna.
  "https://github.com/folke/flash.nvim",

  -- Put some oil on.
  "https://github.com/stevearc/oil.nvim",

  -- Symbolic explorer.
  "https://github.com/bassamsdata/namu.nvim"
})

require("oil").setup({
  default_file_explorer = true,
  columns = { "icon", "permissions" },
  view_options = {
    show_hidden = true,
  },
})

vim.keymap.set({ "n" }, "-", function ()
  require("oil").open()
end, { desc = "Open file explorer on current directory" })
vim.keymap.set({ "n" }, "<C-->", function()
  require("oil").open(vim.fn.getcwd())
end, { desc = "Open file explorer on project directory" })

local flash = require("flash")
vim.keymap.set({ "n", "x", "v" }, "s", flash.jump, { desc = "Jump" })
vim.keymap.set({ "n", "x", "v" }, "S", flash.treesitter, { desc = "Treesitter node selection" })
vim.keymap.set({ "n", "x" }, "<C-s>", flash.treesitter_search, { desc = "Treesitter node search" })
vim.keymap.set({ "n", "x", "o" }, "<c-space>", function()
  flash.treesitter({
    actions = {
      ["<c-space>"] = "next",
      ["<BS>"] = "prev",
    },
  })
end, { desc = "Treesitter incremental selection" })

vim.keymap.set({ "n", "i", "v" }, "<C-m>", "<cmd>Namu symbols<CR>", { desc = "List symbols" })
vim.keymap.set({ "n", "i", "v" }, "<C-S-m>", "<cmd>Namu workspace<CR>", { desc = "List symbols workspace-wide" })
