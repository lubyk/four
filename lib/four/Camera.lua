--[[--
  # four.Camera
  A camera located in space.
  
--]]--

-- Module definition

local lib = { type = 'four.Camera' }
lib.__index = lib
four.Camera = lib
setmetatable(lib, { __call = function(lib, ...) return lib.new(...) end })

-- ## Constructor

lib.ORTHOGRAPHIC = 0
lib.PERSPECTIVE = 1

function lib:set(def) for k, v in pairs(def) do self[k] = v end end
function lib.new(def)
  local self =
    { spatial = four.Spatial (),

      -- Projection
      projection = lib.PERPSECTIVE,
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
      _transform_space_inverse = four.M4.id,
      _projection_matrix = four.M4.id,
      _projection_matrix_inverse = four.M4.id 
    }
    setmetatable(self, lib)
    if (def) then self:set(def) end
    return self    
end





