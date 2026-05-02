-- SPDX-FileCopyrightText: 2023-2025 Gabriel Arazas <foodogsquared@foodogsquared.one>
--
-- SPDX-License-Identifier: MIT

local module = {}

local function jump(count)
  return vim.diagnostic.jump({ count = count, on_jump = function(diagnostic, bufnr)
    if not diagnostic then return end

    vim.diagnostic.open_float({
      namespace = diagnostic.namespace,
      bufnr = bufnr,
      scope = "cursor",
      severity = { min = vim.diagnostic.severity.WARN },
      severity_sort = {
        reverse = true,
      },
      focus = false,
    })
  end })
end

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
    vim.api.nvim_buf_delete(0, { force = true })
  end, { desc = "Delete buffer" })
  vim.keymap.set("i", "jk", "<Esc>", { desc = "Escape" })

  vim.keymap.set("n", "gj", function ()
    jump(vim.v.count1)
  end, { desc = "Go to next diagnostic" })

  vim.keymap.set("n", "gk", function ()
    jump(-vim.v.count1)
  end, { desc = "Go to previous diagnostic" })

  vim.keymap.del("n", "gcc")
  vim.diagnostic.config({
    severity_sort = { reverse = true },
    severity = { min = vim.diagnostic.severity.INFO },
  })
end

return module
