--[[--
  h1 four.Camera
  A camera defines a view volume of world space.
--]]--
local lub  = require 'lub'
local four = require 'four'
local lib  = lub.class 'four.Camera'

local V2 = four.V2
local V3 = four.V3
local M4 = four.M4
local Quat = four.Quat

-- Projection parameters/matrix synchronization

local function setOrthoMatrix(tv)
  local near, far = V2.tuple(tv.range)
  local hw = near * math.tan (tv.fov / 2)
  local hh = hw / tv.aspect
  tv.projection_matrix = M4.ortho(-hw, hw, -hh, hh, near, far)
end

local function setPerspMatrix(tv)
  local near, far = V2.tuple(tv.range)
  local hw = near * math.tan (tv.fov / 2)
  local hh = hw / tv.aspect
  tv.projection_matrix = M4.persp(-hw, hw, -hh, hh, near, far)
end

local function syncProjectionMatrix(tv)  
  if tv.projection == lib.PERSPECTIVE then setPerspMatrix(tv)
  elseif tv.projection == lib.ORTHOGRAPHIC then setOrthoMatrix(tv)
  elseif tv.projection == lib.CUSTOM then return 
  else assert(false) end
end

local is_projection_key = 
  { projection = true, range = true, fov = true, aspect = true, 
    projection_matrix = true }
  
function lib.__index(t, k) 
  if k == "tv" then return rawget(t, k)
  elseif is_projection_key[k] then 
    local tv = t.tv 
    if k == "projection_matrix" and tv.dirty_matrix then 
      syncProjectionMatrix(tv) 
    end
    return tv[k]
  else return lib[k] end
end

function lib.__newindex(t, k, v) 
  if not is_projection_key[k] then rawset(t,k,v)
  else
    local tv = t.tv 
    if k == "projection_matrix" then
      if tv.projection == lib.CUSTOM then tv[k] = v
      else 
        error("Cannot set projection matrix on non-custom projection camera")
      end
    else
      tv.projection_dirty = true;
      tv[k] = v
    end
  end
end

setmetatable(lib, { __call = function(lib, def) return lib.new(def) end })

-- h2. Camera projection types

lib.ORTHOGRAPHIC = 1
lib.PERSPECTIVE = 2
lib.CUSTOM = 3

-- h2. Constructor

--[[--
  @Camera(def)@ is a new camera object. @def@ keys:
  * @transform@, defines the location and orientation of the camera. Default
    transform lies at the origin and looks down the z-axis.
  * @projection@, the kind of projection to use (defaults to @PERSPECTIVE@).
  * @range@, for non-@CUSTOM@ projections defines the near and far clip plane 
    (defaults to @V2(1, 100)@). Clip planes are perpendicular to the camera 
    direction and are defined relative to the camera position.
  * @fov@, for non-@CUSTOM@ projections defines the horizontal field of view
    (defaults to @math.pi / 4@)
  * @aspect@, for non-@CUSTOM@ projections, defines the camera width/height 
    ratio
  * @viewport@, table with @origin@ and @size@ keys defining the viewport
    in normalized screen coordinates of the renderer. Defaults covers 
    the whole renderer viewport.
  * @background@, TODO
  * @effect_override@, specifies an effect to use instead of the renderable's 
    Effects.
--]]--
function lib.new(def)
  local self =
    { transform = four.Transform (), 
      tv = 
        { projection = lib.PERSPECTIVE,
          range = V2(1, 100),
          fov = math.pi / 4,
          aspect = 16 / 9,
          dirty_matrix = true,
          projection_matrix = M4.id ()},
      
      viewport = { origin = four.V2.zero (), size = four.V2(1.0, 1.0) },

      background = 
        { color = four.Color.black (),
          depth = 1.0 },

      -- Custom culling fun, e.g. omit renderable with a given key defined.
      cull = function (renderable) return false end, -- custom culling fun

      effect_override = nil, -- Override all renderable's effects
    }
    setmetatable(self, lib)
    if def then self:set(def) end
    return self    
end

function lib:set(def) 
  if def.transform ~= nil then self.transform = def.transform end
  if def.projection ~= nil then self.projection = def.projection end
  if def.range ~= nil then self.range = def.range end
  if def.fov ~= nil then self.fov = def.fov end
  if def.aspect ~= nil then self.aspect = def.aspect end
  if def.projection_matrix ~= nil then 
    self.projection_matrix = def.projection_matrix 
  end
  if def.background ~= nil then 
    if def.background.color ~= nil then 
      self.background.color = def.background.color 
    end
    if def.background.depth ~= nil then 
      self.background.depth = def.background.depth 
    end
  end
  if def.viewport ~= nil then self.viewport = def.viewport end
  if def.effect_override ~= nil then 
    self.effect_override = def.effect_override 
  end
end

--[[--
  c:screenToDevice(pos) is the normalized device coordinates of the normalized
  screen coordinates @pos@ in @c@.
--]]--
function lib:screenToDevice(pos) 
  local nvp = V2.div(pos - self.viewport.origin, self.viewport.size)
  return 2 * nvp - V2(1,1)
end

return lib
