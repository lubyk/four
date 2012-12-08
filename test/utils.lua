require 'lubyk' 

local lib = {}

local Buffer = four.Buffer
local V3 = four.V3

--[[-- 
  @randomCuboidSamples(count, min, max [, pts])@ is a Buffer with @count@ 
  random 3D points distributed uniformly in the cuboid defined by the two 
  extreme points @min@ and @max@. 

  If @pts@ is present, this object is returned and points are added to it.

  *Warning* Uses rejection sampling. Make sure that the cuboid is not
  much larger/smaller in a single dimension. Planar and linear
  specification (equal min and max in some dimensions) are however not
  a problem.
--]]--
function lib.randomCuboidSamples(count, min, max, pts)
  local b = pts or Buffer { dim = 3, scalar_type = Buffer.FLOAT }
  local xmin, ymin, zmin = V3.tuple(min)
  local xmax, ymax, zmax = V3.tuple(max)
  local min = math.min(xmin, ymin, zmin)
  local max = math.max(xmax, ymax, zmax)
  local x, y, z 
  for i = 1, count do 
    if xmin == xmax then x = xmin else
      repeat x = xmin + math.random() * (max - min)
      until xmin <= x and x <= xmax 
    end
    if ymin == ymax then y = ymin else
      repeat y = ymin + math.random() * (max - min)
      until ymin <= y and y <= ymax 
    end
    if zmin == zmax then z = zmin else
      repeat z = zmin + math.random() * (max - min)
      until zmin <= z and z <= zmax 
    end
    b:push3D(x, y, z)
  end
  return b
end

return lib
