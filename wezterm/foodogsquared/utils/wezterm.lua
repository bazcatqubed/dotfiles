--- Wezterm-specific functions.
local M = {}

---Return the active pane with metadata.
---@param tab MuxPane
---@return PaneInformation
function M.active_pane_with_info(tab)
  for _, pane in ipairs(tab:panes_with_info()) do
    if pane.is_active then
      return pane
    end
  end
end

---Return the active tab with metadata.
---@param window MuxWindow
---@return PaneInformation
function M.active_tab_with_info(window)
  for _, tab in ipairs(window:tabs_with_info()) do
    if tab.is_active then
      return tab
    end
  end
end

return M
