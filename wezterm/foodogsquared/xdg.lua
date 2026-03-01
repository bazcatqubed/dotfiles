-- SPDX-FileCopyrightText: 2025-2026 Gabriel Arazas <foodogsquared@foodogsquared.one>
--
-- SPDX-License-Identifier: MIT

local M = {}

local fds_str = require("foodogsquared/utils/strings")
local wezterm = require("wezterm")

---Given a name of a XDG user directory, return its value. If there's no such
---thing, it will always return the home directory.
---@param n string
---@return string
function M.xdg_user_dir(n)
  return os.getenv("XDG_" .. n .. "_DIR") or wezterm.home_dir
end

---Parse the XDG user dirs file normally found at `$XDG_CONFIG_HOME/user-dirs.dirs`.
---@param path string?
---@return table
function M.parse_xdg_user_dirs(path)
  local dirsfile = path or ((os.getenv("XDG_CONFIG_HOME") or (wezterm.home_dir .. "/.config")) .. "/user-dirs.dirs")
  local res = {}

  io.input(dirsfile)

  local d = io.read("l")
  while d ~= nil do
    if
      fds_str.starts_with(d, "#")
      or fds_str.starts_with(d, " ")
      or fds_str.starts_with(d, "\t")
      or not (fds_str.starts_with(d, "XDG_") or fds_str.ends_with(d, "_DIR"))
    then
      goto continue
    else
      ---@diagnostic disable-next-line: missing-parameter
      local data = string.split(d, "=", 1)
      local basedir = data[1]:gsub("XDG_", ""):gsub("_DIR", "")
      res[basedir] = data[2]:gsub('^%s*"', ""):gsub('"', ""):gsub("%$(%w+)", os.getenv)
    end

    ::continue::
    d = io.read("l")
  end

  return res
end

return M
