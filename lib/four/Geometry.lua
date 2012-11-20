--[[--
  h1. four.Geometry

  A geometry object is the atomic geometrical rendering unit. It
  defines the stream of vertex data for the vertex shader and the
  stream of primitives for the geometry shader.
--]]--

-- Module definition

local lib = { type = 'four.Geometry' }
lib.__index = lib
four.Geometry = lib
setmetatable(lib, { __call = function(lib, ...) return lib.new(...) end})

local Buffer = four.Buffer
local V3 = four.V3

-- h2. Primitive constants
-- Defines how the vertex stream is interpreted

lib.POINTS = 1
lib.LINE_STRIP = 2
lib.LINE_LOOP = 3
lib.LINES = 4
lib.LINE_STRIP_ADJACENCY = 5
lib.LINES_ADJACENCY = 6
lib.TRIANGLE_STRIP = 7
lib.TRIANGLE_FAN = 8
lib.TRIANGLES = 9
lib.TRIANGLE_STRIP_ADJACENCY = 10
lib.TRIANGLES_ADJACENCY = 11

-- h2. Constructor

--[[-- 
  @Geometry(def)@ is a new geometry object. @def@ keys:
  * @primitive@, the geometrical primitive (defaults to @Geometry.TRIANGLES@).
  * @data@, table of named @Buffer@s all of the same size defining per vertex
    data. Table key names are used to bind to the corresponding vertex shader 
    inputs.
  * @index@, @Buffer@ of ints (any dim), indexing into @data@ to define the 
    actual sequence of primitives. *WARNING* indices are zero-based.
  * @immutable@, if @true@, @data@ and @index@ are disposed after 
    the first render (defaults to true).
  * @name@, a user defined way of naming the geometry (may be used by
    the renderer to report errors about the object).
--]]--
function lib.new(def)
  local self = 
    { primitive = lib.TRIANGLES,
      data = {},
      index = nil,
      immutable = true,
      name = "",
      bound_radius = nil,
      dirty = false } -- Geometry is mutable and was touched. The renderer
                      -- sets this to false once it got the new data.
    setmetatable(self, lib)
    if def then self:set(def) end
    return self
end

function lib:set(def)
  if def.primitive then self.primitive = def.primitive end
  if def.data then self.data = def.data end  
  if def.index then self.index = def.index
  else error ("index is a required Geometry initialization key") end
  if def.immutable then self.immutable = def.immutable end
end

-- h2. Geometry operations

-- @disposeBuffers()@ sets @self.index@ to @nil@ and @self.data@ to 
-- @{}@. The renderer calls this function if @self.immutable@ is @true@.
function lib:disposeBuffers() 
  self.data = {}
  self.index = nil
end

--[[-- 
  @computeBoundsRadius()@ computes the radius of the bounding sphere 
  containing all the 3D points of @self.data.vertex@ and stores it in 
  @self.bound_radius@. If @data.vertex@ is @nil@ the radius is zero.
--]]--
function lib:computeBoundRadius ()
  local verts = self.data.vertex
  if not verts then self.bound_radius = 0 else
    local function maxNorm2 (max, x, y, z)
      local norm2 = x * x + y * y + z * z
      if norm2 > max then return norm2 else return max end
    end
    self.bound_radius = math.sqrt(verts:fold3(maxNorm2, 0))
  end
end

--[[--
  @computeVertexNormals()@ computes per vertex normals for all 
  the 3D points of @self.data.vertex@ and stores them in @self.data.normal@.
  *WARNING* works only with @Geometry.TRIANGLE@ primitive.
--]]--
function lib:computeVertexNormals ()
  local vertex = self.data.vertex 
  local index = self.index
  local tri_count = index:length() / 3
  local ns = Buffer { dim = 3, scalar_type = Buffer.FLOAT } 

  for i = 1, vertex:length(), 1 do ns:set3D(i, 0, 0, 0) end
  for i = 1, tri_count, 1 do
    local b = (i - 1) * 3
    local vi1 = index:get1D(b + 1) + 1
    local vi2 = index:get1D(b + 2) + 1
    local vi3 = index:get1D(b + 3) + 1
    local v1 = vertex:getV3(vi1)
    local v2 = vertex:getV3(vi2)
    local v3 = vertex:getV3(vi3)
    local n = V3.cross((v2 - v1), (v3 - v1))
    ns:setV3(vi1, ns:getV3(vi1) + n)
    ns:setV3(vi2, ns:getV3(vi2) + n)
    ns:setV3(vi3, ns:getV3(vi3) + n)
  end

  for i = 1, ns:length(), 1 do ns:setV3(i, V3.unit (ns:getV3(i))) end
  self.data.normal = ns
