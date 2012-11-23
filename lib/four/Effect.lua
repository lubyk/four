--[[--
  h1. four.Effect

  An effect defines a configuration of the graphics pipeline 
  for rendering a Geometry object.

  Given a geometry object @g@, a vertex shader input parameters
  @param@ is bound to the @g.data.param@.
--]]--

local lib = { type = 'four.Effect' }
four.Effect = lib

local Color = four.Color
local Effect = lib

function lib.__index(e, k)           -- special handling for the uniforms key
  if k == "uniforms" then return rawget(e, "_uniforms")
  else return lib[k] end
end

function lib.__newindex(e, k, v)
   if k == "uniforms" then rawset(e, "_uniforms", toUniformTable(v)) 
   else rawset(e, k, v) end
end

setmetatable(lib, { __call = function(lib, ...) return lib.new(...) end})

-- h2. Constructor

--[[-- 
  @Effect(def)@ is a new effect object. @def@ keys:
  * @version@, the GLSL version string (defaults to @"150"@).
  * @uniforms@, key/value table. The key implicitely define uniforms
    with the same names in the shader sources. The value
    is implicitely or explicitely converted, see Uniforms below.
  * @vertex@, vertex shader source.
  * @geometry@, geometry shader source (optional).
  * @fragment@, fragment shader source.
--]]--
function lib.new(def)
  local self = 
    { version = "150 core",
      vertex = lib.Shader [[void main(void) {}]],
      geometry = nil, -- optional
      fragment = lib.Shader [[void main(void) {}]],
      _uniforms = { _table = {} },
      _preamble = nil, }
  setmetatable(self, lib)
  if def then self:set(def) end
  return self
end

function lib:set(def) 
  if def.version then self.version = def.version end
  if def.vertex then self.vertex = def.vertex end
  if def.geometry then self.geometry = def.geometry end
  if def.fragment then self.fragment = def.fragment end
  if def.uniforms then self.uniforms = def.uniforms end
end

-- h2. Shader constructor

function lib.Shader(src) 
  local trace = lk.split(debug.traceback(),'\n\t')[3]
  local file, last_line = string.match(trace, '^([^:]+):([^:]+):')
  local src_line_count = #lk.split(src, '\n')
  return { file = file, line = last_line - src_line_count, src_fragment = src }
end

-- h2. Uniforms

lib.bt = 1
lib.it = 2
lib.ut = 3
lib.ft = 4

lib.model_to_world = 1
lib.world_to_camera = 2
lib.camera_to_clip = 3
lib.model_to_camera = 4
lib.model_to_clip = 5
lib.normals_model_to_camera = 6
lib.camera_resolution = 7

lib.modelToWorld = { dim = 16, typ = lib.ft, special = lib.model_to_world }
lib.worldToCamera = { dim = 16, typ = lib.ft, special = lib.world_to_camera }
lib.cameraToClip = { dim = 16, typ = lib.ft, special = lib.camera_to_clip }
lib.modelToCamera = { dim = 16, typ = lib.ft, special = lib.model_to_camera }
lib.modelToClip = { dim = 16, typ = lib.ft, special = lib.model_to_clip }
lib.normalModelToCamera = { dim = 9, typ = lib.ft, 
                             special = lib.normals_model_to_camera }
lib.cameraResolution = { dim = 2, typ = lib.ft, 
                         special = lib.camera_resolution }

function lib.U(o) -- TODO int request
  local ot = type(o)
  if ot == "boolean" then return { dim = 1, typ = lib.bt, v = { o and 1 or 0 } }
  elseif ot == "number" then return { dim = 1, typ = lib.ft, v = { o } } 
  elseif ot == "table" then 
    if o.typ then return o -- already a uniform
    else
      local dim = #o 
      if dim > 5 and dim ~= 16 then error("Unsupported uniform type") else
        return { dim = dim, typ = lib.ft, v = o}
      end
    end
  else
    error (string.format("Unsupported uniform type: %s", ot))
  end
end

function fromUniform(u) -- removes the uniform typing information 
  if u.special then return "Depends on camera and renderable transform" else
    if u.dim == 1 then 
      if u.typ == lib.bt then return u.v[1] == 1
      else return u.v[1] end
    else return u.v end
  end
end

local uniformTableMeta = 
{
  __index = function (us, k) 
    if k == "_table" then return rawget(us, k)
    else return fromUniform(us._table[k]) end
  end,
  
  __newindex = function (us, k, v)
    local t = rawget(us, "_table")
    rawset(t, k, lib.U(v))
  end
}

