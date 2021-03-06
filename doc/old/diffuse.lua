-- Simple diffuse shader

require 'lubyk'
local Demo = require 'demo'
local Manip = require 'manip'

local V2 = four.V2
local V3 = four.V3
local Quat = four.Quat
local Transform = four.Transform
local Geometry = four.Geometry
local Effect = four.Effect
local Camera = four.Camera 
local Color = four.Color

local effect = Effect 
{ 
  default_uniforms = 
    { model_to_cam = Effect.MODEL_TO_CAMERA,
      normal_to_cam = Effect.MODEL_NORMAL_TO_CAMERA,
      model_to_clip = Effect.MODEL_TO_CLIP,
      world_to_cam = Effect.WORLD_TO_CAMERA,
      light_pos = V3(3, 5, 5),
      light_color = V3(1, 1, 1),
      Kd = V3(0.5, 0.5, 0.5) },

  vertex = Effect.Shader [[
     uniform mat4 model_to_cam; 
     uniform mat3 normal_to_cam; 
     uniform mat4 model_to_clip;

     in vec3 vertex;
     in vec3 normal; 
     out vec4 v_position;
     out vec3 v_normal;
     void main () 
     {
        v_position = model_to_cam * vec4(vertex, 1.0);
        v_normal = normal_to_cam * normal; 
        gl_Position = model_to_clip * vec4(vertex, 1.0);
     }
  ]],

  fragment = Effect.Shader [[
    uniform mat4 world_to_cam;
    uniform vec3 light_pos;
    uniform vec3 light_color; 
    uniform vec3 Kd;

    in vec4 v_position; 
    in vec3 v_normal; 
    out vec4 f_color;
    void main () 
    {
      vec4 f_light_pos = world_to_cam * vec4(light_pos, 1.0);
      vec4 l = normalize(f_light_pos - v_position);
      float I = clamp(dot(normalize(v_normal), l.xyz), 0, 1);
      f_color = vec4(clamp(Kd * light_color * I, 0, 1), 1.0);
    }
  ]],

  rasterization = { cull_face = Effect.CULL_NONE }
}

-- World

local nextGeometry = Demo.geometryCycler { normals = true }
local angle = math.pi / 4

local obj = 
  { transform = Transform { rot = Quat.rotZYX(V3(angle, angle, 0)) },
    geometry = nextGeometry(),
    effect = effect }

local camera = 
  Camera { transform = Transform { pos = V3(0, 0, 5) },
           background = { color = Color(0.2, 0.3, 0.55) },
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
