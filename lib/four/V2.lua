--[[--
  h1. four.V2
  2D float vectors

  Given a vector @v@ we denote by @vi@ its one-based @i@th component.
--]]--

local lib = { type = 'four.V2' }
lib.__index = lib
four.V2 = lib
setmetatable(lib, { __call = function(lib, ...) return lib.V2(...) end })

-- h2. Constructor and accessors

local meta = {} -- for operators, see at the end of file

--[[--
  @V2(x, y)@ is a vector with the corresponding components.

  @V2(o)@ is a vector converted from the object @o@. Supported types
  for @o@: @bt.Vector3@.
--]]--
function lib.V2(x, y) 
  local v = {}
  if y then v = {x, y}  
  else
    if x.type == "bt.Vector3" then v = { x:getX(), x:getY() }
    else
      assert(false, string.format("Cannot convert %s to %s", x.type, lib.type))
    end
  end
  setmetatable(v, meta)
  return v
end

local V2 = lib.V2

-- @x(v)@ is the @x@ component of @v@.
function lib.x(v) return v[1] end

-- @y(v)@ is the @x@ component of @v@.
function lib.y(v) return v[2] end

-- @comp(i, v)@ is the @i@th component of @v@.
function lib.comp(i, v) return v[i] end


-- h2. Converters

-- @ofV3(v)@ is @V2(V3.x(v), V3.y(v))@.
function lib.ofV3(v) return V2(v[1], v[2]) end

-- @ofV4(v)@ is @V2(V4.x(v), V4.y(v))@.
function lib.ofV4(v) return V2(v[1], v[2]) end

-- @tuple(v)@ is @x, y@, the components of @v@.
function lib.tuple(v) return v[1], v[2] end

-- @tostring(v)@ is a textual representation of @v@.
function lib.tostring(v) return string.format("(%g %g)", v[1], v[2]) end


-- h2. Constants 

-- @zero()@ is a vector @(0, 0)@.
function lib.zero() return V2(0, 0) end

-- @ox()@ is a unit vector @(1, 0)@.
function lib.ox() return V2(1, 0) end

-- @oy()@ is a unit vector @(0, 1)@.
function lib.oy() return V2(0, 1) end

-- @huge()@ is a vector whose components are @math.huge@.
function lib.huge() return V2(math.huge, math.huge) end

-- @neg_huge()@ is a vector whose components are @-math.huge@.
function lib.neg_huge() return  V2(-math.huge, -math.huge) end


-- h2. Functions

-- @neg(v)@ is the inverse vector @-v@.
function lib.neg(v) return V2(-v[1], -v[2]) end

-- @add(u, v)@ is the vector addition @u + v@.
function lib.add(u, v) return V2(u[1] + v[1], u[2] + v[2]) end

-- @sub(u, v)@ is the vector subtraction @u - v@.
function lib.sub(u, v) return V2(u[1] - v[1], u[2] - v[2]) end

-- @mul(u, v)@ is the component wise mutiplication @u * v@.
function lib.mul(u, v) return V2(u[1] * v[1], u[2] * v[2]) end

-- @div(u, v)@ is the component wise division @u / v@.
function lib.div(u, v) return V2(u[1] / v[1], u[2] / v[2]) end

-- @smul(s, v)@ is the scalar mutiplication @sv@.
function lib.smul(s, v) return V2(s * v[1], s * v[2]) end

-- @half(v)@ is the half vector @smul(0.5, v)@.
function lib.half(v) return V2(0.5 * v[1], 0.5 * v[2]) end

-- @dot(u, v)@ is the dot product @u.v@.
function lib.dot(u, v) return u[1] * v[1] + u[2] * v[2] end

-- @norm(v)@ is the norm @|v|@.
function lib.norm(v) return math.sqrt (v[1] * v[1] + v[2] * v[2]) end

-- @norm2(v)@ is the squared norm @|v|^2@.
function lib.norm2(v) return v[1] * v[1] + v[2] * v[2] end

-- @unit(v)@ is the unit vector @v/|v|@.
function lib.unit(v) return lib.smul(1 / lib.norm(v), v) end

-- @homogene(v)@ is the vector @v/V3.z(v)@.
function lib.homogene(v) return V2(v[1] / v[2], 1.0) end

--[[--
  @polarUnit(theta)@ is a unit vector whose angular polar coordinate
  is given by @theta@.
--]]--
function lib.polarUnit(theta) V2(math.cos(theta), math.sin(theta)) end

-- @ortho(v)@ is @v@ rotated by @pi/2@.
function lib.ortho(v) return  V2(-v[0], v[1]) end

-- @mix(u, v, t)@ is the linear interpolation @u + t * (v - u)@.
function lib.mix(u, v, t) 
  return V2 (u[1] + t * (v[1] - u[1]), u[2] + t * (v[2] - u[2]))
end


-- h2. Taversal

-- @map(f, v)@ is @V2(f(v1), f(v2))@.
function lib.map(f, v) return V2(f(v[1]), f(v[2])) end

-- @mapi(f, v)@ is @V2(f(1, v1), f(2, v2)@.
function lib.mapi(f, v) return V2(f(1, v[1]), f(2, v[2])) end

-- @fold(f, acc, v)@ is @f(f(acc, v1), v2)@.
function lib.fold(f, acc, v)  return f(f(acc, v[1]), v[2]) end

-- @foldi(f, acc, v)@ is @f(f(acc, 1, v1), 2, v2)@.
function lib.foldi(f, acc, v) return f(f(acc, 1, v[1]), 2, v[2]) end

-- @iter(f, v)@ is @f(v1) f(v2)@.
function lib.iter(f, v) f(v[1]); f(v[2]) end

-- @iteri(f, v)@ is @f(1, v1) f(2, v2)@.
function lib.iteri(f, v) f(1, v[1]); f(2, v[2]) end


-- h2. Predicates

-- @forAll(p, v)@ is @p(v1) and p(v2).
function lib.forAll(p, v) return p(v[1]) and p(v[2]) end

-- @exists(p, v)@ is @p(v1) or p(v2)@.
function lib.exists(p, v) return p(v[1]) or p(v[2]) end

--[[--
  @eq(u, v [,eq])@ is @true@ if @u@ is equal to @v@ component wise.
  If [eq] is provided it used as the equality function.
--]]--
function lib.eq(u, v, eq) 
  if eq then return eq(u[1], v[1]) and eq(u[2], v[2])
  else return u[1] == v[1] and u[2] == v[2] end
end

--[[--
  @lt(u, v [,lt])@ is @true@ if @u@ is lower than @v@ component wise.
  If [lt] is provided it used as the comparison function.
--]]--
function lib.lt(u, v, lt) 
  if lt then return lt(u[1], v[1]) and lt(u[2], v[2])
  else return u[1] < v[1] and u[2] < v[2] end
end

--[[--
  @le(u, v [,le])@ is @true@ if @u@ is lower or equal than @v@ component wise.
  If [le] is provided it used as the comparison function.
--]]--
function lib.le(u, v, le) 
  if le then return le(u[1], v[1]) and le(u[2], v[2])
  else return u[1] <= v[1] and u[2] <= v[2] end
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
  c = cmp(u[2], v[2]) return c
end


-- h2. Operators

meta.__unm = lib.neg
meta.__add = lib.add
meta.__sub = lib.sub
meta.__mul = lib.smul
meta.__tostring = lib.tostring


