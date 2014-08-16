-- Draws a tri-colored triangle.

require 'lubyk'

local V2 = four.V2
local Buffer = four.Buffer 
local Geometry = four.Geometry
local Effect = four.Effect 

function triangle () -- Geometry object for a triangle inside clip space
  local vs = Buffer { dim = 3, scalar_type = Buffer.FLOAT } 
  local cs = Buffer { dim = 4, scalar_type = Buffer.FLOAT }
  local is = Buffer { dim = 1, scalar_type = Buffer.UNSIGNED_INT }
  
  vs:push3D(-0.8, -0.8, 0.0)      -- Vertices
  vs:push3D( 0.8, -0.8, 0.0)
  vs:push3D( 0.0,  0.8, 0.0)

  cs:pushV4(four.Color.red ())    -- Vertices' colors
  cs:pushV4(four.Color.green ())
  cs:pushV4(four.Color.blue ())

  is:push3D(0, 1, 2)              -- Index for a single triangle

  return Geometry { primitive = Geometry.TRIANGLES, 
                    index = is, data = { vertex = vs, color = cs}}
end

local effect = Effect -- Colors the triangle
{
  vertex = Effect.Shader [[
    in vec3 vertex;
    in vec3 color;
    out vec4 v_color;
    void main()
    {
      v_color = vec4(color, 1.0);
      gl_Position = vec4(vertex, 1.0);
    }
  ]],
  
  fragment = Effect.Shader [[
    in vec4 v_color;
    out vec4 color;
    void main() { color = v_color; }
  ]]
}

local obj = { geometry = triangle (), effect = effect } -- renderable
local camera = four.Camera()

-- Render

local w, h = 600, 400
local renderer = four.Renderer { size = V2(w, h) }

local win = mimas.GLWindow()
function win:resizeGL(w, h) renderer.size = V2(w, h) end
function win:paintGL() renderer:render(camera, {obj}) end
function win:initializeGL() renderer:logInfo() end  

win:move(100, 100)
win:resize(w, h)
win:show ()
run ()



