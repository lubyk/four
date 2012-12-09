-- Geometry viewer

require 'lubyk'
local Demo = require 'demo'
local Manip = require 'manip'
local Gooch = require 'gooch'
local Dtri = require 'dtri'
local Utils = require 'utils'

local V2 = four.V2
local V3 = four.V3
local Quat = four.Quat
local Transform = four.Transform
local Buffer = four.Buffer
local Geometry = four.Geometry
local Effect = four.Effect
local Camera = four.Camera
local Color = four.Color

local effects = 
  { Effect.Wireframe,
    Effect.Normals, 
    Gooch.effect }  

local nextEffect = Demo.effectCycler { effects = effects } 

-- World

function cmpx(v0, v1)
  if V3.x(v0) < V3.x(v1) then return -1 
  elseif V3.x(v0) > V3.x(v1) then return 1 
  else return 0 end
end

function tris () 
  local vs = Utils.randomCuboidSamples(1000, V3(-1.5, -1, 0), V3(1.5, 1, 0))
  vs:push3D(-1.5,  1, 0)
  vs:push3D(-1.5, -1, 0)
  vs:push3D( 1.5, -1, 0)
  vs:push3D( 1.5,  1, 0)
  local is = Dtri.angulation(vs, nil, true)
  return Geometry { primitive = Geometry.TRIANGLES, 
                    data = { vertex = vs }, index = is }
end
  
geometries = { function () return tris () end }

local nextGeometry = Demo.geometryCycler { normals = true,
                                           geometries = geometries }

local obj = 
  { transform = Transform (),
    geometry = nextGeometry(),
    effect = nextEffect() }
  
local camera = Camera 
  { transform = Transform { pos = V3(0, 0, 5) },
    background = { color = Color(0, 0, 0) },
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
math.randomseed(os.time())
app.init()
run ()
