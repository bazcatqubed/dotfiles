-- SPDX-FileCopyrightText: 2025 Gabriel Arazas <foodogsquared@foodogsquared.one>
--
-- SPDX-License-Identifier: MIT

local M = {}

function M:to_bool(v)
  return not not v
end

return M
