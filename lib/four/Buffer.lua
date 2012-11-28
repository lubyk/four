--[[--
  h1. four.Buffer

  A buffer holds 1D to 4D int/float vectors in a linear lua array.
--]]--

-- Module definition

local lib = { type = 'four.Buffer' }
lib.__index = lib
four.Buffer = lib
setmetatable(lib, { __call = function(lib, ...) return lib.new(...) end})

--[[--
   h2. Buffer element type 
   Defines how the data will be stored on the gpu and how the shader will 
   view the data.
--]]--

lib.FLOAT = 1
lib.DOUBLE = 2
lib.INT = 3
lib.UNSIGNED_INT = 4

--[[--
  @Buffer(def)@ is a new buffer object. @def@ keys:
  * @dim@, the vectors dimension (defaults to @3@).
  * @scalar_type@, the vector's element type (defaults to @lib.FLOAT@).
  * @data@, an array of numbers (defaults to @{}@)
  * @normalize@, @true@ if the data should be normalized by the gpu (defaults
    to @false@).
--]]--
function lib.new(def)
  local self = 
    { dim = 3,                  
      scalar_type = lib.FLOAT,  
      data = {},
      normalize = false }               
    setmetatable(self, lib)
    if def then self:set(def) end
    return self
end

function lib:set(def) 
  if def.dim then self.dim = def.dim end
  if def.scalar_type then self.scalar_type = def.scalar_type end  
  if def.data then self.data = def.data end
  if def.normalize then self.normalize = def.normalize end
end

function lib:length() return (#self.data / self.dim) end
function lib:scalarLength() return #self.data end
function lib:disposeBuffer() self.data = {} end

-- h2. Getters 

function lib:getScalar(i) return self.data[i] end
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

-- h2. Setters

function lib:setScalar(i, x) self.data[i] = x end
function lib:set1D(i, x)
  local b = (i - 1) * self.dim 
  self.data[b + 1] = x; 
end

function lib:set2D(i, x, y)
  local b = (i - 1) * self.dim 
  local t = self.data
  t[b + 1] = x; 
  t[b + 2] = y; 
end

function lib:set3D(i, x, y, z)
  local b = (i - 1) * self.dim 
  local t = self.data
  t[b + 1] = x; 
  t[b + 2] = y; 
  t[b + 3] = z;
end

function lib:set4D(i, x, y, z, w)
  local b = (i - 1) * self.dim 
  local t = self.data 
  t[b + 1] = x; 
  t[b + 2] = y; 
  t[b + 3] = z;
  t[b + 4] = w;
end

function lib:setV3(i, v) self:set3D(i, four.V3.tuple(v)) end
function lib:setV4(i, v) self:set4D(i, four.V4.tuple(v)) end

--[[--
   h2. Append 
   *Note*, appending just add elements at the end of the data, it 
   doesn't care about buffer dimension.
--]]--

function lib:push(i, ...)
  local t = self.data 
  local s = #t
  for i, v in ipairs(...) do t[s + i] = v end
end

function lib:push1D(i, x)
  local t = self.data 
  local s = #t
  t[s + 1] = x; 
end

function lib:push2D(i, x, y)
  local t = self.data
  local s = #self.data
  t[s + 1] = x; t[s + 2] = y; 
end

function lib:push3D(x, y, z)
  local t = self.data
  local s = #t
  t[s + 1] = x; t[s + 2] = y; t[s + 3] = z;
end

function lib:push4D(x, y, z, w)
  local t = self.data
  local s = #t
  t[s + 1] = x; t[s + 2] = y; t[s + 3] = z; t[s + 4] = w;
end

function lib:pushV3(v) self:push3D(four.V3.tuple(v)) end
function lib:pushV4(v) self:push4D(four.V4.tuple(v)) end

-- h2. Traversing

function lib:foldScalars(f, acc)
  local t = self.data 
  local acc = acc
  for i = 1, self:scalarLength() do 
    acc = f(acc, t[i])
  end
  return acc
end

function lib:fold1D(f, acc)
  local dim = self.dim
  local t = self.data 
  local acc = acc 
  for i = 1, self:length() do 
    local b = (i - 1) * dim
    acc = f(acc, t[b + 1])
  end
  return acc
end

function lib:fold2D(f, acc)
  local dim = self.dim
  local t = self.data
  local acc = acc 
  for i = 1, self:length() do 
    local b = (i - 1) * dim
    acc = f(acc, t[b + 1], t[b + 2])
  end
  return acc
end

function lib:fold3D(f, acc)
  local dim = self.dim
  local t = self.data 
  local acc = acc 
  for i = 1, self:length() do 
    local b = (i - 1) * t
    acc = f(acc, t[b + 1], t[b + 2], t[b + 3])
  end
  return acc
end

function lib:fold4D(f, acc)
  local dim = self.dim
  local t = self.data
  local acc = acc 
  for i = 1, self:length() do 
    local b = (i - 1) * dim
    acc = f(acc, t[b + 1], t[b + 2], t[b + 3], t[b + 4])
  end
  return acc
end

function lib:foldV3(f, acc)
  local dim = self.dim
  local t = self.data
  local acc = acc
  for i = 1, self:length() do 
    local b = (i - 1) * dim
    acc = f(acc, four.V3(t[b + 1], t[b + 2], t[b + 3]))
  end
  return acc
end

function lib:foldV4(f, acc)
  local dim = self.dim
  local t = self.data
  local acc = acc 
  for i = 1, self:length() do 
    local b = (i - 1) * tim
    acc = f(acc, four.V4(t[b + 1], t[b + 2], t[b + 3], t[b + 4]))
  end
  return acc
end
