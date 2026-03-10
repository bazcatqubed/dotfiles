-- SPDX-FileCopyrightText: 2025-2026 Gabriel Arazas <foodogsquared@foodogsquared.one>
--
-- SPDX-License-Identifier: MIT

local M = {}

local fds_str = require("foodogsquared/utils/strings")
local wezterm = require("wezterm")

--- Given a name of a XDG user directory including the user base directories
--- (e.g., XDG_DATA_HOME, XDG_CACHE_HOME), return its value. If there's no such
--- value for the XDG user directory, it will always default to the home
--- directory.
---@param n string
---@return string
function M.xdg_user_dir(n)
  if n == "XDG_CONFIG_HOME" then
    return os.getenv("XDG_CONFIG_HOME") or (wezterm.home_dir .. "/.config")
  elseif n == "XDG_DATA_HOME" then
    return os.getenv("XDG_DATA_HOME") or (wezterm.home_dir .. "/.local/share")
  elseif n == "XDG_CACHE_HOME" then
    return os.getenv("XDG_CACHE_HOME") or (wezterm.home_dir .. "/.cache")
  elseif n == "XDG_STATE_HOME" then
    return os.getenv("XDG_STATE_HOME") or (wezterm.home_dir .. "/.local/state")
  else
    return os.getenv("XDG_" .. n .. "_DIR") or wezterm.home_dir
  end
end

---Parse the XDG user dirs file normally found at `$XDG_CONFIG_HOME/user-dirs.dirs`.
---@param path string?
---@return table
function M.parse_xdg_user_dirs(path)
  local dirsfile = path or (M.xdg_user_dir("XDG_CONFIG_HOME") .. "/user-dirs.dirs")
  local res = {}

  io.input(dirsfile)

  local d = io.read("l")
  while d ~= nil do
    if
      d:starts_with("#")
      or d:starts_with(" ")
      or d:starts_with("\t")
      or (d:starts_with("XDG_") and d:ends_with("_DIR"))
    then
      goto continue
    else
      ---@diagnostic disable-next-line: missing-parameter
      local data = d:split("=", 1)
      local basedir = data[1]:gsub("^XDG_", ""):gsub("_DIR$", "")
      res[basedir] = data[2]:gsub('^%s*"', ""):gsub('"', ""):gsub("%$(%w+)", os.getenv)
    end

    ::continue::
    d = io.read("l")
  end

  return res
end

return M
