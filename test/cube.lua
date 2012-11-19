require 'lubyk'

local V2 = four.V2
local V3 = four.V3
local V4 = four.V4
local Quat = four.Quat
local Color = four.Color
local Transform = four.Transform
local Effect = four.Effect
local Camera = four.Camera 

local cube = 
  { transform = Transform { rot = Quat.rotZYX(V3(math.pi/4, math.pi/4, 0)) },
    geometry = four.Geometry.Cube(1),
    effect = Effect.Wireframe () }

local camera = Camera { transform = Transform { pos = V3(0, 0, 5) } }

-- TODO factor out and debug manipulators.

function manip_sphere_point(radius, center, v)
  local p = (1 / radius) * (v - center) 
  local d = V2.norm2(v)
  if d > 1 then 
    local a = 1 / math.sqrt(d)
    return V3.ofV2(a * p, 0.0)
  else
    return V3.ofV2(p, math.sqrt(1.0 - d))
  end
end

function manip_orient(tr, start)
  local center = V2(0,0)
  local radius = 1.0
  return { center = center,
           radius = radius,
           start = manip_sphere_point(radius, center, start),
           relative = tr.rot,
           transform = tr }
end

function manip_orient_update (relat, m, v) 
  local p = manip_sphere_point(m.radius, m.center, v) 
  local q = V4.ofV3(V3.cross(m.start, p), V3.dot(m.start, p))
  if relat then m.transform.rot = Quat.mul(m.relative, Quat.ofV4(q)) 
  else m.transform.rot = Quat.ofV4(q) end
end

local cube_orient = nil

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
    local pos = V2.div (V2(x, y), renderer.size)
    pos[2] = 1 - pos[2]
    cube_orient = manip_orient(cube.transform, pos)
    win:update()
  end
end

function win:mouse(x, y)
  local pos = V2.div (V2(x, y), renderer.size)
  pos[2] = 1 - pos[2]
  manip_orient_update(true, cube_orient, pos)
  win:update()
end

win:move(650, 50)
win:resize(w, h)
win:show()
run()



