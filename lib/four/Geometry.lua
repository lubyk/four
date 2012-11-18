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
function lib:computeVertexNormals () error ("TODO") end

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
  vs:push3D(-x, -y, -z)
  vs:push3D( x, -y, -z)
  vs:push3D(-x,  y, -z)
  vs:push3D( x,  y, -z)
  vs:push3D(-x, -y,  z)
  vs:push3D( x, -y,  z)
  vs:push3D(-x,  y,  z)  
  vs:push3D( x,  y,  z)

  -- Faces (triangles), TODO seems wrong orientation
  is:push3D(0, 2, 3)
  is:push3D(0, 3, 1)
  is:push3D(0, 1, 5)
  is:push3D(0, 5, 4)
  is:push3D(0, 4, 6)
  is:push3D(0, 6, 2)
  is:push3D(1, 3, 7)
  is:push3D(1, 7, 5)
  is:push3D(2, 6, 7)
  is:push3D(2, 7, 3)
  is:push3D(4, 5, 7)
  is:push3D(4, 7, 6)

  return lib.new ({ name = "four.cuboid", primitive = lib.TRIANGLES, 
                    data = { vertex = {vs} }, index = is, 
                    extents = extents })
end

-- @Cube(s)@ is a cube with side length @s@ centered on the origin.
function lib.Cube(s) return lib.Cuboid(V3(s, s, s)) end
