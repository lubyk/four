-- Draws a tri-colored triangle.

require 'lubyk'
local V2 = four.V2
local Effect = four.Effect 

function triangle () -- A triangle inside clip space
  local vs = four.Buffer { dim = 3, scalar_type = four.Buffer.FLOAT } 
  local cs = four.Buffer { dim = 4, scalar_type = four.Buffer.FLOAT }
  local is = four.Buffer { dim = 1, scalar_type = four.Buffer.UNSIGNED_INT }
  
  vs:push3D(-0.8, -0.8, 0.0)      -- Vertices
  vs:push3D( 0.8, -0.8, 0.0)
  vs:push3D( 0.0,  0.8, 0.0)

  cs:pushV4(four.Color.red ())    -- Colors
  cs:pushV4(four.Color.green ())
  cs:pushV4(four.Color.blue ())

  is:push3D(0, 1, 2)              -- Index for a single triangle

  return four.Geometry { primitive = four.Geometry.TRIANGLE, 
                         index = is, data = { vertex = vs, color = cs}}
end

local effect = Effect
{
  vertex = Effect.Shader [[
    in vec4 vertex;
    in vec4 color;
    out vec4 v_color;
    void main()
    {
      v_color = color;
      gl_Position = vertex;
    }
  ]],
  
  fragment = Effect.Shader [[
    in vec4 v_color;
    out vec4 color;
    void main() { color = v_color; }
  ]]
}

local obj = { geometry = triangle (), effect = effect }
local camera = four.Camera()

-- Render

local w, h = 600, 400
local renderer = four.Renderer { size = V2(w, h) }
local win = mimas.GLWindow()
function win:resizeGL(w, h) renderer.size = V2(w, h) end
function win:paintGL() renderer:render(camera, {obj}) end
function win:initializeGL() renderer:logInfo() end  

win:move(800, 50)
win:resize(w, h)
win:show ()
run ()



