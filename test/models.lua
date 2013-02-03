--[[--
  h1. Models

  Models stored in lua code.
--]]--

local lib = {} 

require 'lubyk'
local V3 = four.V3
local M4 = four.M4
local Buffer = four.Buffer
local Geometry = four.Geometry

--[[-- 
  @aabbNormalize(g)@ is a normalization matrix for @g@ derived as
  follows. First the axis-aligned bounding box (aabb) of @g@'s
  vertices is computed.  The center of the bounding box is mapped to
  the origin and the model is scaled proportionally so that the
  largest dimension of the aabb is mapped to @1@.
--]]--
function lib.aabbNormalize(g)
  local bounds = { minx = math.huge, miny = math.huge, minz = math.huge,
                   maxx = -math.huge, maxy = -math.huge, maxz = -math.huge }
  
  local function updateBounds(bounds, x, y, z)
    bounds.minx = x < bounds.minx and x or bounds.minx
    bounds.miny = y < bounds.miny and y or bounds.miny
    bounds.minz = z < bounds.minz and z or bounds.minz
    bounds.maxx = x > bounds.maxx and x or bounds.maxx
    bounds.maxy = y > bounds.maxy and y or bounds.maxy
    bounds.maxz = z > bounds.maxz and z or bounds.maxz
    return bounds
  end
  g.data.vertex:fold3D(updateBounds, bounds)

  local scale = 1 / math.max(bounds.maxx - bounds.minx, 
                             bounds.maxy - bounds.miny,
                             bounds.maxz - bounds.minz)
  local center = V3(-0.5 * (bounds.minx + bounds.maxx),
                    -0.5 * (bounds.miny + bounds.maxy),
                    -0.5 * (bounds.minz + bounds.maxz))
  return M4.scale(V3(scale, scale, scale)) * M4.move(center)
end

--[[--
  @bunny([nscale])@ is a Geometry object for the Stanford Bunny. If
  @nscale@ is given, uses @aabbNormalize@ to normalize to the given
  scale the using the Geometry's @pre_transform@.
  
  *Source*. Data is derived from the the PLY file available at
  http://graphics.stanford.edu/data/3Dscanrep/
--]]--
function lib.bunny (nscale)
  local b = yaml.load(lk.readAll(lk.scriptDir() .. '/models/bunny.yml'))
  local vs = Buffer { dim = 3, scalar_type = Buffer.FLOAT, data = b.vertex }
  local is = Buffer { dim = 3, scalar_type = Buffer.UNSIGNED_INT, 
                     data = b.index }
  local g = Geometry { name = "Stanford Bunny", primitive = Geometry.TRIANGLES,
                       data = { vertex = vs }, index = is }

  if nscale then 
    g.pre_transform = 
      M4.scale(V3(nscale, nscale, nscale)) * lib.aabbNormalize(g)
  end

  return g
end

return lib
