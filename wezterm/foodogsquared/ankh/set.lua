-- SPDX-FileCopyrightText: 2026 Gabriel Arazas <foodogsquared@foodogsquared.one>
--
-- SPDX-License-Identifier: MIT

--- @export
local M = {}

do
  local setmt = {}

  --- Creates a new instance of [AnkhSet].
  ---
  --- @return AnkhSet
  function setmt:new()
    local o = {}
    setmetatable(o, self)
    self.__index = self

    return o
  end

  --- Returns an iterator starting on the highest priority of each label.
  ---
  --- @return iterator
  function setmt:ordered_pairs()
    local keys = {}
    for k, v in pairs(self) do
      keys[#keys + 1] = { priority = v.priority, name = k }
    end
    table.sort(keys, function(a, b)
      return a.priority > b.priority
    end)

    local i = 0
    return function()
      i = i + 1
      if keys[i] then
        return keys[i].name, self[keys[i].name]
      end
    end
  end

  M.Set = setmt -- AnkhSet
end

do
  local labelmetatable = {}

  function labelmetatable.__add(a, b)
    for k, v in ipairs(b) do
      if type(v) == "table" and type(a[k]) == "table" then
        labelmetatable.__add(a, b)
      else
        a[k] = v
      end
    end

    return a
  end

  function labelmetatable.__lt(a, b)
    return a.priority < b.priority
  end

  function labelmetatable.__le(a, b)
    return a.priority <= b.priority
  end

  function labelmetatable.__eq(a, b)
    return a.label == b.label and a.priority == b.priority
  end

  --- Creates a new instance of a [Label].
  ---
  --- @param o table
  --- @return AnkhLabel
  function labelmetatable:new(o)
    o = o or {}
    o.priority = o.priority or 0

    setmetatable(o, self)
    self.__index = self

    return o
  end

  M.Label = labelmetatable
end

--- @alias AnkhLabel { priority: integer, id: string, label: string, spawn: table, action: function, }
--- @alias AnkhSet AnkhLabel[]
--- @alias iterator function

return M
