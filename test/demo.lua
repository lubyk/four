--[[--
  h1. Demo
  
  Utilities for simple demos.
--]]--

local lib = {}

require 'lubyk' 
local Models = require 'Models'
local Geometry = four.Geometry

-- h2. Geometry 

--[[--
  @geometryCycle(def)@ is an argument less function returning 
  new geometry objects in a cyclic fashion. @def@ keys:
  * @geometries@, an array of argument less functions that returns geometry
    objects. Default has the geometries of @four.Geometry@ and the Stanford 
    Bunny.
  * @normals@, @true@ if vertex normals should be computed, defaults to @false@.
--]]--
function lib.geometryCycler(def)
  local id = -1
  local normals = def.normals or false
  local geoms = def.geometries or 
    { function () return Geometry.Cube(1) end,
      function () return Geometry.Sphere(0.5, 4) end,
      function () return Geometry.Plane(four.V2(1,1)) end,
      function () return Models.bunny(1) end }
  local function next ()  
    id = (id + 1) % #geoms
    local g = geoms[id + 1] ()
    if normals then g:computeVertexNormals() end
    return g
  end
  return next
end

-- h2. Effects

--[[--
  @effectCycle(def)@ is an argument less function returning 
  new effects in a cyclic fashion. @def@ keys:
  * @effecdts@, an array of argument less functions that returns effect
    objects. Default has the effect of @four.Effect@ TODO.
--]]--
function lib.effectCycler(def)
  local id = -1 
  local effects = def.effects or {} -- TODO
  local function next () 
    id = (id + 1) % #effects
    return effects[id + 1] ()
  end
  return next
end


return lib

