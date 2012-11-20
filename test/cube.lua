require 'lubyk'

local V2 = four.V2
local V3 = four.V3
local V4 = four.V4
local Quat = four.Quat
local Color = four.Color
local Transform = four.Transform
local Effect = four.Effect
local Camera = four.Camera 
local Manip = four.Manip

local cube = 
  { transform = Transform { rot = Quat.rotZYX(V3(math.pi/4, math.pi/4, 0)) },
    geometry = four.Geometry.Cube(1),
    effect = Effect.Wireframe () }

local camera = Camera { transform = Transform { pos = V3(0, 0, 5) } }

local rotator = nil

-- Render
 
local w, h = 640, 360
local renderer = four.Renderer { size = V2(w, h) }
local win = mimas.GLWindow ()
function win:resizeGL(w, h) 
  renderer.size = V2(w, h) 
  camera.aspect = w / h
end
function win:paintGL() renderer:render(camera, {cube}) end
function win:initializeGL() renderer:logInfo() end
function win:keyboard(key, down, utf8, modifiers)
  if down then
    if key == mimas.Key_Escape then self:showFullScreen(false)
    elseif key == mimas.Key_Space then self:swapFullScreen() end
  end
end

function win:click(x, y, op)
  if op == mimas.MousePress then 
    -- TODO factor out conversion to ndc.
    local pos = V2.div (V2(x, y), renderer.size)
    pos[2] = 1 - pos[2]
    pos = 2 * pos - V2(1.0, 1.0)
    -- END todo

    rotator = Manip.Rot(pos, cube.transform.rot)
  end
end

function win:mouse(x, y)
  -- TODO factor out conversion to ndc.
  local pos = V2.div (V2(x, y), renderer.size)
  pos[2] = 1 - pos[2]
  pos = 2 * pos - V2(1.0, 1.0)
  -- END todo 

  cube.transform.rot = Manip.rotUpdate(rotator, pos)
  win:update()
end

win:move(650, 50)
win:resize(w, h)
win:show()
run()



