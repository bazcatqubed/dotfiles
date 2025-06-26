-- SPDX-FileCopyrightText: 2023-2025 Gabriel Arazas <foodogsquared@foodogsquared.one>
--
-- SPDX-License-Identifier: MIT

return {
  {
    "charm-and-friends/freeze.nvim",
    config = function ()
      require("freeze").setup {
        command = "freeze",
        show_line_numbers = true,
        output = function ()
          return vim.env.XDG_PICTURES_DIR .. "/Code/" .. os.date("%F-%T") .. "-freeze.png"
        end
      }
    end,
    keys = {
      { "<leader>Cc", "<cmd>Freeze<CR>", mode = "v", desc = "Screenshot code" },
    },
  }
}
