-- SPDX-FileCopyrightText: 2021-2025 Gabriel Arazas <foodogsquared@foodogsquared.one>
--
-- SPDX-License-Identifier: MIT

-- vim: shiftwidth=2

require("settings").setup()

if vim.g.neovide then
  require("foodogsquared/neovide").setup()
end
