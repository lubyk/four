--[[--
  h1. four.Geometry

  A geometry object is the atomic geometrical rendering unit.  It
  defines a stream of vertex data for the vertex shader.
--]]--

-- Module definition

local lib = { type = 'four.Geometry' }
lib.__index = lib
four.Geometry = lib
setmetatable(lib, { __call = function(lib, ...) return lib.new(...) end})

local Buffer = four.Buffer
local V3 = four.V3

-- h2. Primitive constants
-- Defines how the vertex stream is interpreted.

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

local next_id = 0

function lib:set(def) for k, v in pairs(def) do self[k] = v end end
function lib.new(def)
  local self = 
    {  id = next_id,
       name = "",

       -- Vertex stream definition.
       -- Per vertex data is stored in the `data` field. The `indices`
       -- define the actual stream of vertex data by indexing into `data`.
       -- `primitive` defines how the stream should be interpreted.
       primitive = lib.TRIANGLES,
       indices = {}, -- Buffer of ints (any dim), indexing into data.
                     -- WARNING/TODO zero-based we cannot do anything here 
                     -- (or not)
       data = {}, -- Array of Buffers, all of the same size, defining
                  -- per vertex data.    
       semantics = {  -- Indexes into data, anything can be defined here.
         vertex = 1,
         normal = nil, 
         color = nil,
         uvs = {},
       },
       bound_radius = nil,       

       immutable = true, -- Geometry is immutable, the renderer will call 
                         -- self:disposeBuffers(), once it has the data.
       dirty = false, -- Geometry is mutable and was touched. The renderer
                      -- sets this to false once it got the new data.

       -- TODO keep that in sync with indices, we need it after it 
       -- was disposed
       _indices_count = 0,
       _indices_scalar_type = Buffer.UNSIGNED_INT,

    }
  next_id = next_id + 1
  setmetatable(self, lib)
  if def then self:set(def) end
  return self
end

-- h2. Geometry operations

-- Disposes the geometry's indices and vertex data.
function lib:disposeBuffers() 
  -- TODO introduce a real accessor for indices don't do that here
  self._indices_count = self.indices:length ()
  self._indices_scalar_type = self.indices.scalar_type
  self.indices = nil 
  self.data = {}
end

-- Computes the radius of the bounding sphere containing all the vertex data. 
-- If self.semantics.vertices is nil the radius is zero.
function lib:computeBoundRadius ()
  -- self.data.vertices 
  local vindex = self.semantics.vertices 
  if (not vindex) then self.bound_radius = nil return end

  local function maxNorm2 (max, x, y, z)
    local norm2 = x * x + y * y + z * z
    if norm2 > max then return norm2 else return max end
  end
  
  self.bound_radius = math.sqrt(self.data[vindex]:fold3(maxNorm2, 0))
end

-- Computes vertex normals for TRIANGLE primitive
function lib:computeVertexNormals () error ("TODO") end

function lib:indicesCount() return self._indices_count end
function lib:indicesScalarType() return self._indices_scalar_type end

-- h2. Predefined geometries


-- TODO Cube

-- Cuboid(V3(w, h, d)) is a cuboid centered on the origin with the given
-- extents. 
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

  return lib.new ({ primitive = lib.TRIANGLES, 
                    indices = is, data = { vs },
                    semantics = { vertex = 1 },
                    extents = extents })
end
