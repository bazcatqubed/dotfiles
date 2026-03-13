local M = {}

do
  local setmt = {}

  function setmt:new(o)
    o = o or {}
    setmetatable(o, self)
    self.__index = self

    return o
  end

  function setmt:ordered_pairs(sort)
    local keys = {}
    for k, v in pairs(self) do
      keys[#keys+1] = { priority = v.priority, name = k }
    end
    sort = sort or function (a, b)
      return a.priority > b.priority
    end
    table.sort(keys, sort)

    local i = 0
    return function ()
      i = i + 1
      if keys[i] then
        return keys[i].name, self[keys[i].name]
      end
    end
  end

  M.Set = setmt
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

  function labelmetatable:new(o)
    o = o or {}
    o.priority = o.priority or 0

    setmetatable(o, self)
    self.__index = self

    return o
  end

  M.Label = labelmetatable
end

function M:merge(a, b)
  for k, v in ipairs(b) do
    if type(v) == "table" and type(a[k]) == "table" then
      M:merge(a, b)
    else
      a[k] = v
    end
  end

  return a
end

return M
