require 'lubyk'

-- Warp effect 
-- Taken here http://mrdoob.github.com/three.js/examples/webgl_shader.html
-- Equation due to http://badc0de.jiggawatt.org/

local V2 = four.V2
local Effect = four.Effect 

function fullscreen() -- Two triangles
  local vs = four.Buffer { dim = 3, scalar_type = four.Buffer.FLOAT } 
  local is = four.Buffer { dim = 1, scalar_type = four.Buffer.UNSIGNED_INT }
  
  -- Vertices
  vs:push3D( 1,  1, 0)  
  vs:push3D(-1,  1, 0)
  vs:push3D( 1, -1, 0)
  vs:push3D(-1, -1, 0)

  -- Index for two triangle
  is:push3D(0, 1, 2)         
  is:push3D(2, 1, 3)         

  return four.Geometry { primitive = four.Geometry.TRIANGLE, 
                         indices = is, data = {vs},
                         semantics = { vertex = 1 } }
end

local effect = Effect
{
  uniforms = 
    { resolution = Effect.U(V2.zero()),
      time = Effect.U(0) },

  vertex_shader = [[ 
    in vec3 vertex;
    void main() { gl_Position = vec4(vertex, 1.0); }
  ]],  

  fragment_shader = [[ 
    out vec4 color;
    void main() 
    {
      // p in [0.0, 1.0]
      vec2 p =  gl_FragCoord.xy / resolution.xy;
      float t = time / 10;
      // translation in xyz
      vec2 a = vec2(sin(t/2), sin(t/1.5));
      // translation in rgb
      vec3 d = vec3(sin(t/2), sin(t/1.5), sin(t));
      // angular velocity
      vec3 f = 4 * 6.28 * vec3(2, 1.8, 1.7);
      float r = sin(f.x * (d.r + a.x + p.x)) * sin(f.x * (d.r + a.y + p.y));
      float g = sin(f.y * (d.g + a.x + p.x)) * sin(f.y * (d.g + a.y + p.y));
      float b = sin(f.z * (d.b + a.x + p.x)) * sin(f.z * (d.b + a.y + p.y));

      // normalize [-1, 1] to [0, 1]
      r = 0.5 * (r + 1.0);
      // more black
      //r = r * r * r;

      g = 0.5 * (g + 1.0);
      //g = g * g * g;
      b = 0.5 * (b + 1.0);
      //b = b * b * b;

      // contour
      vec2 range = vec2(0.4, 0.9);
      float c = 
       ((r > range[0] && r < range[1]) ? r : 0) *
       ((g > range[0] && g < range[1]) ? g : 0) *
       ((b > range[0] && b < range[1]) ? b : 0);

      r = c > 0 ? r : 0;
      g = c > 0 ? g : 0;
      b = c > 0 ? b : 0;


      color=vec4(r, g, b, 1.0);
    }
    ]]
}

local obj = { geometry = fullscreen (), effect = effect }
local camera = four.Camera {}
local space = four.Space { objs = {obj} } 

-- Render

local time = 0
local w, h = 600, 400
local renderer = four.Renderer { size = V2(w, h) }
local win = mimas.GLWindow()

function win:closed()
  timer:stop()
end

function win:resizeGL(w, h) 
  local size = V2(w, h)
  renderer.size = size 
  effect.uniforms.resolution = Effect.U(size)
end

function win:paintGL()
  renderer:render(space, camera)  
  effect.uniforms.time = Effect.U(time)
end

function win:initializeGL() 
  renderer:logInfo() 
  effect.uniforms.resolution = Effect.U(V2(w, h))
end  

function win:keyboard(key, down, utf8, modifiers)
  if down then
    if key == mimas.Key_Escape then
      self:showFullScreen(false)
    elseif key == mimas.Key_Space then
      self:swapFullScreen()
    end
  end
end

win:move(10, 800)
win:resize(w, h)
win:show()
--win:showFullScreen(true)

local step = 1/60
timer = lk.Timer(step * 1000, function() time = time + 0.05 win:update() end)
timer:start()
run ()
