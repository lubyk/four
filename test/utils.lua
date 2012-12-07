require 'lubyk' 

local lib = {}

local Buffer = four.Buffer
local V3 = four.V3

--[[-- 
@randomCuboidSamples(count, min, max, pts)@ is a Buffer with @count@ random 
points distributed uniformly in the cuboid defined by the two extreme 
points @min@ and @max@. If @pts@ is present, points are added to @pts@.
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
      repeat x = xmin + math.random() * (xmax - xmin)
      until xmin <= x and x <= xmax 
    end
    if ymin == ymax then y = ymin else
      repeat y = ymin + math.random() * (ymax - ymin)
      until ymin <= y and y <= ymax 
    end
    if zmin == zmax then z = zmin else
      repeat z = zmin + math.random() * (zmax - zmin)
      until zmin <= z and z <= zmax 
    end
    b:push3D(x, y, z)
  end
  return b
end

return lib
