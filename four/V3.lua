--[[--
  h1. four.V3
  3D float vectors
  
  Given a vector @v@ we denote by @vi@ its one-based @i@th component.
--]]--
local lub  = require 'lub'
local four = require 'four'
local lib  = lub.class 'four.V3'

-- h2. Constructors and accessors

--[[--
  @V3(x, y, z)@ is a vector with the corresponding components.

  @V3(o)@ is a vector converted from the object @o@. Supported types
  for @o@: @bt.Vector3@.
--]]--
function lib.new(x, y, z)
  local v = {}
  if y then v = { x, y, z }
  else
    if x.type == "bt.Vector3" then v = { x:getX(), x:getY(), x:getZ() }
    else
      assert(false, string.format("Cannot convert %s to %s", x.type, lib.type))
    end
  end
  setmetatable(v, lib)
  return v
end

local V3 = lib.new

-- @x(v)@ is the @x@ component of @v@.
function lib.x(v) return v[1] end

-- @y(v)@ is the @y@ component of @v@.
function lib.y(v) return v[2] end

-- @z(v)@ is the @z@ component of @v@.
function lib.z(v) return v[3] end

-- @comp(i, v)@ is the @i@th component of @v@.
function lib.comp(i, v) return v[i] end


-- h2. Converters

-- @ofV2(v, z)@ is @V3(V2.x(v), V2.y(v), z)@.
function lib.ofV2(v, z) return V3(v[1], v[2], z) end

-- @ofV4(v)@ is @V3(V4.x(v), V4.y(v), V4.z(v))@.
function lib.ofV4(v) return V3(v[1], v[2], v[3]) end

-- @tuple(v)@ is @x, y, z@, the components of @v@.
function lib.tuple(v) return v[1], v[2], v[3] end

-- @tostring(v)@ is a textual representation of @v@.
function lib.tostring(v) 
  return string.format("(%g %g %g)", v[1], v[2], v[3])
end


-- h2. Constants 

-- @zero()@ is a vector @(0, 0, 0)@.
function lib.zero() return V3(0, 0, 0) end

-- @ox()@ is a unit vector @(1, 0, 0)@.
function lib.ox() return V3(1, 0, 0) end

-- @oy()@ is a unit vector @(0, 1, 0)@.
function lib.oy() return V3(0, 1, 0) end

-- @oz()@ is a unit vector @(0, 0, 1)@.
function lib.oz() return V3(0, 0, 1) end

-- @huge()@ is a vector whose components are @math.huge@.
function lib.huge() return V3(math.huge, math.huge, math.huge) end

-- @neg_huge()@ is a vector whose components are @-math.huge@.
function lib.neg_huge() return V3(-math.huge, -math.huge, -math.huge) end


-- h2. Functions

-- @neg(v)@ is the inverse vector @-v@.
function lib.neg(v) return V3(-v[1], -v[2], -v[3]) end

-- @add(u, v)@ is the vector addition @u + v@.
function lib.add(u, v) return V3(u[1] + v[1], u[2] + v[2], u[3] + v[3]) end

-- @sub(u, v)@ is the vector subtraction @u - v@.
function lib.sub(u, v) return V3(u[1] - v[1], u[2] - v[2], u[3] - v[3]) end

-- @mul(u, v)@ is the component wise mutiplication @u * v@.
function lib.mul(u, v) return V3(u[1] * v[1], u[2] * v[2], u[3] * v[3]) end

-- @div(u, v)@ is the component wise division @u / v@.
function lib.div(u, v) return V3(u[1] / v[1], u[2] / v[2], u[3] / v[3]) end

-- @smul(s, v)@ is the scalar mutiplication @sv@.
function lib.smul(s, v) return V3(s * v[1], s * v[2], s * v[3]) end

-- @half(v)@ is the half vector @smul(0.5, v)@.
function lib.half(v) return V3(0.5 * v[1], 0.5 * v[2], 0.5 * v[3]) end

-- @cross(u, v)@ is the cross product @u x v@.
function lib.cross(u, v) 
  return V3 ((u[2] * v[3]) - (u[3] * v[2]),
             (u[3] * v[1]) - (u[1] * v[3]),
             (u[1] * v[2]) - (u[2] * v[1])) 
end

-- @dot(u, v)@ is the dot product @u.v@.
function lib.dot(u, v) return u[1] * v[1] + u[2] * v[2] + u[3] * v[3] end

-- @norm(v)@ is the norm @|v|@.
function lib.norm(v) 
  return math.sqrt (v[1] * v[1] + v[2] * v[2] + v[3] * v[3])
end

-- @norm2(v)@ is the squared norm @|v|^2@.
function lib.norm2(v) return v[1] * v[1] + v[2] * v[2] + v[3] * v[3] end

-- @unit(v)@ is the unit vector @v/|v|@.
function lib.unit(v) return lib.smul(1 / lib.norm(v), v) end

-- @homogene(v)@ is the vector @v/V3.z(v)@.
function lib.homogene(v) return V3(v[1] / v[3], v[2] / v[3], 1.0) end

