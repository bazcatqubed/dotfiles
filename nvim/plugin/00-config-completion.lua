-- SPDX-FileCopyrightText: 2023-2025 Gabriel Arazas <foodogsquared@foodogsquared.one>
--
-- SPDX-License-Identifier: MIT

vim.api.nvim_create_autocmd("PackChanged", {
  callback = function(ev)
    local name, kind = ev.data.spec.name, ev.data.kind
    if name == "blink.cmp" and (kind == "install" or kind == "update") then
      vim.system({ "cargo", "build", "--release" }, { cwd = ev.data.path })
    end
  end,
})

vim.pack.add({
  "https://github.com/saghen/blink.lib",
  "https://github.com/saghen/blink.cmp",

  -- Be lazy with the preset LSP configurations.
  "https://github.com/neovim/nvim-lspconfig",
})

require("blink.cmp").setup({
  completion = {
    accept = {
      auto_brackets = {
        enabled = true,
        semantic_token_resolution = { enabled = true },
      },
    },
  },

  snippets = {
    preset = "luasnip",
  },
})

local servers = {
  "ansiblels",
  "bashls",
  "blueprint_ls",
  "pyright",
  "lua_ls",
  "rust_analyzer",
  "gopls",
  "nil_ls",
  "nushell",
  "systemd_lsp",
  "vale_lsp",
  "syntax_tree",
  "stylua",
  "mesonlsp",
  "cmake",
  "scheme_langserver",
  "guile_ls",
  "harper_ls",
}

for _, value in ipairs(servers) do
  vim.lsp.enable(value)
end
