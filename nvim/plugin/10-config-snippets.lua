-- SPDX-FileCopyrightText: 2023-2025 Gabriel Arazas <foodogsquared@foodogsquared.one>
--
-- SPDX-License-Identifier: MIT

-- Snippets engine. A must have for me.
vim.api.nvim_create_autocmd("PackChanged", {
  callback = function(ev)
    local name, kind = ev.data.spec.name, ev.data.kind
    if name == "luasnip" and (kind == "install" or kind == "update") then
      vim.system({ "make", "install_jsregexp" }, { cwd = ev.data.path })
    end
  end,
})

vim.pack.add({
  "https://github.com/rafamadriz/friendly-snippets",
  { src = "https://github.com/L3MON4D3/LuaSnip", version = vim.version.range("^2") },
})

require("luasnip.loaders.from_vscode").lazy_load()
require("luasnip.loaders.from_lua").lazy_load()

local ls = require("luasnip")
local types = require("luasnip.util.types")
ls.config.set_config({
  history = true,
  update_events = "TextChanged,TextChangedI",
  ext_opts = {
    [types.choiceNode] = {
      active = {
        virt_text = { { "<- Current choice", "Comment" } },
      },
    },
  },
})

vim.keymap.set({ "i", "s" }, "<c-j>", function()
  if ls.jumpable(1) then
    ls.jump(1)
  end
end)

vim.keymap.set({ "i", "s" }, "<c-k>", function()
  if ls.jumpable(-1) then
    ls.jump(-1)
  end
end)

vim.keymap.set({ "i", "s" }, "<c-l>", function()
  if ls.expand_or_jumpable() then
    ls.expand_or_jump()
  end
end)

vim.keymap.set({ "i", "s" }, "<c-u>", function()
  require("luasnip.extras.select_choice")()
end)