end

-- h2. Predefined geometries

--[[--
  @Cuboid(V3(w, h, d))@ is a cuboid centered on the origin with the given
  extents.
--]]--
function lib.Cuboid(extents)
  local x, y, z = V3.tuple(0.5 * extents)
  local vs = Buffer { dim = 3, scalar_type = Buffer.FLOAT } 
  local is = Buffer { dim = 1, scalar_type = Buffer.UNSIGNED_INT }
  
  -- Vertices
  vs:push3D(-x, -y,  z)
  vs:push3D( x, -y,  z)
  vs:push3D(-x,  y,  z)
  vs:push3D( x,  y,  z)
  vs:push3D(-x, -y, -z)
  vs:push3D( x, -y, -z)
  vs:push3D(-x,  y, -z)  
  vs:push3D( x,  y, -z)

  -- Faces (triangles)
  is:push3D(0, 3, 2)
  is:push3D(0, 1, 3)
  is:push3D(0, 5, 1)
  is:push3D(0, 4, 5)
  is:push3D(0, 6, 4)
  is:push3D(0, 2, 6)
  is:push3D(1, 7, 3)
  is:push3D(1, 5, 7)
  is:push3D(2, 7, 6)
  is:push3D(2, 3, 7)
  is:push3D(4, 7, 5)
  is:push3D(4, 6, 7)

  return lib.new ({ name = "four.cuboid", primitive = lib.TRIANGLES, 
                    data = { vertex = vs }, index = is, 
                    extents = extents })
end

-- @Cube(s)@ is a cube with side length @s@ centered on the origin.
function lib.Cube(s) return lib.Cuboid(V3(s, s, s)) end

--[[--
  @Sphere(r[,level])@ is a sphere of radius @r@ centered on the origin.
  The optional parameter @level@ defines the subdivision level (defaults
  to @10@. Number of triangles is @4^level * 8@
  
--]]--                                                                
function lib.Sphere(r, level)
  local ra = r / math.sqrt(2)
  local level = level or 4
  local vs = Buffer { dim = 3, scalar_type = Buffer.FLOAT } 
  local is = Buffer { dim = 3, scalar_type = Buffer.UNSIGNED_INT }

  -- Level 0 isocahedron 
  vs:push3D( 0,  0,  r)
  vs:push3D( 0,  0, -r)
  vs:push3D(-ra, -ra,  0)
  vs:push3D( ra, -ra,  0)
  vs:push3D( ra,  ra,  0)
  vs:push3D(-ra,  ra,  0)
  is:push3D(0, 3, 4)
  is:push3D(0, 4, 5)
  is:push3D(0, 5, 2)
  is:push3D(0, 2, 3)
  is:push3D(1, 4, 3)
  is:push3D(1, 5, 4)
  is:push3D(1, 2, 5)
  is:push3D(1, 3, 2)

  -- For each face we split its edges in two, move the new points on
  -- the sphere and add the resulting faces to the index
  for i = 1,level,1 do 
    for i = 1, is:length(), 1 do
      local p1i, p2i, p3i = is:get3D(i)
      local p1 = vs:getV3(p1i + 1) -- one based
      local p2 = vs:getV3(p2i + 1)
      local p3 = vs:getV3(p3i + 1)
      local pmaxi = vs:length()
      vs:pushV3(r * V3.unit(0.5 * (p1 + p2))) local pai = pmaxi -- zero based
      vs:pushV3(r * V3.unit(0.5 * (p2 + p3))) local pbi = pmaxi + 1
      vs:pushV3(r * V3.unit(0.5 * (p3 + p1))) local pci = pmaxi + 2
      is:push3D(p1i, pai, pci)
      is:push3D(pai, p2i, pbi)
      is:push3D(pbi, p3i, pci)
      is:set3D(i, pai, pbi, pci)
    end 
  end

  lk.log("TODO fix that in the renderer")
  is.dim = 1

  return lib.new({ name = "four.sphere", primitive = lib.TRIANGLES,
                   data = { vertex = vs }, index = is, 
                   extents = extents })
end

