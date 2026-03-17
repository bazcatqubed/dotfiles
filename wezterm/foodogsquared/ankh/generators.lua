--- A set of generators for Ankh. All functions here have a callback signature
--- of [AnkhOptions], [Wezterm.Window], and [Wezterm.Pane] in
--- that order.

--- @export
local M = {}

function M.default_workspace(config, pluginConfig)
  local wezterm = require("wezterm")

  local default_ws = config.default_workspace or "default"
  return {
    {
      label = default_ws,
      priority = 10000,
      action = wezterm.action.SwitchToWorkspace {
        name = default_ws
      },
    }
  }
end

--- Generator for a bunch of Ankh-specific layout files which is just a
--- [SpawnCommand].
function M.ankh_scripts(pluginConfig, window, pane)
  local wezterm = require("wezterm")
  local foodogsquared_utils = require("foodogsquared.utils")
  local foodogsquared_shell = require("foodogsquared.utils.shell")
  local EXTENSION = ".lua"

  local layout_dir = pluginConfig.layout_dir or (wezterm.config_dir .. "/ankh/layouts")
  local layout_files = wezterm.serde.json_decode(
    foodogsquared_shell.capture_nu(string.format("glob '%s/*%s' | to json", layout_dir, EXTENSION))
  )

  for i, f in ipairs(layout_files) do
    local layout_fn, err = dofile(f)

    if err or (layout_fn == nil) then
      goto continue
    end

    local label = foodogsquared_utils.basename(f):gsub(string.format("%s$", EXTENSION), "")

    layout_files[i] = {
      label = wezterm.format({
        { Foreground = { AnsiColor = "Red" } },
        { Text = "[Ankh Layout]" },
        "ResetAttributes",
        { Text = " " .. label },
      }),
      id = "ankh:" .. label,
      priority = 1500,
      action = layout_fn,
    }

    ::continue::
  end

  return layout_files
end

--- Generator for Nuzlocke paths.
function M.nuzlocke_paths()
  local wezterm = require("wezterm")
  local foodogsquared_utils = require("foodogsquared.utils")
  local paths = wezterm.serde.json_decode(
    require("foodogsquared.utils.shell")
    .capture_nu("use foodogsquared/nuzlocke.nu; nuzlocke list | get path | reverse | to json")
  )

  for i, v in ipairs(paths) do
    local id = "nuzlocke:" .. foodogsquared_utils.basename(v)
    paths[i] = {
      id = id,
      label = wezterm.format({
        { Foreground = { AnsiColor = "Green" } },
        { Text = "[Nuzlocke]" },
        "ResetAttributes",
        { Text = " " .. v },
      }),
      action = wezterm.action.SwitchToWorkspace {
        name = id,
        spawn = { cwd = v }
      },
      priority = 750 + i,
    }
  end

  return paths
end

return M
