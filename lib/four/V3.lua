--[[--
  # four.V3
  3D float vectors
--]]--

-- Module definition  

local lib = { type = 'four.V3' }
lib.__index = lib
four.V3 = lib
setmetatable(lib, { __call = function(lib, x, y, z) return lib.V3(x,y,z) end })

-- ## Constructor

local meta = {} -- for operators

function lib.V3(x, y, z) 
  local o = { x, y, z }  
  setmetatable(o, meta)
  return o
end

local V3 = lib.V3

-- ## Converters

function lib.tuple(v) return v[1], v[2], v[3] end
function lib.tostring(v) 
  return string.format("(%g %g %g)", v[1], v[2], v[3])
end

-- ## Constants 

function lib.zero() return V3(0, 0, 0) end
function lib.ox() return V3(1, 0, 0) end
function lib.oy() return V3(0, 1, 0) end
function lib.oz() return V3(0, 0, 1) end
function lib.huge() return V3(math.huge, math.huge, math.huge) end
function lib.neg_huge() return V3(-math.huge, -math.huge, -math.huge) end

-- ## Functions

function lib.neg(v) return V3(-v[1], -v[2], -v[3]) end
function lib.add(u, v) return V3(u[1] + v[1], u[2] + v[2], u[3] + v[3]) end
function lib.sub(u, v) return V3(u[1] - v[1], u[2] - v[2], u[3] - v[3]) end
function lib.mul(u, v) return V3(u[1] * v[1], u[2] * v[2], u[3] * v[3]) end
function lib.div(u, v) return V3(u[1] / v[1], u[2] / v[2], u[3] / v[3]) end
function lib.smul(s, v) return V3(s * v[1], s * v[2], s * v[3]) end
function lib.half(v) return V3(0.5 * v[1], 0.5 * v[2], 0.5 * v[3]) end
function lib.cross(u, v) return 
  V3 ((u[2] * v[3]) - (u[3] * v[2]),
      (u[3] * v[1]) - (u[1] * v[3]),
      (u[1] * v[2]) - (u[2] * v[1])) 
end

function lib.dot(u, v) return u[1] * v[1] + u[2] * v[2] + u[3] * v[3] end
function lib.norm(v) 
  return math.sqrt (v[1] * v[1] + v[2] * v[2] + v[3] * v[3])
end

function lib.norm2(v) return v[1] * v[1] + v[2] * v[2] + v[3] * v[3] end
function lib.unit(v) return lib.smul(1 / lib.norm(v), v) end
function lib.homogene(v) return V3(v[1] / v[3], v[2] / v[3], 1.0) end
function lib.sphereUnit(theta, phi)
  local tc, ts = math.cos(theta), math.sin(theta)
  local pc, ps = math.cos(phi), math.sin(phi)
  return V3(tc * ps, ts * ps, pc)
end

function lib.mix(u, v, t) 
  return V3 (u[1] + t * (v[1] - u[1]),
             u[2] + t * (v[2] - u[2]),
             u[3] + t * (v[3] - u[3]))
end

-- transforms the *vector* `v` with `m`
function trVec(m, v) 
  return V3 (m[1] * v[1] + m[5] * v[2] + m[ 9] * v[3],
             m[2] * v[1] + m[6] * v[2] + m[10] * v[3],
             m[3] * v[1] + m[7] * v[2] + m[11] * v[3])
end

-- transforms the *point* `pt` with `m`
function trPt(m, pt) 
  return V3 (m[1] * v[1] + m[5] * v[2] + m[ 9] * v[3] + m[13],
             m[2] * v[1] + m[6] * v[2] + m[10] * v[3] + m[14],
             m[3] * v[1] + m[7] * v[2] + m[11] * v[3] + m[15])
end

-- ## Taversal

function lib.map(f, v) return V3(f(v[1]), f(v[2]), f(v[3])) end
function lib.mapi(f, v) return V3(f(1, v[1]), f(2, v[2]), f(3, v[3])) end
function lib.fold(f, acc, v)  return f(f(f(acc, v[1]), v[2]), v[3]) end
function lib.foldi(f, acc, v) return f(f(f(acc, 1, v[1]), 2, v[2]), 3, v[3]) end
function lib.iter(f, v) f(v[1]); f(v[2]); f(v[3]) end
function lib.iteri(f, v) f(1, v[1]); f(2, v[2]); f(3, v[3]) end

-- ## Predicates

function lib.forAll(p, v) return p(v[1]) and p(v[2]) and p(v[3]) end
function lib.exists(p, v) return p(v[1]) or p(v[2]) or p(v[3]) end
function lib.equal(u, v) 
  return u[1] == v[1] and u[2] == v[2] and u[3] ==v[3]
end

function lib.equalF(f, u, v)
  return f(u[1], v[1]) and f(u[2], v[2]) and f(u[3], v[3])
end

function lib.compare(u, v) error ("TODO") end
function lib.compareF(f, u, v) error ("TODO") end

-- ## Operators

meta.__unm = lib.neg
meta.__add = lib.add
meta.__sub = lib.sub
meta.__mul = lib.smul
meta.__tostring = lib.tostring


