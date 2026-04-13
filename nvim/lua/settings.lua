-- SPDX-FileCopyrightText: 2023-2025 Gabriel Arazas <foodogsquared@foodogsquared.one>
--
-- SPDX-License-Identifier: MIT

local module = {}

function module.setup()
  vim.g["mapleader"] = " "
  vim.g["maplocalleader"] = ","
  vim.g["syntax"] = true

  -- Editor configuration
  vim.opt.completeopt = { "menuone", "noselect" }
  vim.opt.termguicolors = true
  vim.opt.encoding = "utf-8"
  vim.opt.number = true
  vim.opt.relativenumber = true
  vim.opt.cursorline = true
  vim.opt.expandtab = true
  vim.opt.shiftwidth = 4
  vim.opt.tabstop = 4
  vim.opt.conceallevel = 1
  vim.opt.list = true
  vim.opt.listchars = { tab = "↦ ", trail = "·" }
  vim.opt_local.spell = true
  vim.opt.smartindent = true

  -- Basic keybindings
  vim.keymap.set("n", "<leader>x", function()
    vim.bo.buflisted = false
    vim.api.nvim_buf_delete(0, { unload = true, force = true })
  end, { desc = "Delete buffer" })
  vim.keymap.set("i", "jk", "<Esc>", { desc = "Escape" })

  vim.keymap.set("n", "gj", function ()
    vim.diagnostic.jump({ count = vim.v.count1, on_jump = function()
      vim.diagnostic.open_float({
        scope = "cursor",
        severity = { min = vim.diagnostic.severity.WARN },
        severity_sort = {
          reverse = true,
        },
      })
    end })
  end, { desc = "Go to next diagnostic" })

  vim.keymap.set("n", "gk", function ()
    vim.diagnostic.jump({ count = -vim.v.count1, on_jump = function()
      vim.diagnostic.open_float({
        scope = "cursor",
        severity = { min = vim.diagnostic.severity.WARN },
        severity_sort = {
          reverse = true,
        },
      })
    end, })
  end, { desc = "Go to previous diagnostic" })

  vim.keymap.del("n", "gcc")
end

return module
