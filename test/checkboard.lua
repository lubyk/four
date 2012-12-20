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
local Buffer = four.Buffer
local Camera = four.Camera 
local Color = four.Color
local Texture = four.Texture 

local effect = Effect 
{ 
  rasterization = { cull_face = Effect.CULL_NONE },
  default_uniforms = { model_to_clip = Effect.MODEL_TO_CLIP },
  vertex = Effect.Shader [[
     uniform mat4 model_to_clip;
     in vec3 vertex;
     in vec2 tex; 
     out vec2 v_tex;
     void main () 
     {
        v_tex = tex;
        gl_Position = model_to_clip * vec4(vertex, 1.0);
     }
  ]],

  fragment = Effect.Shader [[
    uniform sampler2D checkboard;
    in vec2 v_tex;
    out vec4 f_color;
    void main () 
    {
      f_color = texture(checkboard, v_tex);
    }
  ]],

}

-- Checkboard texture

function checkboard () 
  local img = Buffer { dim = 4, scalar_type = Buffer.UNSIGNED_BYTE } 
  for y = 0, 63 do 
    for x = 0, 63 do 
      local xm = bit.band(x, 8) == 0 and 1 or 0 
      local ym = bit.band(y, 8) == 0 and 1 or 0
      local I =  bit.bxor(xm, ym) * 255 
      img:push4D(I, I, I, 255)
    end
  end
  return Texture { type = Texture.TYPE_2D, 
                   internal_format = Texture.RGBA_8UN,
                   size = V3(64, 64, 1),
                   wrap_s = Texture.WRAP_CLAMP_TO_EDGE,
                   wrap_t = Texture.WRAP_CLAMP_TO_EDGE,
                   mag_filter = Texture.MAG_LINEAR,
                   min_filter = Texture.MIN_LINEAR_MIPMAP_LINEAR,
                   generate_mipmaps = true, 
                   data = img }
end

-- World

local geometries = { function () return Geometry.Plane(four.V2(1,1)) end }
local nextGeometry = Demo.geometryCycler { geometries = geometries }
local angle = -math.pi / 8
local obj = 
  { transform = Transform { rot = Quat.rotZYX(V3(angle, angle, 0)) },
    geometry = nextGeometry(),
    checkboard = checkboard (),
    effect = effect }

local camera = 
  Camera { transform = Transform { pos = V3(0, 0, 5) },
           background = { color = Color(0.2, 0.3, 0.55) },
           range = V2(0.1, 100) }

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
