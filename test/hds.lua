-- Half-edge data structure.

require 'lubyk'

local Buffer = four.Buffer
local Geometry = four.Geometry 
local lib = {} 

--[[--
  @FromTriangles(tris)@ is a half-edge data structure for vertex
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
function lib.FromTriangles(tris)
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

  local old_dim = tris.dim -- fix iteration if needed.
  tris.dim = 3
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
  tris.dim = old_dim

  return hds
end

--[[--
  @trianglesAdjacencyIndex(hds, is)@ is a Buffer (zero-based) index suitable 
  for @Geometry@'s @Geometry.TRIANGLES_ADJACENCY@ primitive. If @is@ is non
  nil, this Buffer with the index data is returned.

  *Warning*. Assumes that @hds@ is describing triangles. 
--]]--
function lib.trianglesAdjacencyIndex(hds, is)
  local is = is or Buffer { dim = 1, scalar_type = Buffer.UNSIGNED_INT }
  is.data = {} 
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

return lib





