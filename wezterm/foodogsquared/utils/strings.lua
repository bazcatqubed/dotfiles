-- SPDX-FileCopyrightText: 2025 Gabriel Arazas <foodogsquared@foodogsquared.one>
--
-- SPDX-License-Identifier: MIT

--- A bunch of string-related utilities. A lot of them are based from
--- http://lua-users.org/wiki/StringRecipes
local M = {}

--- Indicates whether `str` starts with `start`.
--- @param str string
--- @param start string
--- @return boolean
function M.starts_with(str, start)
   return str:sub(1, #start) == start
end

--- Indicates whether `str` ends with `ending`.
--- @param str string
--- @param ending string
--- @return boolean
function M.ends_with(str, ending)
   return ending == "" or str:sub(-#ending) == ending
end

---Returns an escaped version of the string normally used for string functions
---requiring a pattern string (e.g., `gsub`).
---@param str string
---@return string
function M.escape_pattern(str)
  return str:gsub("([^%w])", "%%%1")
end

--- Split a string given its input and a separator.
---
--- @param s string
--- @param sep string
--- @return table
function M.split_by(s, sep)
  if sep == nil then
    sep = "%s"
  end

  local t = {}
  for str in string.gmatch(s, "(([^" .. sep .. "]+)") do
    table.insert(t, str)
  end

  return t
end

return M
