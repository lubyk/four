-- Sinex effect
-- Gaspard Buma, 2012
require 'lubyk'

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
                         index = is, data = {vertex = vs}}
end

local effect = Effect
{
  uniforms = 
    { resolution = V2.zero(),
      time = 0 },

  vertex = Effect.Shader [[ 
    in vec3 vertex;
    void main() { gl_Position = vec4(vertex, 1.0); }
  ]],  

  fragment = Effect.Shader [[ 
    // 
    float bump(float x, float a, float b, float k) {
      if (x < a) { // || x > b) {
        return 0.0;
      } else if (x > b) {
        return 0;
      } else if (x < (b+a)/2) {
        // bump pass from low to high
        return 1.0 - exp(k * (a - x));
      } else {
        // bump pass from high to low
        return 1.0 - exp(k * (x - b));
      }                   
    }

    float sigmo(float x, float a, float b, float k) {
      if (x < (a+b)/2) {
        return 1.0 / (1.0 + exp(-k*(x-a)));
      } else {
        return 1.0 - 1.0 / (1.0 + exp(-k*(x-b)));
      }
    }

    out vec4 color;
    void main() 
    {
      // p in [0.0, 1.0]
      vec2 p =  gl_FragCoord.xy / resolution.xy;
      // time = temps en [s]
      float t = 30 + (time / 50);
      // zoom
      vec3 f = 4 * 6.28 * vec3(2, 1.8, 1.7) * (1.0 + sin(t/8));

      // warp effect
      float amp_scale = 0.01 * (1.0 + sin(t)) * 96 / f.x;
      vec2 amp = vec2(amp_scale, amp_scale * resolution.x/resolution.y);
      float px = p.x;
      p.x = p.x * (1-amp.x) + (amp.x * 0.5 * (1.0 + sin(p.y * f.x * 0.3 * (1.0 + sin(t*10*sin(t/10))))));
      p.y = p.y * (1-amp.y) + (amp.y* 0.5 * (1.0 + sin(px  * f.x * 0.3 * (1.0 + sin(t*10*sin(t/10))))));

      // translation in xyz
      vec2 a = vec2(sin(t/2), sin(t/1.5));
      // translation in rgb
      vec3 d = vec3(sin(t/5), sin(t/5.5), sin(t/6));
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
      vec2 range = vec2(
        0.7 * (2.0 + sin(p.x + a.x)) / 3.0,
        0.2 + 0.8 * (2.0 + sin(p.y + a.y * 0.5)) / 3.0
      );
      // smooth cut
      r = r * sigmo(r, range[0], range[1], 80);
      g = g * sigmo(g, range[0], range[1], 80);
      b = b * sigmo(b, range[0], range[1], 80);

      // fuse colors
      float c = r + g + b;
      color=vec4(r * c, g * c, b * c, 1.0);
    }
    ]]
}

local obj = { geometry = fullscreen (), effect = effect }
local camera = four.Camera {}

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
  effect.uniforms.resolution = size
end

function win:paintGL()
  renderer:render(camera, {obj})  
  effect.uniforms.time = now() / 1000
end

function win:initializeGL() 
  renderer:logInfo() 
  effect.uniforms.resolution = V2(w, h)
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
timer = lk.Timer(step * 1000, function() win:update() end)
timer:start()
run ()
