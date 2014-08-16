-- Explosion shader along the lines 


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
  rasterization = { cull_face = Effect.CULL_NONE },
  default_uniforms = 
    { model_to_cam = Effect.MODEL_TO_CAMERA,
      cam_to_clip = Effect.CAMERA_TO_CLIP,
      light_pos = V3(0, 0, 10),
    },

  vertex = Effect.Shader [[
     uniform mat4 model_to_cam;
     in vec3 vertex;
     void main () 
     { gl_Position = model_to_cam * vec4(vertex, 1.0); }
  ]],

  geometry = Effect.Shader [[
    layout(triangles) in;
    layout(points, max_vertices=1024) out; 
    uniform mat4 cam_to_clip; 
    uniform int level; 
    uniform float gravity; 
    uniform float time; 
    uniform float v_scale; 
    uniform float floor; 

    out float g_I; 
    const vec3 light_pos = vec3(0, 0, 10);

    vec3 p0, v01, v02;
    vec3 n; 
    vec3 center; 

    void emitVertex(float s, float t) 
    {
       vec3 p = p0 + s * v01 + t * v02; 
       g_I = abs(dot(normalize(light_pos - p), n));
       vec3 vel = v_scale * (p - center);
       p += vel * time + 0.5 * vec3(0., gravity, 0.) * time * time;    
       p.y = max(floor, p.y);
       gl_Position = cam_to_clip * vec4(p, 1); 
       EmitVertex();
    }

    void main(void) 
    {
      p0 = gl_in[0].gl_Position.xyz;
      vec3 p1 = gl_in[1].gl_Position.xyz;
      vec3 p2 = gl_in[2].gl_Position.xyz;

      v01 = p1 - p0;
      v02 = p2 - p0;
      n = normalize(cross(v01, v02));
      center = (p0 + p1 + p2) / 3;
      
      int count = 1 << level; 
      float dt = 1. / float(count); 
      float t = 1.; 

      for (int i = 0; i <= count; i++) 
      {
         float smax = 1 - t; 
         int nums = i + 1; 
         float ds = smax / float(nums - 1); 
         float s = 0; 
         for (int j = 0; j < nums; j++) 
         {
           emitVertex(s, t); 
           s += ds; 
         }
         t -= dt; 
      }
    }
  ]],

  fragment = Effect.Shader [[
    in float g_I;
    out vec4 f_color;
    void main () 
    {
      f_color = vec4(g_I, g_I, g_I, 1.0);
    }
  ]],

}

-- World

local nextGeometry = Demo.geometryCycler {}
local angle = 0 -- math.pi / 4

local dt = 1 / 600
local obj = 
  { gravity = -0.1, 
    v_scale = 40.0,
    time = 0,
    level = 0,
    floor = -1,
    transform = Transform { rot = Quat.rotZYX(V3(angle, angle, 0)) },
    geometry = nextGeometry(),
    effect = effect }

local camera = 
  Camera { transform = Transform { pos = V3(0, 0, 8) },
           background = { color = Color(0.2, 0.3, 0.55) },
           range = V2(0.1, 100) }

-- Interaction

function command(app, c)
  if false then
  elseif c.ExitFullscreen then app.win:showFullScreen(false)
  elseif c.ToggleFullscreen then app.win:swapFullScreen()
  elseif c.Resize then camera.aspect = V2.x(app.size) / V2.y(app.size)
  elseif c.StartRotation then 
    local pos = camera:screenToDevice(c.pos) 
    app.rotator = Manip.Rot(obj.transform.rot, pos)
  elseif c.Rotation then 
    local pos = camera:screenToDevice(c.pos)
    obj.transform.rot = Manip.rotUpdate(app.rotator, pos)
  elseif c.MoveOut then 
    -- TODO factor that out 
    local forward = V3.unit(four.M4.col(four.Quat.toM4(camera.transform.rot),3))
    camera.transform.pos = camera.transform.pos + 0.2 * forward
  elseif c.MoveIn then 
    -- TODO factor that out 
    local forward = V3.unit(four.M4.col(four.Quat.toM4(camera.transform.rot),3))
    camera.transform.pos = camera.transform.pos - 0.2 * forward
  elseif c.CycleGeometry then obj.geometry = nextGeometry()
  elseif c.IncLevel then obj.level = math.min(obj.level + 1, 8)
  elseif c.DecLevel then obj.level = math.max(obj.level - 1, 0)
  elseif c.IncTime then obj.time = obj.time + dt
  elseif c.DecTime then obj.time = math.max(obj.time - dt, 0)
  elseif c.ResetTime then obj.time = 0
  elseif c.ToggleExplode then app.explode = not app.explode
  end
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
    elseif e.utf8 == '+' then c.IncLevel = true
    elseif e.utf8 == '-' then c.DecLevel = true
    elseif e.utf8 == 'e' then c.ToggleExplode = true
    elseif e.utf8 == 'n' then c.IncTime = true
    elseif e.utf8 == 'p' then c.DecTime = true
    elseif e.utf8 == 'r' then c.ResetTime = true
    end
  end
  if e.MouseDown then c.StartRotation = true c.pos = e.pos end
  if e.MouseMove then c.Rotation = true c.pos = e.pos end
  if next(c) ~= nil then command(app, c) end
end

-- Application

local app = Demo.App { event = event, camera = camera, objs = { obj } }
app.explode = false
app.init()

function loop () 
  if app.explode then 
    obj.time = obj.time + 1 / 60
  end
  app.win:update()
end

local step = 1/60
timer = lk.Timer(step * 1000, loop)
timer:start()

run ()
