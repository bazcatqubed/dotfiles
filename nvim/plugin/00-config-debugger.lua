-- SPDX-FileCopyrightText: 2026 Gabriel Arazas <foodogsquared@foodogsquared.one>
--
-- SPDX-License-Identifier: MIT

vim.pack.add({
  "https://github.com/rcarriga/nvim-dap-ui",
  "https://github.com/nvim-neotest/nvim-nio",
  "https://github.com/mfussenegger/nvim-dap",
  "https://github.com/theHamsta/nvim-dap-virtual-text",
})

local function b(bind)
  return "<Leader>d" .. bind
end

local dap = require("dap")
vim.keymap.set("n", b("b"), dap.toggle_breakpoint, { desc = "Toggle breakpoint" })
vim.keymap.set("n", b("B"), function()
  dap.toggle_breakpoint(nil, nil, vim.fn.input("Message: "))
end, { desc = "Toggle breakpoint with message" })
vim.keymap.set("n", b("n"), dap.continue, { desc = "Continue" })
vim.keymap.set("n", b("d"), dap.terminate, { desc = "Terminate session" })
vim.keymap.set("n", b("j"), dap.step_into, { desc = "Step into" })
vim.keymap.set("n", b("k"), dap.step_out, { desc = "Step out" })
vim.keymap.set("n", b("l"), dap.step_over, { desc = "Step over" })
vim.keymap.set("n", b("r"), dap.restart, { desc = "Restart" })
vim.keymap.set("n", b("."), dap.run_last, { desc = "Run last configuration" })

vim.keymap.set("n", "<F5>", dap.continue, { desc = "Continue" })
vim.keymap.set("n", "<F9>", dap.toggle_breakpoint, { desc = "Toggle breakpoint" })
vim.keymap.set("n", "<F10>", dap.step_over, { desc = "Step over" })
vim.keymap.set("n", "<F11>", dap.step_into, { desc = "Step into" })
vim.keymap.set("n", "<F12>", dap.step_out, { desc = "Step out" })
