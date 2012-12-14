--[[--
  A few useful geometrical tools.
  * Find the circumcenter of 3 points in 3D
  * Delaunay triangulation
  * Half-edge data structure 
  * Triangulation adjacency computation.
  * Volume (Cuboid) uniform sampling.
--]]--

require 'lubyk' 

local lib = {}
local Buffer = four.Buffer
local V3 = four.V3
local Buffer = four.Buffer
local Geometry = four.Geometry 

--[[--
   h2. Delaunay triangluation
   Implements Paul Bourke\'s algorithm.
   See http://paulbourke.net/papers/triangulate/
--]]--

local TRI_EPS = 1e-5

--[[--
  @circumcenter(p, q, r) returns the center of the 3D triangle
  defined by the V3 @p@, @q@ and @r@.
--]]--
function lib.circumcenter(p, q, r) -- in 3D
  -- See Geometric Data Structures for Computer Graphics, 
  -- E. Langetepe, G. Zachman pp. 259.
  local pMr = p - r
  local qMr = q - r
  local pMrlen2 = V3.norm2(pMr)
  local qMrlen2 = V3.norm2(qMr)
  local pMrXqMr = V3.cross(pMr, qMr) 
  local f = 1 / (2 * V3.norm2(pMrXqMr))
  return r + f * V3.cross(pMrlen2 * qMr - qMrlen2 * pMr, pMrXqMr)
end

--[[--
  @inCircumCircle(px, py, x1, y1, x2, y2, x3, y3)@ is @(inside, right)@ where
  @inside@ is @true@ iff @p@ is in or on the edge of the circum circle
  of points 1, 2, 3 and @right@ is @true@ iff @inside@ is false and @p@
  is on the right (x-axis) of the circle.
--]]--
local function inCircumCircle(px, py, x1, y1, x2, y2, x3, y3)
  local m1, m2, mx1, mx2, my1, my2
  local xc, yc
  local dy12 = math.abs(y1 - y2)
  local dy23 = math.abs(y2 - y3)
  if dy12 < TRI_EPS and dy23 < TRI_EPS then return false, false end

  if dy12 < TRI_EPS then 
    m2 = -(x3 - x2) / (y3 - y2)
    mx2 = 0.5 * (x2 + x3)
    my2 = 0.5 * (y2 + y3)
    xc = 0.5 * (x2 + x1)
    yc = m2 * (xc - mx2) + my2
  elseif dy23 < TRI_EPS then
    m1 = - (x2-x1) / (y2-y1)
    mx1 = 0.5 * (x1 + x2)
    my1 = 0.5 * (y1 + y2)
    xc = 0.5 * (x3 + x2)
    yc = m1 * (xc - mx1) + my1
  else
    m1 = - (x2-x1) / (y2-y1)
    m2 = - (x3-x2) / (y3-y2)
    mx1 = 0.5 * (x1 + x2)
    mx2 = 0.5 * (x2 + x3)
    my1 = 0.5 * (y1 + y2)
    my2 = 0.5 * (y2 + y3)
    xc = (m1 * mx1 - m2 * mx2 + my2 - my1) / (m1 - m2)
    if dy12 > dy23 then yc = m1 * (xc - mx1) + my1
    else yc = m2 * (xc - mx2) + my2 end
  end

  local dx = x2 - xc
  local dy = y2 - yc
  local rsquared = dx * dx + dy * dy
  local dx = px - xc
  local dy = py - yc
  local d = dx * dx + dy * dy

  return (d - rsquared <= TRI_EPS), (xc < px and dx * dx > rsquared)
end

local function xcmp(x0, x1) 
  if x0 < x1 then return -1 
  elseif x0 > x1 then return 1 
  else return 0 end
end