function toUniformTable(t)
  local us = { _table = {}}
  setmetatable(us, uniformTableMeta)
  for k, v in pairs(t) do us[k] = v end
  return us
end

function lib:getUniforms() return self._uniforms._table end

-- GLSL meta programming

local uTypeScalar = 
  {  [lib.bt] = "bool",
     [lib.it] = "int",
     [lib.it] = "uint",
     [lib.ft] = "float" }

local uTypeVec = 
  {  [lib.bt] = "bvec",
     [lib.it] = "ivec",
     [lib.it] = "uvec",
     [lib.ft] = "vec" }

local function glslVersion(v) return string.format("#version %s\n", v) end
local function glslUniform(n, u)
  local s = string.format
  if u.dim == 1 then return s("uniform %s %s;", uTypeScalar[u.typ], n)
  elseif u.dim <= 5 then return s("uniform %s%d %s;", uTypeVec[u.typ], u.dim, n)
  elseif u.dim == 9 then return s("uniform mat3 %s;", n)
  elseif u.dim == 16 then return s("uniform mat4 %s;", n)
  else assert(false) end
end

function lib:glslPreamble(pretty)
  if self._preamble then return self._preamble else
    local uniforms = ""
    local nl = pretty and "\n" or ""
    for k, v in pairs(self:getUniforms()) do
      uniforms = uniforms .. glslUniform(k, v) .. nl
    end
    if not pretty then uniforms = uniforms .. "\n" end
    return glslVersion(self.version) .. uniforms
  end
end

-- h2. Effect shaders

function lib:vertexShaderSource(pretty) 
  local v = self.vertex
  v.src = self:glslPreamble(pretty) .. v.src_fragment
  return  v
end

function lib:geometryShaderSource(pretty)
  local g = self.geometry
  if not g then return nil end
  g.src = self:glslPreamble(pretty) .. g.src_fragment
  return g
end

function lib:fragmentShaderSource(pretty)
  local f = self.fragment
  f.src = self:glslPreamble(pretty) .. f.src_fragment
  return f
end

-- h2. Predefined Effects

--[[--
  @Wireframe(def)@ renders triangle geometry as wireframe. @def@ keys:
  * @fill@, a Color defining the triangle fill color (defaults 
    to Color.white ()).
  * @wite@, a Color defining the wireframe color (default to Color.red().

  Effect adapted from http://cgg-journal.com/2008-2/06/index.html.
--]]--
function lib.Wireframe(def)
  return Effect
  {
    uniforms = 
      { 
        model_to_clip = Effect.modelToClip,
        resolution = Effect.cameraResolution,
        fill = def and def.fill or Color.white (),
        wire = def and def.wire or Color.red (),
        hidden_surface = true
      },
      
    vertex = Effect.Shader [[
      in vec4 vertex;
      void main() { gl_Position = model_to_clip * vertex; }
    ]],  

    geometry = Effect.Shader [[
      layout(triangles) in;
      layout(triangle_strip, max_vertices=3) out;
      noperspective out vec3 dist;
      void main(void)
      {
        vec2 p0 = resolution * gl_in[0].gl_Position.xy/gl_in[0].gl_Position.w;
        vec2 p1 = resolution * gl_in[1].gl_Position.xy/gl_in[1].gl_Position.w;
        vec2 p2 = resolution * gl_in[2].gl_Position.xy/gl_in[2].gl_Position.w;
  
        vec2 v0 = p2 - p1;
        vec2 v1 = p2 - p0;
        vec2 v2 = p1 - p0;
        float area = abs(v1.x * v2.y - v1.y * v2.x);

        dist = vec3(area / length(v0), 0, 0);
        gl_Position = gl_in[0].gl_Position;
        EmitVertex();
	
        dist = vec3(0, area/length(v1), 0);
        gl_Position = gl_in[1].gl_Position;
        EmitVertex();

        dist = vec3(0, 0, area/length(v2));
        gl_Position = gl_in[2].gl_Position;
        EmitVertex();

        EndPrimitive();
      }  
 ]],

  fragment = Effect.Shader [[
    noperspective in vec3 dist;
    out vec4 color;
    void main(void)
    {
      float d = min(dist[0],min(dist[1],dist[2]));
      float I = exp2(-2*d*d);
      if (!hidden_surface && I < 0.01) { discard; }
      color = mix(fill, wire, I); // I*wire + (1.0 - I)*fill;
    }
  ]]
}
end
