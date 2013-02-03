require 'lubyk'
local Demo = require 'demo'
local Manip = require 'manip'

local V2 = four.V2
local V3 = four.V3
local V4 = four.V4
local Quat = four.Quat
local Transform = four.Transform
local Buffer = four.Buffer
local Geometry = four.Geometry
local Effect = four.Effect
local Camera = four.Camera 
local Color = four.Color

local Gooch = require 'gooch'
local Models = require 'Models'

-- Effects and shaders

local gooch = Gooch.effect()
local wireframe = Effect.Wireframe { adjacency = true }  
local contour_world_tris = Effect 
{
  rasterization = { cull_face = Effect.CULL_BACK },
  default_uniforms = 
    { model_to_cam = Effect.MODEL_TO_CAMERA,
      normal_to_cam = Effect.MODEL_NORMAL_TO_CAMERA,
      model_to_clip = Effect.MODEL_TO_CLIP,
      world_to_cam = Effect.WORLD_TO_CAMERA,
      cam_to_clip = Effect.CAMERA_TO_CLIP,
      contour_width = 0.015, 
      contour_color = Color.black() },

  vertex = Effect.Shader [[
     uniform mat4 model_to_clip; 
     uniform mat4 model_to_cam; 
     uniform mat3 normal_to_cam; 
     in vec3 vertex;
     in vec3 normal; 
     out vec3 v_normal;
     out vec3 v_vertex;
     void main () 
     { 
       v_normal = normalize(normal_to_cam * normal);
       v_vertex = vec3(model_to_cam * vec4(vertex, 1.0));
       gl_Position = model_to_clip * vec4(vertex, 1.0); 
     }
  ]],

  geometry = Effect.Shader [[
    layout(triangles_adjacency) in; 
    layout(triangle_strip, max_vertices = 18) out;
    uniform float contour_width;
    uniform mat4 cam_to_clip; 
    in vec3 v_normal[6];
    in vec3 v_vertex[6];
    out float g_dist;

    bool front_facing(vec3 cp0, vec3 cp1, vec3 cp2) 
    { 
       return cross(cp1 - cp0, cp2 - cp0).z > 0; // clip space test 
    } 

    void emit_vertex(vec3 v, float d) 
    { 
      g_dist = d; 
      gl_Position = cam_to_clip * vec4(v, 1); 
      EmitVertex();
    } 

    void emit_contour(vec3 p0, vec3 n0, vec3 p1, vec3 n1) 
    { 
      // Extrudes a trapezoid along the edge normals (triangle strip CCW).
      //          p0  p1
      //          x-----x
      //        /____--- \
      //       x----------x p1 + n1 * contour_width
      //       p0 + n0 * contour_width 

      emit_vertex(p0, 0);
      emit_vertex(p0 + n0 * contour_width, 1);
      emit_vertex(p1, 0); 
      emit_vertex(p1 + n1 * contour_width, 1);
      EndPrimitive();
    } 

    void main () 
    { 
      // 5 --- 4 --- 3
      //   \ / * \ /
      //    0 --- 2
      //     \   /
      //       1
      vec3 cp0 = gl_in[0].gl_Position.xyz / gl_in[0].gl_Position.w;
      vec3 cp1 = gl_in[1].gl_Position.xyz / gl_in[1].gl_Position.w;
      vec3 cp2 = gl_in[2].gl_Position.xyz / gl_in[2].gl_Position.w;
      vec3 cp3 = gl_in[3].gl_Position.xyz / gl_in[3].gl_Position.w;
      vec3 cp4 = gl_in[4].gl_Position.xyz / gl_in[4].gl_Position.w;
      vec3 cp5 = gl_in[5].gl_Position.xyz / gl_in[5].gl_Position.w;

      if (front_facing(cp0, cp2, cp4))
      { 
        if (!front_facing(cp0, cp1, cp2))
          emit_contour(v_vertex[0], v_normal[0], v_vertex[2], v_normal[2]);

        if (!front_facing(cp2, cp3, cp4))
          emit_contour(v_vertex[2], v_normal[2], v_vertex[4], v_normal[4]);

        if (!front_facing(cp4, cp5, cp0)) 
          emit_contour(v_vertex[4], v_normal[4], v_vertex[0], v_normal[0]);
      }
   }
  ]],

  fragment = Effect.Shader [[
    uniform vec4 contour_color; 
    in float g_dist; 
    out vec4 f_color;
    void main () {       
      f_color = vec4(contour_color.rgb, 1 - smoothstep(0.85, 1.0, g_dist)); 
    }
  ]],

}

