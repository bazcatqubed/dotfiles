local M = {}

---Given a predicate and a list, return a boolean value if any of the item
---fulfill the condition.
---@param pred function
---@param list table
---@return boolean
function M.any(pred, list)
  for i, o in pairs(list) do
    if pred(i, o) then
      return true
    end
  end

  return false
end

---Given a predicate and a list, return a boolean value if all of the list
---items fulfill the condition.
---@param pred function
---@param list table
---@return boolean
function M.all(pred, list)
  for i, o in pairs(list) do
    if not pred(i, o) then
      return false
    end
  end

  return true
end

return M
