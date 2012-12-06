-- Geometry viewer

require 'lubyk'
local Demo = require 'demo'
local Gooch = require 'gooch'
local Manip = require 'manip'

local V2 = four.V2
local V3 = four.V3
local Quat = four.Quat
local Transform = four.Transform
local Geometry = four.Geometry
local Effect = four.Effect
local Camera = four.Camera 
local Color = four.Color

function WireHiQ() 
  local back = Effect.Wireframe 
    { wire_color = Color(0.8, 0.8, 0.8, 1.0),
      fill_color = Color(1, 1, 1, 1),
      wire_width = 2.0,
      rasterization = { cull_face = Effect.CULL_FRONT } }

  local front = Effect.Wireframe 
    { wire_color = Color(0, 0, 0, 1.0),
      wire_only = true, 
      wire_width = 6.0,
      rasterization = { cull_face = Effect.CULL_BACK },
      depth = { func = Effect.DEPTH_FUNC_LEQUAL }}

  return { back, front }
end

function WireHiQAndNormals()
  local normals = Effect.Normals()
  return { WireHiQ(), normals }
end

local effects = 
  { WireHiQ,
    WireHiQAndNormals,
    Effect.Normals,
    Effect.Wireframe,
    Gooch.effect }  

local nextEffect = Demo.effectCycler { effects = effects } 

-- World

local nextGeometry = Demo.geometryCycler { normals = true }
local angle = math.pi / 4

local obj = 
  { transform = Transform { rot = Quat.rotZYX(V3(angle, angle, 0)) },
    geometry = nextGeometry(),
    effect = nextEffect() }
  
local camera = Camera 
  { transform = Transform { pos = V3(0, 0, 5) },
    background = { color = Color(0.2, 0.3, 0.55) },
    range = V2(0.1, 10) }

-- Interaction

function command(app, c)
  if c.ExitFullscreen then app.win:showFullScreen(false)
  elseif c.ToggleFullscreen then app.win:swapFullScreen()
  elseif c.Resize then camera.aspect = V2.x(app.size) / V2.y(app.size)
  elseif c.CycleGeometry then obj.geometry = nextGeometry()
  elseif c.CycleEffect then obj.effect = nextEffect() 
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
    elseif e.utf8 == 'e' then c.CycleEffect = true
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
