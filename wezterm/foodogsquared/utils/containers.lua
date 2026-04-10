-- SPDX-FileCopyrightText: 2026 Gabriel Arazas <foodogsquared@foodogsquared.one>
--
-- SPDX-License-Identifier: MIT

local M = {}

local fds_strings = require("foodogsquared.utils.strings")
local wezterm = require("wezterm")

M.prefixes = {
  distrobox = "distrobox:",
  podman = "podman:",
  toolbox = "toolbox:",
}

--- @alias PodmanContainer table
--- @alias PodmanProcesses PodmanContainer[]

--- Return the processes within Podman.
---
--- @return PodmanProcesses?
function M.podman_ps()
  local success, stdout, _ = wezterm.run_child_process({
    "podman",
    "ps",
    "--all",
    "--format",
    "json",
  })

  if success then
    return wezterm.json_parse(stdout)
  end
end

function M.label_names(containers, exec_domains) end

--- Return a list of containers that are currently running.
---
--- @param data PodmanProcesses
--- @return table
function M.podman_list_running_containers(data)
  local containers = {}
  for _, container in ipairs(data) do
    if M.is_podman_container_running(container) then
      containers[container.Id] = container.Names[0]
    end
  end
  return containers
end

--- Checks if the given [PodmanContainer] is running or not (at least from the
--- prerendered [PodmanProcesses]).
---
--- @param container PodmanContainer
--- @return boolean
function M.is_podman_container_running(container)
  return container.State == "running"
end

--- Return a list of container IDs from my custom images.
--- @param data PodmanProcesses
--- @return table
function M.podman_list_custom_images(data)
  local containers = {}
  for _, image in ipairs(data) do
    if fds_strings.starts_with(image.Image, "ghcr.io/bazcatqubed/nixos-config") then
      containers[image.Id] = image.Names[0]
    end
  end
  return containers
end

--- Return a list of container IDs and their names.
--- @param data PodmanProcesses
--- @return table
function M.distrobox_list_images(data)
  local containers = {}

  for _, value in ipairs(data) do
    if M.is_a_distrobox_container(value) then
      goto continue
    end
    if value.Id and value.Names then
      containers[value.Id] = value.Names[1]
    end
    ::continue::
  end

  return containers
end

--- Checks whether the given [PodmanContainer] is a Distrobox container.
---
--- @param container PodmanContainer
--- @return boolean
function M.is_a_distrobox_container(container)
  local labels = container.Labels or {}
  local manager = labels.manager or ""
  return manager ~= "distrobox"
end

--- Return a list of valid toolbox containers' IDs and their names.
--- @param data PodmanProcesses
--- @return table
function M.toolbox_list_images(data)
  local containers = {}
  for _, value in ipairs(data) do
    if not M.is_a_toolbox_container(value) then
      goto continue
    end

    if value.Id and value.Names then
      containers[value.Id] = value.Names[1]
    end
    ::continue::
  end

  return containers
end

--- Checks if the given [PodmanContainer] is a toolbox container.
---
--- @param container PodmanContainer
--- @return boolean
function M.is_a_toolbox_container(container)
  local labels = container.Labels or {}
  local isToolboxContainer = labels["com.github.containers.toolbox"]
    or labels["com.github.debarshiray.toolbox"] -- the old version of the image ID
    or ""

  return isToolboxContainer == "true"
end

return M
