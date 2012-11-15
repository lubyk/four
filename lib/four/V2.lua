--[[--
  # four.V2
  2D float vectors
--]]--

-- Module definition
  
local lib = { type = 'four.V2' }
lib.__index = lib
four.V2 = lib
setmetatable(lib, { __call = function(lib, x, y) return lib.V2(x, y) end })

-- ## Constructor

local meta = {} -- for operators

function lib.V2(x, y) 
  local o = {x, y}  
  setmetatable(o, meta)
  return o
end

local V2 = lib.V2

-- ## Converters

function lib.tuple(v) return v[1], v[2] end
function lib.tostring(v) return string.format("(%g %g)", v[1], v[2]) end

-- ## Constants 

function lib.zero() return V2(0, 0) end
function lib.ox() return V2(1, 0) end
function lib.oy() return V2(0, 1) end
function lib.huge() return V2(math.huge, math.huge) end
function lib.neg_huge() return  V2(-math.huge, -math.huge) end

-- ## Functions

function lib.neg(v) return V2(-v[1], -v[2]) end
function lib.add(u, v) return V2(u[1] + v[1], u[2] + v[2]) end
function lib.sub(u, v) return V2(u[1] - v[1], u[2] - v[2]) end
function lib.mul(u, v) return V2(u[1] * v[1], u[2] * v[2]) end
function lib.div(u, v) return V2(u[1] / v[1], u[2] / v[2]) end
function lib.smul(s, v) return V2(s * v[1], s * v[2]) end
function lib.half(v) return V3(0.5 * v[1], 0.5 * v[2]) end
function lib.dot(u, v) return u[1] * v[1] + u[2] * v[2] end
function lib.norm(v) return math.sqrt (v[1] * v[1] + v[2] * v[2]) end
function lib.norm2(v) return v[1] * v[1] + v[2] * v[2] end
function lib.unit(v) return lib.smul(1 / lib.norm(v), v) end
function lib.homogene(v) return V2(v[1] / v[2], 1.0) end
function lib.polarUnit(theta) V2(math.cos(theta), math.sin(theta)) end
function lib.ortho(v) return  V2(-v[0], v[1]) end
function lib.mix(u, v, t) 
  return V2 (u[1] + t * (v[1] - u[1]), u[2] + t * (v[2] - u[2]))
end

-- ## Taversal

function lib.map(f, v) return V2(f(v[1]), f(v[2])) end
function lib.mapi(f, v) return V2(f(1, v[1]), f(2, v[2])) end
function lib.fold(f, acc, v)  return f(f(acc, v[1]), v[2]) end
function lib.foldi(f, acc, v) return f(f(acc, 1, v[1]), 2, v[2]) end
function lib.iter(f, v) f(v[1]); f(v[2]) end
function lib.iteri(f, v) f(1, v[1]); f(2, v[2]) end

-- ## Predicates

function lib.forAll(p, v) return p(v[1]) and p(v[2]) end
function lib.exists(p, v) return p(v[1]) or p(v[2]) end
function lib.equal(u, v) return u[1] == v[1] and u[2] == v[2] end
function lib.equalF(f, u, v) return f(u[1], v[1]) and f(u[2], v[2]) end
function lib.compare(u, v) error ("TODO") end
function lib.compareF(f, u, v) error ("TODO") end

-- ## Operators

meta.__unm = lib.neg
meta.__add = lib.add
meta.__sub = lib.sub
meta.__mul = lib.smul
meta.__tostring = lib.tostring


