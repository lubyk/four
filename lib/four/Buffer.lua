--[[--
  # four.Buffer

  A buffer holds 1D to 4D int/float vectors in a linear lua array.
--]]--

-- Module definition

local lib = { type = 'four.Buffer' }
lib.__index = lib
four.Buffer = lib
setmetatable(lib, { __call = function(lib, ...) return lib.new(...) end})

-- ## Buffer element type 
-- Defines how the data will be stored on the gpu and how the 
-- shader will view the data.

lib.FLOAT = 1
lib.DOUBLE = 2
lib.INT = 3
lib.UNSIGNED_INT = 4

function lib.new(def)
  local self = 
    {  normalize = false,        -- true if data should be normalized by the gpu
       dim = 3,                  -- dimension, 1, 2, 3 or 4.    
       scalar_type = lib.FLOAT,  -- element type 
       data = {} }               -- data array
  setmetatable(self, lib)
  if def then self:set(def) end
  return self
end

function lib:set(def) for k, v in pairs(def) do self[k] = v end end
function lib:length() return (#self.data / self.dim) end

-- ## Getters 

function lib:get1D(i)
  local b = (i - 1) * self.dim 
  return self.data[b + 1]
end

function lib:get2D(i)
  local b = (i - 1) * self.dim
  return self.data[b + 1], self.data[b + 2]
end

function lib:get3D(i)
  local b = (i - 1) * self.dim
  return self.data[b + 1], self.data[b + 2], self.data[b + 3]
end

function lib:get4D(i) 
  local b = (i - 1) * self.dim
  return self.data[b + 1], self.data[b + 2], self.data[b + 3], self.data[b + 4]
end

function lib:getV3(i) 
  local b = (i - 1) * self.dim
  return four.V3(self.data[b + 1], 
                 self.data[b + 2], 
                 self.data[b + 3])
end

function lib:getV4(i) 
  local b = (i - 1) * self.dim
  return four.V4(self.data[b + 1], 
                 self.data[b + 2], 
                 self.data[b + 3], 
                 self.data[b + 4])
end

-- ## Setters

function lib:set1D(i, x)
  local b = (i - 1) * self.dim 
  self.data[b + 1] = x; 
end

function lib:set2D(i, x, y)
  local b = (i - 1) * self.dim 
  self.data[b + 1] = x; 
  self.data[b + 2] = y; 
end

function lib:set3D(i, x, y, z)
  local b = (i - 1) * self.dim 
  self.data[b + 1] = x; 
  self.data[b + 2] = y; 
  self.data[b + 3] = z;
end

function lib:set4D(i, x, y, z, w)
  local b = (i - 1) * self.dim 
  self.data[b + 1] = x; 
  self.data[b + 2] = y; 
  self.data[b + 3] = z;
  self.data[b + 4] = w;
end

function lib:setV3(i, v) self:set3(i, four.V3.tuple(v)) end
function lib:setV4(i, v) self:set4(i, four.V4.tuple(v)) end

-- ## Append 
-- Note, appending doesn't care about buffer dimension.

function lib:push1D(i, x)
  local s = #self.data
  self.data[s + 1] = x; 
end

-- TODO table.insert
-- ++ local t = self.data

function lib:push2D(i, x, y)
  local s = #self.data
  self.data[s + 1] = x; 
  self.data[s + 2] = y; 
end

function lib:push3D(x, y, z)
  local s = #self.data
  self.data[s + 1] = x; 
  self.data[s + 2] = y; 
  self.data[s + 3] = z;
end

function lib:push4D(x, y, z, w)
  local s = #self.data
  self.data[s + 1] = x; 
  self.data[s + 2] = y; 
  self.data[s + 3] = z;
  self.data[s + 4] = w;
end

function lib:pushV3(v) self:push3D(four.V3.tuple(v)) end
function lib:pushV4(v) self:push4D(four.V4.tuple(v)) end

-- ## Traversing

function lib:fold1D(f, acc)
  local acc = acc 
  for i = 1, self:length() do 
    local b = (i - 1) * self.dim
    acc = f(acc, self.data[b + 1])
  end
  return acc
end

function lib:fold2D(f, acc)
  local acc = acc 
  for i = 1, self:length() do 
    local b = (i - 1) * self.dim
    acc = f(acc, self.data[b + 1], self.data[b + 2])
  end
  return acc
end

function lib:fold3D(f, acc)
  local acc = acc 
  for i = 1, self:length() do 
    local b = (i - 1) * self.dim
    acc = f(acc, self.data[b + 1], self.data[b + 2], self.data[b + 3])
  end
  return acc
end

function lib:fold4D(f, acc)
  local acc = acc 
  for i = 1, self:length() do 
    local b = (i - 1) * self.dim
    acc = f(acc, 
            self.data[b + 1], 
            self.data[b + 2], 
            self.data[b + 3], 
            self.data[b + 4])
  end
  return acc
end

function lib:foldV3(f, acc)
  local acc = acc
  for i = 1, self:length() do 
    local b = (i - 1) * self.dim
    acc = f(acc, four.V3(self.data[b + 1], 
                         self.data[b + 2], 
                         self.data[b + 3]))
  end
  return acc
end

function lib:foldV4(f, acc)
  local acc = acc 
  for i = 1, self:length() do 
    local b = (i - 1) * self.dim
    acc = f(acc, four.V4(self.data[b + 1], 
                         self.data[b + 2], 
                         self.data[b + 3], 
                         self.data[b + 4]))
  end
  return acc
end
