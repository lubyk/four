--[[--
  h1 four.Camera
  A camera defines a view volume of world space.
--]]--

-- Module definition

local lib = { type = 'four.Camera' }
lib.__index = lib
four.Camera = lib
setmetatable(lib, { __call = function(lib, ...) return lib.new(...) end })

local V2 = four.V2
local V3 = four.V3
local M4 = four.M4
local Quat = four.Quat
local Color = four.Color

-- h2. Camera projection types

lib.ORTHOGRAPHIC = 1
lib.PERSPECTIVE = 2

-- h2. Constructor

--[[--
  @Camera(def)@ is a new camera object. @def@ keys:
  * @transform@, defines the location and orientation of the camera.
  * @projection@, the kind of projection to use.
  * @zrange@, defines the near and far clip plane. Clip planes
    are perpendicular to the camera direction and are defined
    relative to the camera position. 
  * @field_of_view@, 
  * @aspect@, 
--]]--
function lib.new(def)
  local self =
    { transform = four.Transform (), 
      projection = lib.PERSPECTIVE,
      range = V2(0.1, 1000),
      
      -- Projection
      size = nil, -- viewport size for orthographic

      clip_near = 0, -- closest distance were drawing occurs
      clip_far = 1000, -- farthest distance where drawing occurs
      filed_of_view = math.pi / 2, -- 

      -- Viewport in normalized screen coordinates
      viewport = { origin = four.V2.zero (), size = four.V2(1.0, 1.0) },

      -- Rendering attributes
      background = 
        { color = four.Color.black (), -- set to nil to disable clearing
          depth = 1.0,                 -- set to nil to disable clearing
          clear_stencil = 0 },         -- set to nil to disable clearing

      -- Custom culling fun, e.g. omit renderable with a given key defined.
      cull = function (renderable) return false end, -- custom culling fun

      effect_override = nil, -- Override all renderable's effects
      effect_default = nil,  -- Use this effect for renderables without one.
      
      _dirty_projection = true,

      projection_matrix = M4.id ()
    }
    setmetatable(self, lib)
    if (def) then self:set(def) end
    return self    
end


function lib:set(def) for k, v in pairs(def) do self[k] = v end end






