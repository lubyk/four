--[[--
  # four.Manip
  Transform components manipulators. 
--]]--

-- local lib = { type = 'four.Manip' }
-- lib.__index = lib
-- four.Manip = lib

local lib = {}

local V2 = four.V2
local V3 = four.V3
local V4 = four.V4
local Quat = four.Quat

local function sphere_point(radius, center, v)
  local p = (1 / radius) * (v - center) 
  local d = V2.norm2(v)
  if d > 1 then 
    local a = 1 / math.sqrt(d)
    return V3.ofV2(a * p, 0.0)
  else
    return V3.ofV2(p, math.sqrt(1.0 - d))
  end
end

function lib.Rot(relat, start)
  local center = V2(0,0)
  local radius = 1.0
  local relative = relat or Quat.id ()
  return { center = center,
           radius = radius,
           start = sphere_point(radius, center, start),
           relative = relative }  
end

function lib.rotUpdate(r, v)
  local p = sphere_point(r.radius, r.center, v) 
  local q = V4.ofV3(V3.cross(r.start, p), V3.dot(r.start, p))
  return Quat.mul(Quat.ofV4(q), r.relative)
end

return lib
