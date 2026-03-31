-- SPDX-FileCopyrightText: 2023-2025 Gabriel Arazas <foodogsquared@foodogsquared.one>
--
-- SPDX-License-Identifier: MIT

vim.pack.add({
  -- The main star of the show.
  "https://github.com/folke/snacks.nvim",
})

require("snacks").setup({
  ---@type snacks.Config
  bigfile = { enabled = true },
  explorer = { enabled = true },
  indent = {
    enabled = true,
    char = "┊",

    scope = {
      underline = true,
    },

    chunk = {
      enabled = true,
    },
  },
  input = { enabled = true },
  notifier = { enabled = true },
  git = { enabled = true },
  lazygit = {
    enabled = vim.fn.executable("lazygit") == 1,
  },
  picker = { enabled = true },
  quickfile = { enabled = true },
  rename = { enabled = true },
  scope = { enabled = true },
  statuscolumn = { enabled = true },
  toggle = {
    enabled = true,
    which_key = pcall(require, "which-key"),
  },
  words = { enabled = true },
  zen = {
    enabled = true,
    zoom = {
      toggles = {
        dim = true,
        git_signs = false,
        diagnostics = false,
        inlay_hints = false,
      },
      win = { width = 0 },
    },
  },
})

local function picker_prefix(bind)
  return "<leader>f" .. bind
end

vim.keymap.set("n", picker_prefix("f"), Snacks.picker.files, { desc = "Select files in root directory" })
vim.keymap.set("n", picker_prefix("F"), function()
  Snacks.picker.files({ cwd = vim.fn.expand("%:p:h") })
end, { desc = "Select files in current directory" })

vim.keymap.set("n", picker_prefix("g"), Snacks.picker.grep, { desc = "Grep in project directory" })
vim.keymap.set("n", picker_prefix("G"), function ()
  Snacks.picker.grep({ cwd = vim.fn.expand("%:p:h") })
end, { desc = "Grep in current directory" })

vim.keymap.set("n", picker_prefix("b"), Snacks.picker.buffers, { desc = "List all opened buffers" })

vim.keymap.set("n", "<leader>s", function()
  Snacks.picker.lsp_symbols({
    layout = {
      preset = "vscode",
      preview = "main",
    },
  })
end, { desc = "List all symbols for the current file" })
vim.keymap.set("n", "<leader>S", function()
  Snacks.picker.lsp_workspace_symbols({
    layout = { preset = "vscode" },
    tree = true,
  })
end, { desc = "List all symbols for the workspace" })

vim.keymap.set("n", "<leader>c", Snacks.picker.diagnostics, { desc = "List all diagnostics" })
vim.keymap.set("n", "<leader>C", Snacks.picker.diagnostics_buffer, { desc = "List current diagnostics" })

vim.keymap.set("n", "<leader>g", Snacks.lazygit.open, { desc = "Open Lazygit" })
vim.keymap.set("n", picker_prefix("A"), function ()
  Snacks.picker.resume()
end, { desc = "Resume last search" })
vim.keymap.set("n", picker_prefix("h"), Snacks.picker.help, { desc = "Help pages" })
vim.keymap.set("n", picker_prefix("m"), Snacks.picker.man, { desc = "Manpages" })
