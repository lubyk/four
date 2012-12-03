--[[--
  h1. four.Effect

  An effect defines either a configuration of the graphics pipeline 
  or a list of Effects for rendering a Geometry object.
--]]--

local lib = { type = 'four.Effect' }
lib.__index = lib
four.Effect = lib
setmetatable(lib, { __call = function(lib, ...) return lib.new(...) end})

local Color = four.Color
local Effect = lib

-- h2. Render states

--[[--
h3. Rasterization state

*Note*. Faces with a counter clock-wise orientation are front faces.

Rasterization state is described by a table with the following keys:
  * @face_cull@, faces to cull (defaults to @CULL_NONE@).
--]]--

function lib.defaultRasterization () 
  return { cull_face = lib.CULL_NONE }
end

lib.CULL_NONE = 1
lib.CULL_FRONT = 2
lib.CULL_BACK = 3

--[[--
h3. Depth state

*Note.* Depth clearing and depth range are specified by the Camera object.

Depth state is described by a table with the following keys:
  * @enable@, @true@ if z-test should be performed (defaults to @true@)
  * @func@, comparison function (defaults to @DEPTH_FUNC_LESS@)
  * @offset@, depth offset (defaults to @{ factor = 0, units = 0 }@), 
    see doc of glPolygonOffset.
--]]--

function lib.defaultDepth() 
  return { enable = true, func = lib.DEPTH_FUNC_LESS,
           offset = { factor = 0, units = 0 } }
end

lib.DEPTH_FUNC_NEVER = 1
lib.DEPTH_FUNC_LESS = 2
lib.DEPTH_FUNC_EQUAL = 3
lib.DEPTH_FUNC_LEQUAL = 4
lib.DEPTH_FUNC_GREATER = 5
lib.DEPTH_FUNC_NOTEQUAL = 6
lib.DEPTH_FUNC_GEQUAL = 7
lib.DEPTH_FUNC_ALWAYS = 8

-- h2. Constructor

--[[-- 
  @Effect(def)@ is a new effect object. @def@ keys:
  * @version@, the GLSL version string (defaults to @"150"@).
  * @default_uniforms@, key/value table, defining default values for uniforms.
  * @uniform@, uniform lookup function invoked before rendering a renderable.
    defaults to @function(cam, renderable, name) = return renderable[name]@. 
    If the function returns @nil@, @default_uniforms@ is used.
  * @vertex@, vertex shader source.
  * @geometry@, geometry shader source (optional).
  * @fragment@, fragment shader source.
  * @depth@, depth state keys to override the defaults (see Depth state).
  * @rasterization@, rasterization state keys to override the defaults 
    (see Rasterization state).
--]]--
function lib.new(def)
  local self = 
    { default_uniforms = {},
      uniform = function(cam, renderable, name) return renderable[name] end,
      vertex = lib.Shader [[void main() {}]],
      geometry = nil, -- optional
      fragment = lib.Shader [[void main() {}]],
      rasterization = lib.defaultRasterization(),
      depth = lib.defaultDepth() }
  setmetatable(self, lib)
  if def then self:set(def) end
  return self
end

function lib:set(def) 
  if def.default_uniforms then self.default_uniforms = def.default_uniforms end
  if def.uniform then self.uniform = def.uniform end
  if def.vertex then self.vertex = def.vertex end
  if def.geometry then self.geometry = def.geometry end
  if def.fragment then self.fragment = def.fragment end
  if def.rasterization then 
    if def.rasterization.cull_face then 
      self.rasterization.cull_face = def.rasterization.cull_face 
    end
  end
  if def.depth then 
    if def.depth.enable then self.depth.enable = def.depth.enable end
    if def.depth.func then self.depth.func = def.depth.func end
    if def.depth.offset then self.depth.offset = def.depth.offset end
  end
end


-- h2. Shader constructor

function lib.Shader(src) 
  local trace = lk.split(debug.traceback(),'\n\t')[3]
  local file, last_line = string.match(trace, '^([^:]+):([^:]+):')
  local src_line_count = #lk.split(src, '\n')
  
  return { file = file, line = last_line - src_line_count, fragment = src }
