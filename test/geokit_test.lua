-- Geometry viewer

require 'lubyk'

local Geokit = require 'geokit'
local Geometry = four.Geometry
local V2 = four.V2
local V3 = four.V3

local should = test.Suite("geokit")

function should.circumcenter()
  
  -- TODO use comparison with eps
--  assertEqual(Geokit.circumcenter(V3.ox(), V3.oy(), V3.oz()), 
--              V3(1/3, 1/3, 1/3))
end

function should.planeHDS()
  -- N.B. these assertions depend on the index given by Plane and 
  -- the way hdsFromTriangles operates. 

  local p = Geometry.Plane(V2(1,2))
  local hds = Geokit.hdsFromTriangles(p.index)

  -- TODO Plane indices changed ! 

  -- assertEqual(hds.vertex[1], 1)  
  -- assertEqual(hds.vertex[2], 2)
  -- assertEqual(hds.vertex[3], 3)
  -- assertEqual(hds.vertex[4], 6)

  -- assertEqual(hds.face[1], 1)
  -- assertEqual(hds.face[2], 4)

  -- assertEqual(hds.halfedge[1].dest, 2)
  -- assertEqual(hds.halfedge[1].face, 1)
  -- assertEqual(hds.halfedge[1].next, 2)
  -- assertEqual(hds.halfedge[1].twin, nil)

  -- assertEqual(hds.halfedge[2].dest, 3)
  -- assertEqual(hds.halfedge[2].face, 1)
  -- assertEqual(hds.halfedge[2].next, 3)
  -- assertEqual(hds.halfedge[2].twin, nil)

  -- assertEqual(hds.halfedge[3].dest, 1)
  -- assertEqual(hds.halfedge[3].face, 1)
  -- assertEqual(hds.halfedge[3].next, 1)
  -- assertEqual(hds.halfedge[3].twin, 4)

  -- assertEqual(hds.halfedge[4].dest, 3)
  -- assertEqual(hds.halfedge[4].face, 2)
  -- assertEqual(hds.halfedge[4].next, 5)
  -- assertEqual(hds.halfedge[4].twin, 3)

  -- assertEqual(hds.halfedge[5].dest, 4)
  -- assertEqual(hds.halfedge[5].face, 2)
  -- assertEqual(hds.halfedge[5].next, 6)
  -- assertEqual(hds.halfedge[5].twin, nil)

  -- assertEqual(hds.halfedge[6].dest, 1)
  -- assertEqual(hds.halfedge[6].face, 2)
  -- assertEqual(hds.halfedge[6].next, 4)
  -- assertEqual(hds.halfedge[6].twin, nil)
end

function should.planeTrianglesAdjacency()
  local p = Geometry.Plane(V2(1,2), V2(1, 2))
  local i = p.index

  assertValueEqual(V3(0, 1, 3), p.index:getV3(1))
  assertValueEqual(V3(0, 3, 2), p.index:getV3(2))
  assertValueEqual(V3(2, 3, 5), p.index:getV3(3))
  assertValueEqual(V3(2, 5, 4), p.index:getV3(4))

  local hds = Geokit.hdsFromTriangles(p.index)
  local i = Geokit.trianglesHdsToAdjacencyIndex(hds)

  assertEqual(i:getScalar(1), 0)
  assertEqual(i:getScalar(2), 0)
  assertEqual(i:getScalar(3), 1)
  assertEqual(i:getScalar(4), 1)
  assertEqual(i:getScalar(5), 3)
  assertEqual(i:getScalar(6), 2)

  assertEqual(i:getScalar(7), 0)
  assertEqual(i:getScalar(8), 1)
  assertEqual(i:getScalar(9), 3)
  assertEqual(i:getScalar(10), 5)
  assertEqual(i:getScalar(11), 2)
  assertEqual(i:getScalar(12), 2)

  assertEqual(i:getScalar(13), 2)
  assertEqual(i:getScalar(14), 0)
  assertEqual(i:getScalar(15), 3)
  assertEqual(i:getScalar(16), 3)
  assertEqual(i:getScalar(17), 5)
  assertEqual(i:getScalar(18), 4)

  assertEqual(i:getScalar(19), 2)
  assertEqual(i:getScalar(20), 3)
  assertEqual(i:getScalar(21), 5)
  assertEqual(i:getScalar(22), 5)
  assertEqual(i:getScalar(23), 4)
  assertEqual(i:getScalar(24), 4)
end





