--[[--
  h1. four.Transform

  A transform orients an object in 3D space. It can also call arbitrary
  observing functions when it changes.

  *Note*, the transform decomposition scales, rotates and
  then translates.
--]]--

local lib = { type = 'four.Transform' }
four.Transform = lib

local Quat = four.Quat
local V3 = four.V3
local V4 = four.V4
local M4 = four.M4

-- Transform decomposition/matrix synchronization

local function syncMatrix(tv) 
  tv.matrix = M4.rigidqScale(tv.pos, tv.rot, tv.scale) 
end

local function syncDecomp(tv)
  local m = tv.matrix
  tv.pos = M4.getMove(m)
  tv.rot = Quat.ofM4(m)
  tv.scale = M4.getScale(m)
end

local function notify(tr, tv) for _, d in tv.deps do d(tr) end end

local is_decomp_key = { pos = true, rot = true, scale = true } 
function lib.__index(t, k) 
  if k == "tv" then return rawget(t, k)
  elseif is_decomp_key[k] then
    local tv = t.tv
    if tv.dirty_decomp then syncDecomp(tv) end
    return tv[k]
  elseif (k == "matrix") then
    local tv = t.tv
    if tv.dirty_matrix then syncMatrix(tv) end
    return tv[k]
  else return lib[k] end
end

function lib.__newindex(t, k, v)
  if is_decomp_key(k) then 
    local tv = t.tv
    if tv.dirty_decomp then syncDecomp(tv) end -- other decomps.
    tv[k] = v
    tv.dirty_matrix = true 
    notify(t, tv)
  elseif (k == "matrix") then 
    local tv = t.tv 
    tv[k] = v
    tv.dirty_decomp = true
    tv.dirty_matrix = false
    notify(t, tv)
  elseif (k == "deps") then 
    local deps = t.tv.deps
    deps = {}
    for _, dep in ipairs(v) do table.insert(deps, dep) end
  else t[k] = v end
end

setmetatable(lib, { __call = function(lib, o) return lib.new(o) end })

-- h2. Constructor

local err_ambig = "Ambiguous transform (matrix and decomposition specified)"

--[[--
  @Transform(def)@ is a new transform object. @def@ keys:
  * @pos@, the position component of the transform as @V3@ object.
  * @rot@, the rotation component of the transform as a @Quat@ object.
  * @scale@, the scaling component of the transform.
  * @matrix@, the matrix of the transform (excludes @pos@, @rot@, @scale@).
  * @deps@, weak array of functions called whenever the transform changes.
--]]--
function lib.new(def)
  local self =
    { tv = { pos = V3.zero (),
             rot = Quat.id (),
             scale = V3(1, 1, 1),
             matrix = M4.id (),
             dirty_decomp = false,
             dirty_matrix = false,
             deps = {}}            -- Weakly references dependents. 
    }
    setmetatable(self.tv.deps, { __mode = 'v' })
    setmetatable(self, lib)
    if def then self:set(def) end
    return self
end

function lib:set(def)
  local tv = self.tv 
  if def.pos then tv.dirty_matrix = true tv.pos = def.pos end
  if def.rot then tv.dirty_matrix = true tv.rot = def.rot end
  if def.scale  then tv.dirty_matrix = true tv.scale = def.scale end
  if def.matrix then 
    if tv.dirty_matrix then error(err_ambig) else
      tv.dirty_decomp = true 
      tv.matrix = def.matrix
    end
  end
  if def.deps then self.deps = def.deps end    
end

function lib:insertDep(d) table.insert(self.tv.tdeps, dep) end
function lib:removeDep(d)
  local tdeps = self.tv.deps
  for i, dep in ipairs(tdeps) do 
    if dep == d then table.remove(tdeps, i) break end 
  end
end

--[[--
  @lookAt(pos[,up])@ rotates the transform so that the forward points
  at @pos@. If @up@ is unspecified @V3.oy ()@ is used. The final
  @up@ vector only matches if the forward direction is orthogonal
  to the forward direction.
--]]--
function lib:lookAt(t, up)
  
end