end


-- h2. Special Uniforms

lib.MODEL_TO_WORLD = { special_uniform = true } 
lib.MODEL_TO_CAMERA = { special_uniform = true } 
lib.MODEL_TO_CLIP = { special_uniform = true } 
lib.MODEL_NORMAL_TO_CAMERA = { special_uniform = true } 
lib.WORLD_TO_CAMERA = { special_uniform = true } 
lib.CAMERA_TO_CLIP = { special_uniform = true } 
lib.CAMERA_RESOLUTION = { special_uniform = true } 
lib.RENDER_FRAME_START_TIME = { special_uniform = true }

-- h2. Effect shaders

local function makeSource(preamble, src)
  local frags = src.fragment and { src } or src
  local src = { preamble }
  local files = {}
  for i, f in ipairs(frags) do 
    src[i + 1] = string.format("#line %d %d\n%s", f.line, i, f.fragment)
    files[i] = f.file
  end
  return { src = table.concat(src,"\n"), files = files }
end

function lib:vertexShaderSource(pre) return makeSource(pre, self.vertex) end
function lib:fragmentShaderSource(pre) return makeSource(pre, self.fragment) end
function lib:geometryShaderSource(pre) 
  return self.geometry and makeSource(pre, self.geometry) or nil
end


-- h2. Predefined Effects

--[[--
  @Wireframe(def)@ renders triangle geometry as wireframe. @def@ keys:
  * @fill_color@, a Color defining the triangle fill color (defaults 
    to Color.white ()).
  * @wire_color@, a Color defining the wireframe color (default to Color.red().
  * @wire_only@, draw only the wire frame.
  * All other @Effect@ @def@ key apply.

  Effect adapted from http://cgg-journal.com/2008-2/06/index.html.
--]]--
function lib.Wireframe(def)
  
  return Effect
  {
    rasterization = def and def.rasterization or {},
    depth = def and def.depth or {},
    
    default_uniforms = 
      { model_to_clip = Effect.MODEL_TO_CLIP,
        resolution = Effect.CAMERA_RESOLUTION,
        fill_color = def and def.fill_color or Color.white(),
        wire_color = def and def.wire_color or Color.black(),
        wire_width = def and def.wire_width or 1.0,
        wire_only = def and def.wire_only or false },
      
    vertex = Effect.Shader [[
      uniform mat4 model_to_clip;
      in vec4 vertex;
      out vec4 v_vertex;
      void main() { gl_Position = model_to_clip * vertex; }
    ]],  

    geometry = Effect.Shader [[
      uniform vec2 resolution;
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
      uniform bool wire_only;
      uniform float wire_width;
      uniform vec4 wire_color;
      uniform vec4 fill_color; 

      noperspective in vec3 dist;
      out vec4 color;

      void main(void)
      {
        float d = min(dist[0],min(dist[1],dist[2]));
        float I = exp2(-(2 / wire_width) * d * d);
        if (wire_only)
        {
          color = I * wire_color;
        } else {
          color = vec4(I * wire_color.rgb + (1.0 - I) * fill_color.rgb, 
                       fill_color.a);
        }
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
  rasterization = def and def.rasterization or {},
  depth = def and def.depth or {},

  default_uniforms = 
    { model_to_cam = Effect.MODEL_TO_CAMERA,
      normal_to_cam = Effect.MODEL_NORMAL_TO_CAMERA,
      cam_to_clip = Effect.CAMERA_TO_CLIP,
      normal_scale = def and def.normal_scale or 0.1,
      normal_color_start = def and def.normal_color_start or Color.black(),
      normal_color_end = def and def.normal_color_end or Color.white() },
    
  vertex = Effect.Shader [[
    uniform mat4 model_to_cam; 
    uniform mat3 normal_to_cam; 
    uniform float normal_scale;
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
    uniform mat4 cam_to_clip;
    uniform vec4 normal_color_start; 
    uniform vec4 normal_color_end; 
   
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

