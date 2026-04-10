-- SPDX-FileCopyrightText: 2025 Gabriel Arazas <foodogsquared@foodogsquared.one>
--
-- SPDX-License-Identifier: MIT

local fds_containers = require("foodogsquared.utils.containers")
local fds_strings = require("foodogsquared.utils.strings")
local utils = require("foodogsquared.utils.init")
local wezterm = require("wezterm")
local M = {}

--- Return a list of container IDs from my custom images.
--- @param data table
--- @return table
local function podman_list_custom_images(data)
  local containers = {}
  for _, image in ipairs(data) do
    if fds_strings.starts_with(image.Image, "ghcr.io/bazcatqubed/nixos-config") then
      containers[image.Id] = image.Names[0]
    end
  end
  return containers
end

local function make_podman_label_func(id)
  return function(name)
    local _, stdout, _ = wezterm.run_child_process({
      "podman",
      "inspect",
      "--format",
      "{{ .State.Running }}",
      id,
    })
    local running = stdout == "true\n"
    local color = running and "Green" or "Red"
    return wezterm.format({
      { Text = "Podman container named " },
      { Foreground = { AnsiColor = color } },
      { Text = name },
    })
  end
end

local function make_systemd_nspawn_label_func(machine)
  return function(_)
    return wezterm.format({
      { Foreground = { AnsiColor = "Green" } },
      { Text = string.format("%s (%s)", machine.os, machine.version) },
    })
  end
end

local function make_podman_fixup_func(id)
  return function(cmd)
    cmd.args = cmd.args or { "/bin/sh" }
    local wrapped = {
      "podman",
      "exec",
      "-it",
      id,
    }
    for _, arg in ipairs(cmd.args) do
      table.insert(wrapped, arg)
    end

    cmd.args = wrapped
    return cmd
  end
end

local function make_podman_custom_image_fixup_func(id)
  return function(cmd)
    cmd.args = cmd.args or { "/bin/sh" }
    local wrapped = {
      "podman",
      "run",
      "-it",
      id,
    }
    for _, arg in ipairs(cmd.args) do
      table.insert(wrapped, arg)
    end

    cmd.args = wrapped
    return cmd
  end
end

local function make_distrobox_fixup_func(name)
  return function(cmd)
    local wrapped = {
      "distrobox",
      "enter",
      name,
    }

    cmd.args = wrapped
    return cmd
  end
end

local function make_toolbox_fixup_func(name)
  return function(cmd)
    local wrapped = {
      "toolbox",
      "enter",
      name,
    }

    cmd.args = wrapped
    return cmd
  end
end

local function make_systemd_nspawn_fixup_func(name)
  return function(cmd)
    local wrapped = {
      "machinectl",
      "shell",
      name,
    }

    cmd.args = wrapped
    return cmd
  end
end

--- Given a config builder, apply the following configuration specifically set
--- by this module.
--- @param config table
--- @return table
function M.apply_to_config(config)
  config.exec_domains = config.exec_domains or {}

  if os.execute("systemd-run --version") then
    table.insert(
      config.exec_domains,
      wezterm.exec_domain("scoped", function(cmd)
        local env = cmd.set_environment_variables
        local ident = "wezterm-pane-" .. env.WEZTERM_PANE .. "-on-" .. utils.basename(env.WEZTERM_UNIX_SOCKET)

        local wrapped = {
          "systemd-run",
          "--user",
          "--scope",
          "--description=Shell started by wezterm",
          "--same-dir",
          "--collect",
          "--unit=" .. ident,
        }

        for _, arg in ipairs(cmd.args or { os.getenv("SHELL") }) do
          table.insert(wrapped, arg)
        end

        cmd.args = wrapped

        return cmd
      end, "systemd-run environment")
    )

    config.default_domain = "scoped"
  end
  ::end_systemd_scope::

  if os.execute("podman --version") then
    local containers = fds_containers.podman_ps()

    if containers == nil then
      goto end_podman
    end

    for id, name in pairs(fds_containers.podman_list_running_containers(containers)) do
      table.insert(
        config.exec_domains,
        wezterm.exec_domain("podman:" .. name, make_podman_fixup_func(id), make_podman_label_func(id))
      )
    end

    for id, name in pairs(podman_list_custom_images(containers)) do
      table.insert(
        config.exec_domains,
        wezterm.exec_domain("fds-image:" .. name, make_podman_custom_image_fixup_func(id), make_podman_label_func(id))
      )
    end

    if os.execute("distrobox --version") then
      for id, name in pairs(fds_containers.distrobox_list_images(containers)) do
        table.insert(
          config.exec_domains,
          wezterm.exec_domain("distrobox:" .. name, make_distrobox_fixup_func(name), make_podman_label_func(id))
        )
      end
    end

    if os.execute("toolbox --version") then
      for id, name in pairs(fds_containers.toolbox_list_images(containers)) do
        table.insert(
          config.exec_domains,
          wezterm.exec_domain("toolbox:" .. name, make_toolbox_fixup_func(name), make_podman_label_func(id))
        )
      end
    end
  end
  ::end_podman::

  if os.execute("machinectl --version") and os.execute("systemd-nspawn --version") then
    local success, stdout, _ = wezterm.run_child_process({
      "machinectl",
      "list",
      "--output",
      "json",
    })

    if not success then
      goto end_systemd_nspawn
    end

    local machines = wezterm.json_parse(stdout)

    for _, machine in ipairs(machines) do
      local name = machine.machine
      table.insert(
        config.exec_domains,
        wezterm.exec_domain(
          "systemd-nspawn:" .. name,
          make_systemd_nspawn_fixup_func(name),
          make_systemd_nspawn_label_func(machine)
        )
      )
    end
  end
  ::end_systemd_nspawn::

  return config
end

return M
