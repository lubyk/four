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
   if k == "uniforms" then rawset(e, "_uniforms", lib.Uniforms(v)) 
   else rawset(e, k, v) end
end

setmetatable(lib, { __call = function(lib, ...) return lib.new(...) end})

-- h2. Render states

--[[--
h3. Face culling
In four, the convention is that faces with a counter clock-wise orientation
are front faces.
--]]--

lib.CULL_NONE = 1
lib.CULL_FRONT = 2
lib.CULL_BACK = 3

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
  * @cull_face@, face culling (defaults to @CULL_BACK@).
  * @polygon_offset@, scale and unit used to calculate depth values
    (defaults to @{ factor = 0, units = 0 }@).
--]]--
function lib.new(def)
  local self = 
    { version = "150 core",
      vertex_in = {},
      vertex_out = {},
      vertex = lib.Shader [[void main(void) {}]],
      geometry = nil, -- optional
      fragment = lib.Shader [[void main(void) {}]],
      cull_face = lib.CULL_BACK,
      polygon_offset = { factor = 0, units = 0 },
      _uniforms = { _table = {} }}
  setmetatable(self, lib)
  if def then self:set(def) end
  return self
end

function lib:set(def) 
  if def.version then self.version = def.version end
  if def.vertex_in then self.vertex_in = def.vertex_in end
  if def.vertex_out then self.vertex_out = def.vertex_out end
  if def.vertex then self.vertex = def.vertex end
  if def.geometry_out then self.geometry_out = def.geometry_out end
  if def.geometry then self.geometry = def.geometry end
  if def.fragment_out then self.fragment_out = def.fragment_out end
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

-- h2. GLSL type specifications

lib.bool_scalar = 1
lib.int_scalar = 2
lib.uint_scalar = 3
lib.float_scalar = 4

lib.bool = { dim = 1, scalar_type = lib.bool_scalar }
lib.bvec2 = { dim = 2, scalar_type = lib.bool_scalar }
lib.bvec3 = { dim = 3, scalar_type = lib.bool_scalar }
lib.bvec4 = { dim = 4, scalar_type = lib.bool_scalar }

lib.int = { dim = 1, scalar_type = lib.uint_scalar }
lib.ivec2 = { dim = 2, scalar_type = lib.uint_scalar }
lib.ivec3 = { dim = 3, scalar_type = lib.uint_scalar }
lib.ivec4 = { dim = 4, scalar_type = lib.uint_scalar }

lib.uint = { dim = 1, scalar_type = lib.uint_scalar }
lib.uvec2 = { dim = 2, scalar_type = lib.uint_scalar }
lib.uvec3 = { dim = 3, scalar_type = lib.uint_scalar }
lib.uvec4 = { dim = 4, scalar_type = lib.uint_scalar }

lib.float = { dim = 1, scalar_type = lib.float_scalar}
lib.vec2 = { dim = 2, scalar_type = lib.float_scalar }
lib.vec3 = { dim = 3, scalar_type = lib.float_scalar }
lib.vec4 = { dim = 4, scalar_type = lib.float_scalar }

lib.mat3 = { dim = 3, scalar_type = lib.float_scalar }
lib.mat4 = { dim = 4, scalar_type = lib.float_scalar }

-- h2. Uniforms

lib.model_to_world = 1
lib.world_to_camera = 2
lib.camera_to_clip = 3
lib.model_to_camera = 4
lib.model_to_clip = 5
lib.normals_model_to_camera = 6
lib.camera_resolution = 7

lib.modelToWorld = { dim = 16, scalar_type = lib.float_scalar, special = lib.model_to_world }
lib.worldToCamera = { dim = 16, scalar_type = lib.float_scalar, special = lib.world_to_camera }
lib.cameraToClip = { dim = 16, scalar_type = lib.float_scalar, special = lib.camera_to_clip }
lib.modelToCamera = { dim = 16, scalar_type = lib.float_scalar, special = lib.model_to_camera }
lib.modelToClip = { dim = 16, scalar_type = lib.float_scalar, special = lib.model_to_clip }
lib.normalModelToCamera = { dim = 9, scalar_type = lib.float_scalar, 
                             special = lib.normals_model_to_camera }
lib.cameraResolution = { dim = 2, scalar_type = lib.float_scalar, 
                         special = lib.camera_resolution }

function lib.U(o) -- TODO int request
  local ot = type(o)
  if ot == "boolean" then return { dim = 1, scalar_type = lib.bool_scalar, v = { o and 1 or 0 } }
  elseif ot == "number" then return { dim = 1, scalar_type = lib.float_scalar, v = { o } } 
  elseif ot == "table" then 
    if o.scalar_type then return o -- already a uniform
    else
      local dim = #o 
      if dim > 5 and dim ~= 16 then error("Unsupported uniform type") else
        return { dim = dim, scalar_type = lib.float_scalar, v = o}
      end
    end
  else
    error (string.format("Unsupported uniform type: %s", ot))
  end
