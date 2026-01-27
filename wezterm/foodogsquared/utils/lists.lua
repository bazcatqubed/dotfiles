-- SPDX-FileCopyrightText: 2025-2026 Gabriel Arazas <foodogsquared@foodogsquared.one>
--
-- SPDX-License-Identifier: MIT

local M = {}

---Given a predicate and a list, return a boolean value if any of the item
---fulfill the condition.
---@param pred function
---@param list table
---@return boolean
function M.any(pred, list)
  for i, o in pairs(list) do
    if pred(i, o) then
      return true
    end
  end

  return false
end

---Given a predicate and a list, return a boolean value if all of the list
---items fulfill the condition.
---@param pred function
---@param list table
---@return boolean
function M.all(pred, list)
  for i, o in pairs(list) do
    if not pred(i, o) then
      return false
    end
  end

  return true
end

---Return a new table with its items reversed.
---@param t table
---@return table
function M.reverse(t)
  local nt = {}
  local items = #t

  for index, value in ipairs(t) do
    nt[items + 1 - index] = value
  end

  return nt
end

return M
