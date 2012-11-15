--[[--
  h1. four.Effect

  An effect defines a configuration of the graphics pipeline 
  for rendering a Geometry object.

  Apply effect to Geometry.
  Vertex shader input names need to match geometry.semantics.
--]]--

-- Module definition

local lib = { type = 'four.Effect' }
lib.__index = lib
four.Effect = lib
setmetatable(lib, { __call = function(lib, ...) return lib.new(...) end})

-- h2. Constructor

local next_id = 0
function lib:set(def) 
  for k, v in pairs(def) do 
    if k ~= "id" then self[k] = v end
  end
end

function lib.new(def)
  local self = 
    { id = next_id,
      glsl_version = "150",
      vertex_shader = "void main(void) {}",
      geometry_shader = nil, -- optional
      fragment_shader = "void main(void) {}",
      uniforms = {}}

  next_id = next_id + 1
  setmetatable(self, lib)
  if def then self:set(def) end
  return self
end

-- h2. Uniform constructors

lib.bt = 1
lib.it = 2
lib.ut = 3
lib.ft = 4

function lib.U(o) -- TODO opt param for ivec int etc.
  local ot = type(o)
  if ot == "boolean" then return { dim = 1, typ = lib.bt, v = { o and 1 or 0 } }
  elseif ot == "number" then return { dim = 1, typ = lib.ft, v = { o } } 
  elseif ot == "table" then 
    local dim = #o 
    if dim > 5 and dim ~= 16 then error("unsupported uniform type") else
      return { dim = dim, typ = lib.ft, v = o}
    end
  else
    error ("unsupported uniform type")
  end
end

-- glsl meta programming

local function glsl_version(v) return string.format("#version %s\n", v) end
local function glsl_for_u(n, u)
  local s = string.format
  if u.dim == 1 then 
    if u.typ == lib.bt then return s("uniform bool %s;", n)
    elseif u.typ == lib.it then return s("uniform int %s;", n)
    elseif u.typ == lib.ut then return s("uniform uint %s;", n)
    elseif u.typ == lib.ft then return s("uniform float %s;", n)
    else assert(false) end
  elseif u.dim <= 5 then
    if u.typ == lib.bt then return s("uniform bvec%d %s;", u.dim, n)
    elseif u.typ == lib.it then return s("uniform ivec%d %s;", u.dim, n)
    elseif u.typ == lib.ut then return s("uniform uvec%d %s;", u.dim, n)
    elseif u.typ == lib.ft then return s("uniform vec%d %s;", u.dim, n)
    else assert(false) end
  elseif u.dim == 16 then return s("uniform mat4 %s;", n)
  else assert(false) end
end

function lib:glsl_preamble() -- TODO cache
  -- TODO bundle default geometric uniforms
  local uniforms = ""
  for k, v in pairs(self.uniforms) do
    uniforms = uniforms .. glsl_for_u(k, v) .. "\n"
  end
  return glsl_version(self.glsl_version) .. uniforms
end

-- h2. Effect parameters

function lib:vertexShader() 
  return  self:glsl_preamble() .. self.vertex_shader
end

function lib:geometryShader()
  if not self._vertexShader then return nil end
  return self:glsl_preamble() .. self.vertex_shader
end

function lib:fragmentShader()
  return self:glsl_preamble() .. self.fragment_shader
end



------ 

function lib.FlatShading(color) 
local vertex_shader =
[[#version 150
in  vec3 vertex;
out vec3 color;
void main(void)
{
  gl_Position(vertex, 1.0)
}
]]

local fragment_shader = 
[[#version 150

in vec3 color;
out vec4 out_color;
void main (void) 
{
  out_color = vec4 (color, 1.0);
}
]]
end