--[[--
  @triangulation(ps [, index [, sort] ])@ is a zero-based index Buffer 
  representing the Delaunay triangulation in xy coordinates of the 2D or 
  3D point set @ps@. 

  If @index@ is present, this object returned (@index.dim@ must be 3, and 
  data is appended to the object).

  If @sort@ is @true@, the triangles are specified so that the first
  index is the smallest one.
--]]--
function lib.triangulation(ps, index, sort)
  local tris = index or Buffer { dim = 3, scalar_type = Buffer.UNSIGNED_INT }
  local tri_start = tris:length()
  assert(tris.dim == 3)
  tris.updated = true

  local pcount = ps:length() 
  local xorder = ps:sortOrder(xcmp, Buffer.get1D)
  local exts = ps:dimExtents()
  local complete = {}

  local dmax = math.max(exts[1].max - exts[1].min, exts[2].max - exts[2].min)
  local xmid = 0.5 * (exts[1].max + exts[1].min)
  local ymid = 0.5 * (exts[2].max + exts[2].min)

  -- Temporarily add super triangle vertice at the end of the point buffer 
  ps:set2D(pcount + 1, xmid - 20 * dmax, ymid - dmax)
  ps:set2D(pcount + 2, xmid + 20 * dmax, ymid - dmax)
  ps:set2D(pcount + 3, xmid, ymid + 20 * dmax)
  
  -- Add CW super triangle to the triangles 
  tris:push3D(pcount + 0, pcount + 1, pcount + 2) -- indices are zero based
  complete[1] = false

  for i = 1, pcount do 
    local px, py = ps:get2D(xorder[i])
    local edges = {}
    local j = tri_start
    while j < tris:length() do 
      j = j + 1
      if not complete[j - tri_start] then 
        local k1, k2, k3 = tris:get3D(j) -- indices are zero based
        local x1, y1 = ps:get2D(k1 + 1)
        local x2, y2 = ps:get2D(k2 + 1)
        local x3, y3 = ps:get2D(k3 + 1)
        inside, right = inCircumCircle(px, py, x1, y1, x2, y2, x3, y3)
        if right then complete[j - tri_start] = true end
        if inside then 
          local b = #edges
          edges[b + 1] = { k1, k2 }
          edges[b + 2] = { k2, k3 }
          edges[b + 3] = { k3, k1 }
          -- Delete triangle 
          tri_count = tris:length()
          tris:swap(j, tri_count)
          tris:delete(tri_count)
          complete[j - tri_start] = complete[tri_count - tri_start]
          complete[tri_count - tri_start] = nil
          j = j - 1          
        end
      end
    end

    -- Delete multiple edges
    for j = 1, #edges - 1 do 
      for k = j + 1, #edges do 
        if edges[j][1] == edges[k][2] and edges[j][2] == edges[k][1] then 
          edges[j][1] = -1 
          edges[j][2] = -1 
          edges[k][1] = -1 
          edges[k][2] = -1
        end
      end
    end

    for j = 1, #edges do 
      if edges[j][1] ~= -1 and edges[j][2] ~= -1 then 
        local k1 = edges[j][1]
        local k2 = edges[j][2]
        local k3 = xorder[i] - 1
        if sort then
          local min = math.min(k1, k2, k3)
          if min == k2 then 
            k2 = k3 
            k3 = k1 
            k1 = min
          elseif min == k3 then 
            k3 = k2 
            k2 = k1 
            k1 = min 
          else -- order is correct
          end
        end
        tris:push3D(k1, k2, k3)
        complete[tris:length() - tri_start] = false
      end
    end
  end
  
  -- Delete triangles with supertriangle vertices
  local j = tri_start
  while j < tris:length() do 
    j = j + 1
    local k1, k2, k3 = tris:get3D(j)
    if k1 >= pcount or k2 >= pcount or k3 >= pcount then 
      tris:delete(j)
      j = j - 1
    end
  end

  -- Clear supertriangle vertices
  ps:set2D(pcount + 1, nil, nil)
  ps:set2D(pcount + 2, nil, nil)
  ps:set2D(pcount + 3, nil, nil)

  return tris
end


-- h2. Half-edge data structure