--[[--
  @sphereUnit(theta, phi)@ is the unit vector whose azimuth spherical 
  coordinate is @theta@ and zenith is @phi@. 
--]]--
function lib.sphereUnit(theta, phi)
  local tc, ts = math.cos(theta), math.sin(theta)
  local pc, ps = math.cos(phi), math.sin(phi)
  return V3(tc * ps, ts * ps, pc)
end

-- @mix(u, v, t)@ is the linear interpolation @u + t * (v - u)@.
function lib.mix(u, v, t) 
  return V3 (u[1] + t * (v[1] - u[1]),
             u[2] + t * (v[2] - u[2]),
             u[3] + t * (v[3] - u[3]))
end

--[[--
  @trVec(m, v)@ is the *vector* @v@ transformed by the @M4@ matrix @m@ 
  (the translation component of @m@ is ignored).
--]]--
function lib.trVec(m, v) 
  return V3 (m[1] * v[1] + m[5] * v[2] + m[ 9] * v[3],
             m[2] * v[1] + m[6] * v[2] + m[10] * v[3],
             m[3] * v[1] + m[7] * v[2] + m[11] * v[3])
end

-- @trPt(m, pt)@ is the *point* @p@ transformed by the @M4@ matrix @m@.
function lib.trPt(m, pt) 
  return V3 (m[1] * pt[1] + m[5] * pt[2] + m[ 9] * pt[3] + m[13],
             m[2] * pt[1] + m[6] * pt[2] + m[10] * pt[3] + m[14],
             m[3] * pt[1] + m[7] * pt[2] + m[11] * pt[3] + m[15])
end


-- h2. Taversal

-- @map(f, v)@ is @V3(f(v1), f(v2), f(v3))@.
function lib.map(f, v) return V3(f(v[1]), f(v[2]), f(v[3])) end

-- @mapi(f, v)@ is @V3(f(1, v1), f(2, v2), f(3, v3))@.
function lib.mapi(f, v) return V3(f(1, v[1]), f(2, v[2]), f(3, v[3])) end

-- @fold(f, acc, v)@ is @f(f(f(acc, v1), v2), v3)@.
function lib.fold(f, acc, v)  return f(f(f(acc, v[1]), v[2]), v[3]) end

-- @foldi(f, acc, v)@ is @f(f(f(acc, 1, v1), 2, v2), 3, v3)@.
function lib.foldi(f, acc, v) return f(f(f(acc, 1, v[1]), 2, v[2]), 3, v[3]) end

-- @iter(f, v)@ is @f(v1) f(v2) f(v3)@.
function lib.iter(f, v) f(v[1]) f(v[2]) f(v[3]) end

-- @iteri(f, v)@ is @f(1, v1) f(2, v2) f(3, v3)@.
function lib.iteri(f, v) f(1, v[1]) f(2, v[2]) f(3, v[3]) end


-- h2. Predicates

-- @forAll(p, v)@ is @p(v1) and p(v2) and p(v3)@.
function lib.forAll(p, v) return p(v[1]) and p(v[2]) and p(v[3]) end

-- @exists(p, v)@ is @p(v1) or p(v2) or p(v3)@.
function lib.exists(p, v) return p(v[1]) or p(v[2]) or p(v[3]) end

--[[--
  @eq(u, v [,eq])@ is @true@ if @u@ is equal to @v@ component wise.
  If [eq] is provided it used as the equality function.
--]]--
function lib.eq(u, v, eq) 
  if eq then return eq(u[1], v[1]) and eq(u[2], v[2]) and eq(u[3], v[3])
  else return u[1] == v[1] and u[2] == v[2] and u[3] == v[3] end
end

--[[--
  @lt(u, v [,lt])@ is @true@ if @u@ is lower than @v@ component wise.
  If [lt] is provided it used as the comparison function.
--]]--
function lib.lt(u, v, lt) 
  if lt then return lt(u[1], v[1]) and lt(u[2], v[2]) and lt(u[3], v[3])
  else return u[1] < v[1] and u[2] < v[2] and u[3] < v[3] end
end

--[[--
  @le(u, v [,le])@ is @true@ if @u@ is lower or equal than @v@ component wise.
  If [le] is provided it used as the comparison function.
--]]--
function lib.le(u, v, le) 
  if le then return le(u[1], v[1]) and le(u[2], v[2]) and le(u[3], v[3])
  else return u[1] <= v[1] and u[2] <= v[2] and u[3] <= v[3] end
end

--[[--
  @compare(u, v [, cmp])@ is:
  * @-1@ if @u@ is smaller than @v@
  * @0@ if @u@ is equal to @v@
  * @1@ if @u@ is greater than @v@
  where the order is the lexicographic order defined by using @cmp@
  on the components (@cmp@ defaults to the standard order on floats).
--]]--
function lib.compare(u, v, cmp)
  local cmp = cmp or function (a, b) if a < b then return -1 
                                     elseif a > b then return 1 
                                     else return 0 end
                     end
  local c 
  c = cmp(u[1], v[1]) if c ~= 0 then return c end
  c = cmp(u[2], v[2]) if c ~= 0 then return c end
  c = cmp(u[3], v[3]) return c
end


-- h2. Operators

lib.__unm = lib.neg
lib.__add = lib.add
lib.__sub = lib.sub
lib.__mul = lib.smul
lib.__tostring = lib.tostring

return lib
