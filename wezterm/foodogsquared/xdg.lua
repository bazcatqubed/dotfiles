local M = {}

local wezterm = require("wezterm")

---Given a name of a XDG user directory, return its value. If there's no such
---thing, it will always return the home directory.
---@param n string
---@return string
function M.xdg_user_dir(n)
  return os.getenv("XDG_" .. n .. "_DIR") or wezterm.home_dir
end

return M
