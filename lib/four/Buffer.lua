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
  h2. Buffer usage hints
  Defines how the data will be updated (hint for renderer).
--]]--

lib.UPDATE_NEVER = 1
lib.UPDATE_SOMETIMES = 2
lib.UPDATE_OFTEN = 3

--[[--
  @Buffer(def)@ is a new buffer object. @def@ keys:
  * @dim@, the vectors dimension (defaults to @3@).
  * @scalar_type@, the vector's element type (defaults to @lib.FLOAT@).
  * @data@, an array of numbers (defaults to @{}@)
  * @normalize@, @true@ if the data should be normalized by the gpu (defaults
    to @false@).
  * @update@, the update frequency (defaults to @UPDATE_NEVER@)
  * @disposable@, if @true@, @data@ may be disposed by the renderer.
  * @updated@, if @true@, @data@ will be read again by the renderer. The
    renderer sets the flag to @false@ once he read the data.
--]]--
function lib.new(def)
  local self = 
    { dim = 3,                  
      scalar_type = lib.FLOAT,  
      data = {},
      normalize = false,
      update = lib.UPDATE_NEVER,
      disposable = true, 
      updated = true }               
    setmetatable(self, lib)
    if def then self:set(def) end
    return self
end

function lib:set(def) 
  if def.dim then self.dim = def.dim end
  if def.scalar_type then self.scalar_type = def.scalar_type end  
  if def.data then self.data = def.data end
  if def.normalize then self.normalize = def.normalize end
  if def.update then self.update = def.update end
  if def.disposable then self.disposable = def.disposable end
  if def.updated then self.updated = def.updated end
end

function lib:length() return (#self.data / self.dim) end
function lib:scalarLength() return #self.data end
function lib:disposeBuffer() if self.disposable then self.data = {} end end

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

function lib:getV2(i) 
  local b = (i - 1) * self.dim
  return four.V2(self.data[b + 1], 
                 self.data[b + 2])
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

function lib:push(...)
  local t = self.data 
  local s = #t
  for i, v in ipairs{...} do t[s + i] = v end
end

function lib:push1D(x)
  local t = self.data 
  local s = #t
  t[s + 1] = x; 
end

function lib:push2D(x, y)
  local t = self.data
  local s = #t
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


-- h2. Swapping and deleting

-- @self:swap(i,j)@ swaps the element @i@ and @j@ in self. 
function lib:swap(i,j)
  local dim = self.dim 
  local t = self.data 
  local ib = (i - 1) * dim 
  local jb = (j - 1) * dim
  for d = 1, dim do 
    local ii = ib + d
    local jj = jb + d
    local temp = t[ii]
    t[ii] = t[jj] 
    t[jj] = temp 
  end
end
 
--[[--
  @self:delete(i)@, deletes the element of @self@ at @i@.x
  *Warning* Does not preserve the order of elements in the array.
--]]--
function lib:delete(i)
 local dim = self.dim
 local t = self.data 
 local len = self:length() 

 if len == 1 then self.data = {} 
 else 
   if i ~= len then self:swap(i, len) end
   local lb = (len - 1) * dim
   for d = 1, dim do t[lb + d] = nil end
 end
end

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
    local b = (i - 1) * dim
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
    local b = (i - 1) * dim
    acc = f(acc, four.V4(t[b + 1], t[b + 2], t[b + 3], t[b + 4]))
  end
  return acc
end

--[[--
  h2. Sorting
  
  Sorting methods use custom comparison function @cmp@. @cmp(x,y)@ is:
  * -1 if @x@ is smaller than @y@
  * 0, if @x@ equals @y@
  * 1 if @x@ is greater than @y@
--]]--

local function generic_sort_order(b, cmp, get)
  local order = {}
  local qsort
  qsort = function (order, b, l, r)
    if l < r then
      local pivot = math.floor(l + (r - l) / 2)
      local pi = order[pivot]
      local pvalue = get(b, pi)
      order[pivot] = order[r]
      order[r] = pi
      local loc = l
      for k = l, r - 1 do 
        local ki = order[k]
        local kvalue = get(b, ki)
        if cmp(kvalue, pvalue) == -1 then
          order[k] = order[loc]
          order[loc] = ki
          loc = loc + 1
        end
      end
      order[r] = order[loc]
      order[loc] = pi
      qsort(order, b, l, loc - 1)
      qsort(order, b, loc + 1, r)
    end
  end
  for i = 1, b:length() do order[i] = i end
  qsort(order, b, 1, b:length())
  return order
end

local function generic_sort_inplace(b, cmp, cget, get, set)
  local qsort
  qsort = function (b, l, r)
    if l < r then
      local pivot = math.floor(l + (r - l) / 2)
      local pvc = cget(b, pivot)
      local pv = get(b, pivot) 
      set(b, pivot, get(b, r))
      set(b, r, pv) 
      local loc = l
      for i = l, r - 1 do 
        local ivc = cget(b, i)
        local iv = get(b, i) 
        if cmp(ivc, pvc) == - 1 then 
          set(b, i, get(b, loc))
          set(b, loc, iv)
          loc = loc + 1
        end
      end
      set(b, r, get(b, loc))
      set(b, loc, pv)
      qsort(b, l, loc - 1)
      qsort(b, loc + 1, r)
    end
  end
  qsort(b, 1, b:length())
end

local sort_get = { lib.get1D, lib.getV2, lib.getV3, lib.getV4 }
local sort_set = { lib.set1D, lib.setV2, lib.setV3, lib.setV4 }

--[[--
  @self:sort(cmp [, get])@ sorts the elements of the buffer in place using
  @cmp@ as a comparison function. @cmp@ is given objects returned by @get@
  (defaults depends on @self.dim@, number for @1@, V2 for @2@, V3 for @3@, 
   V4 for @4@)
--]]--
function lib:sort(cmp, get)  
  local set = sort_set[self.dim]
  local get = sort_get[self.dim]
  local cget = get or sort_get[self.dim]
  generic_sort_inplace(self, cmp, cget, get, set)
end

--[[--
  @self:sortOrder(cmp [, get])@ is like @self:sort@ excepts elements of 
  the buffer are kept in place and an array of indexes defining 
  the order is returned. 
--]]--
function lib:sortOrder(cmp, get)
  local get = get or sort_get[self.dim]
  return generic_sort_order(self, cmp, get)
end

-- h2. Data properties 

--[[--
 @self:dimExtents()@ is a table of size @self.dim@ each index
 storing a table @{min = ..., max = ... }@ corresponding to 
 the minimal and maximal scalar value in that dimension.
--]]--
function lib:dimExtents()
  local dim = self.dim 
  local t = self.data 
  local exts = {}
  for i = 1, dim do exts[i] = { max = -math.huge, min = math.huge } end
  for i = 1, self:length() do 
    local b = (i - 1) * dim 
    for d = 1, dim do
      local v = t[b + d]
      if v < exts[d].min then exts[d].min = v end
      if v > exts[d].max then exts[d].max = v end
    end
  end
  return exts
end
