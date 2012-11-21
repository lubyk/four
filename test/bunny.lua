require 'lubyk'
require 'bunny_geometry'

local V2 = four.V2
local V3 = four.V3
local V4 = four.V4
local Quat = four.Quat
local Color = four.Color
local Transform = four.Transform
local Effect = four.Effect
local Camera = four.Camera 
local Manip = four.Manip

-- World 

local bunny = 
  { transform = Transform { pos = V3(0, -0.1, 0),
                            rot = Quat.rotZYX(V3(0, math.pi/6, 0))} ,
    geometry = bunny (),
    effect = gooch () }

bunny.geometry:computeVertexNormals()

local camera = Camera { transform = Transform { pos = V3(0, 0, 0.5) },
                        range = V2(0.1, 5) }

-- Interaction

function command(app, c)
  if c.ExitFullscreen then app.win:showFullScreen(false) end
  if c.ToggleFullscreen then app.win:swapFullScreen() end
  if c.Resize then camera.aspect = V2.x(app.size) / V2.y(app.size) end
  if c.StartRotation then 
    local pos = camera:screenToDevice(c.pos) 
    app.rotator = Manip.Rot(bunny.transform.rot, pos)
  end
  if c.Rotation then 
    local pos = camera:screenToDevice(c.pos)
    bunny.transform.rot = Manip.rotUpdate(app.rotator, pos)
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
  app.win:update()
end

function event(app, e) 
  local c = {} 
  if e.Resize then c.Resize = true end
  if e.KeyDown then 
    if e.key == mimas.Key_Escape then c.ExitFullscreen = true
    elseif e.key == mimas.Key_Space then c.ToggleFullscreen = true
    elseif e.key == mimas.Key_Up then c.MoveIn = true
    elseif e.key == mimas.Key_Down then c.MoveOut = true 
    end
  end
  if e.MouseDown then c.StartRotation = true c.pos = e.pos end
  if e.MouseMove then c.Rotation = true c.pos = e.pos end
  command(app, c)
end

-- Application

local app = App { event = event, camera = camera, objs = { bunny } }

function app.win:paintGL() 
  bunny.effect.uniforms.time = now() / 1000
  app.renderer:render(app.camera, app.objs)   
end

app.init()

local step = 1/60
timer = lk.Timer(step * 1000, function() app.win:update() end)
timer:start()
run ()







