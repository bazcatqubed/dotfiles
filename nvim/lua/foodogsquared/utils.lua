-- SPDX-FileCopyrightText: 2025 Gabriel Arazas <foodogsquared@foodogsquared.one>
--
-- SPDX-License-Identifier: MIT

local M = {}

--- Returns the Lua object as a truthy value.
---
--- @param v? any
--- @return boolean
function M.to_bool(v)
  return not not v
end

return M