end

function fromUniform(u) -- removes the uniform typing information 
  if u.special then return "Depends on camera and renderable transform" else
    if u.dim == 1 then 
      if u.scalar_type == lib.bool_scalar then return u.v[1] == 1
      else return u.v[1] end
    else return u.v end
  end
end

local uniformsMeta = 
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

function lib.Uniforms(t)
  local us = { _table = {}}
  setmetatable(us, uniformsMeta)
  for k, v in pairs(t) do us[k] = v end
  return us
end

function lib.rawUniforms(t) return t._table end
function lib:getUniforms() return lib.rawUniforms(self._uniforms) end

-- GLSL meta programming

local uTypeScalar = 
  { [lib.bool_scalar] = "bool",
    [lib.int_scalar] = "int",
    [lib.uint_scalar] = "uint",
    [lib.float_scalar] = "float" }

local uTypeVec = 
  { [lib.bool_scalar] = "bvec",
    [lib.int_scalar] = "ivec",
    [lib.uint_scalar] = "uvec",
    [lib.float_scalar] = "vec" }

local function glslType(t)
  local s = string.format
  if t.dim == 1 then return uTypeScalar[t.scalar_type]
  elseif t.dim <= 5 then return s("%s%d", uTypeVec[t.scalar_type], t.dim) 
  elseif t.dim == 9 then return "mat3" 
  elseif t.dim == 16 then return "mat4"
  else assert(false)
  end
end

local function glslVersion(v) return string.format("#version %s\n", v) end
local function glslUniform(n, u) 
  return string.format("uniform %s %s;", glslType(u), n) 
end

local function glslIn(n, type) 
  return string.format("in %s %s;", glslType(type), n)
end

local function glslOut(n, type) 
  return string.format("out %s %s;", glslType(type), n)
end

function lib:glslPreamble(pretty, inputs, outputs)
  local decls = ""
  local nl = pretty and "\n" or ""
  for k, v in pairs(self:getUniforms()) do
    decls = decls .. glslUniform(k, v) .. nl
  end
  for k, type in pairs(inputs) do
    decls = decls .. glslIn(k, type) .. nl
  end
  for k, type in pairs(outputs) do
    decls = decls .. glslOut(k, type) .. nl
  end
  if not pretty then decls = decls .. "\n" end
  return glslVersion(self.version) .. decls
end


-- h2. Effect shaders

function lib:vertexShaderSource(pretty) 
  local v = self.vertex
  local pre = self:glslPreamble(pretty, self.vertex_in, self.vertex_out)
  v.src =  pre .. v.src_fragment
  return  v
end

function lib:geometryShaderSource(pretty)
  local g = self.geometry
  if not g then return nil end
  local pre = self:glslPreamble(pretty, self.vertex_out, self.geometry_out)
  g.src =  pre .. g.src_fragment
  return g
end

function lib:fragmentShaderSource(pretty)
  local f = self.fragment
  local inputs = (self.geometry and self.geometry_out) or self.vertex_out
  local pre = self:glslPreamble(pretty, inputs, self.fragment_out)
  f.src =  pre .. f.src_fragment
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


--[[--
  @Normals(def)@ renders the normals of geometry.
  * @normal_scale@, a scale factor to apply to the normals.
  * @normal_color_start@, color at the starting point of the vector.
  * @normal_color_end@, color at the end of vector. 
--]]--
function lib.Normals(def)
return Effect
{
  uniforms = 
    { model_to_cam = Effect.modelToCamera,
      normal_to_cam = Effect.normalModelToCamera,
      cam_to_clip = Effect.cameraToClip,
      normal_scale = def and def.normal_scale or 0.1,
      normal_color_start = def and def.normal_color_start or Color.black(),
      normal_color_end = def and def.normal_color_end or Color.white() },
    
  vertex = Effect.Shader [[
      in vec3 vertex;
      in vec3 normal;
      out vec4 v_position;
      out vec3 v_snormal;

      void main() 
      { 
         v_position = model_to_cam * vec4(vertex, 1.0);
         v_snormal = normal_scale * normalize(normal_to_cam * normal);
      }
    ]],  
  
  geometry = Effect.Shader [[
    layout(triangles) in;
    layout(line_strip, max_vertices = 6) out;

    in vec4 v_position[3];
    in vec3 v_snormal[3];
    out vec4 g_color;

    void main()
    {
       for (int i = 0; i < 3; i++)
       {
         gl_Position = cam_to_clip * v_position[i];
         g_color = normal_color_start;
         EmitVertex();

         gl_Position = cam_to_clip * (v_position[i] + vec4(v_snormal[i], 0.0));
         g_color = normal_color_end;
         EmitVertex();

         EndPrimitive();
       }
    }
  ]],
  
  fragment = Effect.Shader [[
    in vec4 g_color;
    out vec4 f_color;
    void main(void) { f_color = g_color; }
  ]]
}
end

