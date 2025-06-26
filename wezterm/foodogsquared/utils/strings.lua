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

return M
