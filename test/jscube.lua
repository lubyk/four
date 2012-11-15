require 'lubyk'

local V2 = four.V2
local V3 = four.V3
local Color = four.Color
local Spatial = four.Spatial

local renderable = 
  { spatial = Spatial(),
    geometry = four.Geometry.Cuboid(V3(1, 1, 1)), 
    effect = four.Effect.FlatShading(Color.red) }

local camera = four.Camera ({ spatial = Spatial { pos = V3(0, 0, -5) } })
local space = four.Space() -- Aggregates spatial objects (renderable or not)
space:add(renderable)

-- Render

local win = mimas.GLWindow ()
local wsize = V2(600, 400)
local renderer = four.Renderer ({ size = wsize })
function win:resizeGL(w, h) renderer.size = V2(w, h) end
function win:paintGL() renderer:render(space, camera) end
function win:initializeGL()
  local info = renderer:info()
end  

function main ()
  local w, h = V2.tuple(wsize) 
  win:move (800,50)
  win:resize (w, h)
  win:show ()
  run ()
end

main()



