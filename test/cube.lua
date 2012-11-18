require 'lubyk'

local V2 = four.V2
local V3 = four.V3
local Color = four.Color
local Transform = four.Transform
local Effect = four.Effect

local effect = Effect
{
  uniforms = 
    { model_to_clip = Effect.modelToClip,
      model_color = Color.red () },

  vertex = Effect.Shader [[
    in vec3 vertex;
    void main() { gl_Position = model_to_clip * vec4(vertex, 1.0); }
  ]],  

  fragment = Effect.Shader [[
    out vec4 color;
    void main() { color = model_color; }
  ]]
}

local cube = 
  { transform = Transform { pos = V3(0, 0, 0) },
    geometry = four.Geometry.Cube(0.5),
    effect = effect }

local camera = four.Camera ({ transform = Transform { pos = V3(0, 0, 5) } })

-- Render

local w, h = 640, 360
local renderer = four.Renderer { size = V2(w, h) }
local win = mimas.GLWindow ()
function win:resizeGL(w, h) renderer.size = V2(w, h) end
function win:paintGL() renderer:render(camera, {cube}) end
function win:initializeGL() renderer:logInfo() end
function win:keyboard(key, down, utf8, modifiers)
  if down then
    if key == mimas.Key_Escape then self:showFullScreen(false)
    elseif key == mimas.Key_Space then self:swapFullScreen() end
  end
end

win:move(650, 50)
win:resize(w, h)
win:show()
run()



