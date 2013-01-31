-- Vertex blending

require 'lubyk'
local Demo = require 'demo'
local Manip = require 'manip'

local V2 = four.V2
local V3 = four.V3
local Quat = four.Quat
local Buffer = four.Buffer
local Transform = four.Transform
local Geometry = four.Geometry
local Effect = four.Effect
local Camera = four.Camera 
local Color = four.Color

local vblend = Effect.Shader [[
    uniform mat4 world_to_clip;
    uniform mat4 model_to_clip;
    uniform mat4 m[2];
    in vec3 vertex; 
    in vec3 normal; 
    in vec3 tex; 
    out vec4 v_vertex;
    void main() { 
      float b1 = tex.y; 
      float b2 = 1 - tex.y;
      vec4 p = vec4(vertex, 1.0);
      gl_Position = model_to_clip * (b1 * m[0] * p + b2 * m[1] *p); 
    }
   ]]
 
-- World

local height = 1.5
local geometries = 
  { function () return Geometry.Plane(V2(0.5, height), V2(1,15)) end }

local nextGeometry = Demo.geometryCycler { geometries = geometries, 
                                           normals = true }
local angle = math.pi / 4

local transform = Transform { 
  rot = Quat.rotZYX(V3(-angle, -angle, 0)) 
--  rot = Quat.rotZYX(V3(0, -math.pi / 2, 0)) 
}

local bend = { dir = 1,
               angle = 10 * (math.pi / 180),
               limit = 75 * (math.pi / 180),
               incr = 1.3 * (math.pi / 180) }

local function bender(angle)
  local tr = V3(0, 0.25 * height * (math.cos(2 * angle) - 1), 
                   0.25 * height * math.sin(2 * angle))
  local axis = V3(1, 0, 0)
  return four.M4.rigid(tr, axis, angle)
end

local obj = 
  { transform = transform,
    m = {bender(bend.angle), Transform {}},
    geometry = nextGeometry(),
    effect = Effect.Wireframe { vertex = vblend } }

local function updateBendAngle(incr)
  local incr = incr or bend.incr
  bend.angle = bend.angle + bend.dir * incr
  if math.abs(bend.angle) > bend.limit then 
    bend.dir = -1 * bend.dir
  end
  obj.m[1] = bender(bend.angle)
end

local obj_noblend = 
  { transform = transform,
    m = { Transform {}, Transform {} },
    geometry = obj.geometry;
    effect = Effect.Wireframe { vertex = vblend } }
  
local camera = 
  Camera { transform = Transform { pos = V3(0, 0, 5) },
           background = { color = Color(0.2, 0.3, 0.55) },
           range = V2(0.1, 10) }

local world = { obj, obj_noblend }

-- Interaction

function command(app, c)
  if false then
  elseif c.BendInc then 
    bend.dir = 1
    updateBendAngle()
  elseif c.BendDec then 
    bend.dir = -1
    updateBendAngle()
  elseif c.ToggleSimulation then app.simulate = not app.simulate
  elseif c.UpdateSimulation then updateBendAngle()
  elseif c.ExitFullscreen then app.win:showFullScreen(false)
  elseif c.ToggleFullscreen then app.win:swapFullScreen()
  elseif c.Resize then camera.aspect = V2.x(app.size) / V2.y(app.size)
  elseif c.StartRotation then 
    local pos = camera:screenToDevice(c.pos) 
    app.rotator = Manip.Rot(transform.rot, pos)
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
  elseif c.CycleGeometry then obj.geometry = nextGeometry() end
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
    elseif e.key == mimas.Key_Left then c.BendInc = true
    elseif e.key == mimas.Key_Right then c.BendDec = true    
    elseif e.utf8 == 'n' then c.UpdateSimulation = true
    elseif e.utf8 == 's' then c.ToggleSimulation = true
    elseif e.utf8 == 'r' then c.PrintRenderStats = true
    end
  end
  if e.MouseDown then c.StartRotation = true c.pos = e.pos end
  if e.MouseMove then c.Rotation = true c.pos = e.pos end
  if next(c) ~= nil then command(app, c) end
end

-- Application

local app = Demo.App { event = event, camera = camera, objs = world }
app.simulate = true
app.init()

function loop () 
  if app.simulate then updateBendAngle() end
  app.win:update()
end

local step = 1/60
timer = lk.Timer(step * 1000, loop)
timer:start()

run ()
