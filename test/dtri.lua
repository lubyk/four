-- Delaunay triangulation according to Paul Bourke's algorithm
-- http://paulbourke.net/papers/triangulate/

require 'lubyk'

local V3 = four.V3
local Buffer = four.Buffer
local Geometry = four.Geometry 
local lib = {} 

local TRI_EPS = 1e-5

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
  elseif x1 > x0 then return 1 
  else return 0 end
end


--[[--
  @angulation(ps [, index [, sort] ])@ is a Buffer (zero-based) index 
  representing the Delaunay triangulation in xy coordinates of the 2D or 
  3D point set @ps@. 

  If @index@ is present, this object returned (@index.dim@ must be 3, and 
  @index.data@ is overwritten).

  If @sort@ is @true@, the triangles are specified so that the first
  index is the smallest one, and the triangles are sorted 
  lexicographically. 
--]]--
function lib.angulation(ps, index, sort)
  local tris = index or Buffer { dim = 3, scalar_type = Buffer.UNSIGNED_INT }
  assert(tris.dim == 3)
  tris.updated = true
  tris.data = {}

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
    local j = 0
    while j < tris:length() do 
      j = j + 1
      if not complete[j] then 
        local k1, k2, k3 = tris:get3D(j) -- indices are zero based
        local x1, y1 = ps:get2D(k1 + 1)
        local x2, y2 = ps:get2D(k2 + 1)
        local x3, y3 = ps:get2D(k3 + 1)
        inside, right = inCircumCircle(px, py, x1, y1, x2, y2, x3, y3)
        if right then complete[j] = true end
        if inside then 
          local b = #edges
          edges[b + 1] = { k1, k2 }
          edges[b + 2] = { k2, k3 }
          edges[b + 3] = { k3, k1 }
          -- Delete triangle 
          tri_count = tris:length()
          tris:swap(j, tri_count)
          tris:delete(tri_count)
          complete[j] = complete[tri_count]
          complete[tri_count] = nil
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
          else -- correct order 
          end
        end
        tris:push3D(k1, k2, k3)
        complete[tris:length()] = false
      end
    end
  end
  
  -- Delete triangles with supertriangle vertices
  local j = 0 
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

  if sort then tris:sort(V3.compare) end

  return tris
end

return lib

