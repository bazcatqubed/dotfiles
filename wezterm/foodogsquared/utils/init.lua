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
--- @return boolean
function M.executable(exe)
  return os.execute(exe)
end

--- Split a string given its input and a separator.
---
--- @param s string
--- @param sep string
--- @return table
function M.string_split(s, sep)
  if sep == nil then
    sep = "%s"
  end

  local t = {}
  for str in string.gmatch(s, "(([^" .. sep .. "]+)") do
    table.insert(t, str)
  end

  return t
end

--- Returns a boolean if the given value is empty.
--- @param s any
--- @return boolean
function M.is_empty(s)
  return s == nil or s == ""
end

return M
