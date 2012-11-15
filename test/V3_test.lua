--[[--
  four.V3 test
--]]--

require 'lubyk'
local should = test.Suite("four")

local V3 = four.V3

-- Mostly testing on integers so that arithmetic is exact.

local EPS = 1e-6

function should.converters()
  local v = V3(3, 4, 5)
  local x, y, z = V3.tuple(v)
  assertEqual(3, x)
  assertEqual(4, y)
  assertEqual(5, z)
  assertEqual("(3 4 5)", tostring(v))
end

function should.constants ()
  assertValueEqual(V3(0, 0, 0), V3.o)
  assertValueEqual(V3(1, 0, 0), V3.ox)
  assertValueEqual(V3(0, 1, 0), V3.oy)
  assertValueEqual(V3(0, 0, 1), V3.oz)
  assertValueEqual(V3(math.huge, math.huge, math.huge), V3.huge)
  assertValueEqual(V3(-math.huge, -math.huge, -math.huge), V3.neg_huge)
end

function should.functions ()
  local v1 = V3(1, 2, 3) 
  local v2 = V3(4, 5, 6)
  local v3 = V3(3, 2, 1) 
  local v4 = V3(12, 10, 6)
  local v5 = V3(12, 18, 6)

  assertValueEqual(V3(-1, -2, -3), V3.neg(v1))
  assertValueEqual(V3(5, 7, 9), V3.add(v1, v2))
  assertValueEqual(V3(2, 0, -2), V3.sub(v3, v1))
  assertValueEqual(V3(4, 10, 18), V3.mul(v1, v2))
  assertValueEqual(V3(3, 2, 1), V3.div(v4, v2))
  assertValueEqual(V3(3, 6, 9), V3.smul(3, v1))
  assertValueEqual(V3(6, 5, 3), V3.half(v4))
  assertValueEqual(V3.oz, V3.cross(V3.ox, V3.oy))
  assertValueEqual(1, V3.dot(V3.ox, V3.ox)) -- find better example
  assertValueEqual(1, V3.norm(V3.ox)) -- find better example
  assertValueEqual(true, math.abs(V3.norm (V3.unit(v1)) - 1) < EPS)
  assertValueEqual(V3(2, 3, 1), V3.homogene (v5))
  assertValueEqual(V3.oz, V3.sphereUnit(0.5 * math.pi, 0)) -- brittle test
  assertValueEqual(V3(1, 4, 6), V3.mix(V3(-2, 2, 4), V3(4, 6, 8), 0.5))
  assertError("TODO", function () ltr(nil, v1) end)
  assertError("TODO", function () tr(nil, v1) end)
end

function should.traverals ()
  -- TODO
end

function should.predicates ()
  -- TODO
end

function should.operators()
  local v1 = V3(1, 2, 3) 
  local v2 = V3(4, 5, 6)
  assertValueEqual(V3(5, 7, 9), v1 + v2)
  assertValueEqual(V3(3, 3, 3), v2 - v1)
  assertValueEqual(V3(2, 4, 6), 2 * v1)
  assertValueEqual(V3(-1, -2, -3), -v1)
  assertValueEqual("(1 2 3)", tostring(v1))
end
