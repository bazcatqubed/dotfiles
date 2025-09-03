-- SPDX-FileCopyrightText: 2025 Gabriel Arazas <foodogsquared@foodogsquared.one>
--
-- SPDX-License-Identifier: MIT

local M = {}

--- Return the basename of a given filepath equivalent to `basename(3)`.
---
--- @param s string
--- @return string
function M.basename(s)
  return string.gsub(s, '(.*[/\\])(.*)', '%2')
end

--- Return a boolean indicating if the given executable is found in $PATH.
---
--- @param exe? string
--- @return boolean?
function M.executable(exe)
  return os.execute(exe)
end

--- Returns a boolean if the given value is empty.
--- @param s any
--- @return boolean
function M.is_empty(s)
  return s == nil or s == ""
end

---Return the user name from the current Wezterm environment.
---@return string
function M.get_user()
  return os.getenv("USER") or os.getenv("LOGNAME") or os.getenv("USERNAME") or nil
end

---Create a conditional where it returns either of the given values whether the
---condition returns true or false.
---@param cond boolean
---@param T any
---@param F any
---@return any
function M.cond(cond, T, F)
  if cond then return T else return F end
end

return M
