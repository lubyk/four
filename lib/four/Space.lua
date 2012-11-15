--[[--
  # four.Space
  A 3D space gathers objects to submit for rendering. 
--]]--

-- Module definition

local lib = { type = 'four.Space' }
lib.__index = lib
four.Space = lib
setmetatable(lib, { __call = function(lib, ...) return lib.new(...) end})

-- ## Constructor

function lib:set(def) 
  for k, v in pairs(def) do 
    if (k ~= "objs") then self[k] = v else
      for _, o in ipairs(v) do self:add(o) end
    end 
  end
end

function lib.new(def)
  local self = 
    { _objs = {},
      -- Custom culling function, e.g. to plug a spatial data structure.
      cull = function (o, cam) return false end 
    }
  setmetatable(self, lib)
  if def then self:set(def) end
  return self
end

-- ## Objects 

function lib:objs() return self._objs end

-- TODO insert/remove

function lib:add(o) table.insert(self._objs, o) end
function lib:rem(o)
  for i, obj in ipairs(self._objs) do
    if obj == o then table.remove(self._objs, i); break end
  end
end