local effects = 
  { function () return contour_world_tris end,
    function () return { gooch, contour_world_tris } end, 
    function () return { wireframe, contour_world_tris } end }

local nextEffect = Demo.effectCycler { effects = effects } 

-- Geometry

local geometries = 
  { function () return Geometry.Cube(1, true) end,
    function () return Geometry.Sphere(0.5, 4) end,
    function () return Models.bunny(1) end }
  
local nextGeometry =  Demo.geometryCycler { geometries = geometries, 
                                            normals = true, adjacency = true }

-- World

local angle = math.pi / 4

local obj = 
  { transform = Transform { rot = Quat.rotZYX(V3(angle, angle, 0)) },
    geometry = nextGeometry(),
    effect = nextEffect(), 
    contour_width = 0.015 }

local camera = 
  Camera { transform = Transform { pos = V3(0, 0, 5) },
           background = { color = Color.white() },
           range = V2(0.1, 10) }

-- Interaction

function command(app, c)
  if c.ExitFullscreen then app.win:showFullScreen(false) end
  if c.ToggleFullscreen then app.win:swapFullScreen() end
  if c.Resize then camera.aspect = V2.x(app.size) / V2.y(app.size) end
  if c.StartRotation then 
    local pos = camera:screenToDevice(c.pos) 
    app.rotator = Manip.Rot(obj.transform.rot, pos)
  end
  if c.Rotation then 
    local pos = camera:screenToDevice(c.pos)
    obj.transform.rot = Manip.rotUpdate(app.rotator, pos)
  end
  if c.MoveOut then 
    -- TODO factor that out 
    local forward = V3.unit(four.M4.col(four.Quat.toM4(camera.transform.rot),3))
    camera.transform.pos = camera.transform.pos + 0.2 * forward
  end
  if c.MoveIn then 
    -- TODO factor that out 
    local forward = V3.unit(four.M4.col(four.Quat.toM4(camera.transform.rot),3))
    camera.transform.pos = camera.transform.pos - 0.2 * forward
  end
  if c.CycleGeometry then obj.geometry = nextGeometry() end
  if c.CycleEffect then obj.effect = nextEffect() end
  if c.IncreaseContour then obj.contour_width = obj.contour_width + 0.005 end
  if c.DecreaseContour then obj.contour_width = obj.contour_width - 0.005 end
  app.win:update()
end

function event(app, e) 
  local c = {} 
  if e.Resize then c.Resize = true end
  if e.KeyDown then 
    if e.key == mimas.Key_Escape then c.ExitFullscreen = true
    elseif e.key == mimas.Key_Space then c.ToggleFullscreen = true
    elseif e.key == mimas.Key_Down then c.MoveOut = true 
    elseif e.key == mimas.Key_Up then c.MoveIn = true
    elseif e.key == mimas.Key_Left then c.MoveLeft = true
    elseif e.key == mimas.Key_Right then c.MoveRight = true    
    elseif e.utf8 == 'g' then c.CycleGeometry = true
    elseif e.utf8 == 'e' then c.CycleEffect = true
    elseif e.utf8 == '+' then c.IncreaseContour = true
    elseif e.utf8 == '-' then c.DecreaseContour = true
    end
  end
  if e.MouseDown then c.StartRotation = true c.pos = e.pos end
  if e.MouseMove then c.Rotation = true c.pos = e.pos end
  if next(c) ~= nil then command(app, c) end
end

-- Application

local app = Demo.App { event = event, camera = camera, objs = { obj } }
app.init()
run ()
