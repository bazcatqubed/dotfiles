local wezterm = require("wezterm")

return function (pluginConfig, window, pane)
  local cwd_uri = pane:get_current_working_dir()

  local inner_tab, inner_pane, inner_window = window:mux_window():spawn_tab({
    cwd = cwd_uri.file_path,
    domain = pluginConfig.default_domain or nil,
  })

  local inner_inner_pane = inner_pane:split({
    args = { "lazygit" },
    direction = "Right",
    size = 0.333,
    top_level = true,
  })

  inner_inner_pane:split({
    direction = "Bottom",
  })
end