--[[--
  @hdsFromTriangles(tris)@ is a half-edge data structure for vertex
  indices of the triangles stored in the @tris@ Buffer object. No two
  different indices in @tris@ must represent the same vertice,
  otherwise the information will be incorrect.

  *Warning*, tris indexes vertices with zero-based indexing. All the 
  indexes below are however one-based.

  The result is a table with the following keys:
  * @vertex@, maps each vertex index to one of its incident 
     half-edges (indexes into @halfedge@).
  * @face@, maps each face to one of the half-edges that bounds it
    (indexes into @halfedge@).
  * @halfedge@, maps each one-based indexed half-edge to a table with the 
    following keys:
  ** @dest@, the other points of the edge.
  ** @face@, the face it belongs to. 
  ** @next@, the next half-edge inside the face in CCW order.
  ** @twin@, the half-edge opposite to that edge (if any).
--]]--
function lib.hdsFromTriangles(tris)
  assert(tris.dim == 3)
  local hds = { vertex = {}, face = {}, halfedge = {} } 
  local vmap = {} -- maps two vertex indices to an edge index
  local edge = -3
  local face = 0

  local function addEdge(face, edge, next, a, b)
    local info = { dest = b, face = face, next = next, twin = nil } 
    if not hds.vertex[a] then hds.vertex[a] = edge end
   
    local twin = vmap[b] and vmap[b][a] or nil
    if twin then 
      info.twin = twin 
      hds.halfedge[twin].twin = edge
    else
      vmap[a] = vmap[a] or {} 
      vmap[a][b] = edge
    end
      
    hds.halfedge[edge] = info
  end

  for i = 1,tris:length() do 
    local ka, kb, kc = tris:get3D(i)
    ka = ka + 1 kb = kb + 1 kc = kc + 1 
    face = face + 1
    edge = edge + 3
    local e1 = edge + 1 
    local e2 = edge + 2
    local e3 = edge + 3
    addEdge(face, e1, e2, ka, kb) 
    addEdge(face, e2, e3, kb, kc)
    addEdge(face, e3, e1, kc, ka)
    hds.face[face] = e1
  end
  return hds
end

--[[--
  @trianglesHdsToAdjacencyIndex(hds [, is])@ is a zero-based index Buffer
  suitable for @Geometry@'s @Geometry.TRIANGLES_ADJACENCY@ primitive. 
  
  If @is@ is present, this object is returned and data is appended to it.

  *Warning*. Assumes that @hds@ is describing triangles and TODO was 
  generated by the function @hdsFromTriangles@.
--]]--
function lib.trianglesHdsToAdjacencyIndex(hds, is)
  local is = is or Buffer { dim = 3, scalar_type = Buffer.UNSIGNED_INT }
  is.updated = true
  
  -- Note this depends on how hds is generated. 
  for i = 1,#hds.halfedge / 3 do
    local b = (i - 1) * 3
    local he1 = hds.halfedge[b + 1]
    local he1_twin = he1.twin and hds.halfedge[he1.twin] or nil
    local he2 = hds.halfedge[b + 2]
    local he2_twin = he2.twin and hds.halfedge[he2.twin] or nil
    local he3 = hds.halfedge[b + 3]
    local he3_twin = he3.twin and hds.halfedge[he3.twin] or nil

    -- Theses -1 are here because of zero-based index.
    is:push(he3.dest - 1)
    is:push(he1_twin and hds.halfedge[he1_twin.next].dest - 1 or he3.dest - 1)
    is:push(he1.dest - 1)
    is:push(he2_twin and hds.halfedge[he2_twin.next].dest - 1 or he1.dest - 1)
    is:push(he2.dest - 1)
    is:push(he3_twin and hds.halfedge[he3_twin.next].dest - 1 or he2.dest - 1)
  end
  return is
end

-- TODO do it directly.
function lib.trianglesAdjacencyIndex(tris, is) 
  local hds = lib.hdsFromTriangles(tris)
  lib.trianglesHdsToAdjacencyIndex(hds, is)
end


-- h2. Volume sampling

--[[-- 
  @sampleCuboid(count, min, max [, pts])@ is a Buffer with @count@ 
  random 3D points distributed uniformly in the cuboid defined by the two 
  extreme points @min@ and @max@. 

  If @pts@ is present, this object is returned and points are added to it.

  *Warning* Uses rejection sampling. Make sure that the cuboid is not
  much larger/smaller in a single dimension or the generation may take
  an arbitrary amount of time. Planar and linear specification (equal
  min and max in some dimensions) are however not a problem.
--]]--
function lib.sampleCuboid(count, min, max, pts)
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
