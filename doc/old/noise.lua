-- Sinex effect
-- Gaspard Buma, 2012
require 'lubyk'
require 'test/snoise'

local V2 = four.V2
local Effect = four.Effect 
local Transform = four.Transform

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
    { resolution  = V2.zero(),
      modelToClip = Effect.modelToClip,
      time = 0 },

  vertex = Effect.Shader [[ 
in vec3 vertex;
out vec3 v_texCoord3D;

void main( void )
{
	gl_Position = vec4(vertex, 1.0);
  v_texCoord3D = vertex;
}
  ]],  

  fragment = Effect.Shader(snoise .. [[ 
in vec3 v_texCoord3D;
out vec4 color;

//
// main()
//
void main( void )
{
  float time = time * 0.01;
  // Perturb the texcoords with three components of noise
  vec3 uvw = v_texCoord3D + 0.1*vec3(snoise(v_texCoord3D + vec3(0.0, 0.0, time)),
    snoise(v_texCoord3D + vec3(43.0, 17.0, time)),
	snoise(v_texCoord3D + vec3(-17.0, -43.0, time)));
  // Six components of noise in a fractal sum
  // n += 0.5 * snoise(uvw * 2.0 - vec3(0.0, 0.0, time*1.4)); 
  // n += 0.25 * snoise(uvw * 4.0 - vec3(0.0, 0.0, time*2.0)); 
  // n += 0.125 * snoise(uvw * 8.0 - vec3(0.0, 0.0, time*2.8)); 
  // n += 0.0325 * snoise(uvw * 16.0 - vec3(0.0, 0.0, time*4.0)); 

  vec3 n = vec3(
    snoise(uvw - vec3(0.0, 0.0, time * 5.6)),
    snoise(uvw - vec3(0.0, 0.0, time * 4.8)),
    snoise(uvw - vec3(0.0, 0.0, time * 4.9))
    );

  //n = n * 0.7;
  // A "hot" colormap - cheesy but effective 


  vec2 range = vec2(0.2, 0.7);
  float r = n.x;
  float g = n.y;
  float b = n.z;

  // smooth cut
  if (r > range[1]) {
    // distance to range[1] in [1, 0];
    float dist = 1.0 - (r - range[1]) / (1.0 - range[1]);
    // quick turn to 0
    r = r * dist * dist * dist;
  } else if (r < range[0]) {
    // distance to range[0] in [1, 0];
    float dist = 1.0 - (range[0] - r) / range[0];
    // quick turn to 0
    r = r * dist * dist * dist * dist * dist;
  }

  if (g > range[1]) {
    // distance to range[1] in [1, 0];
    float dist = 1.0 - (g - range[1]) / (1.0 - range[1]);
    // quick turn to 0
    g = g * dist * dist * dist;
  } else if (g < range[0]) {
    // distance to range[0] in [1, 0];
    float dist = 1.0 - (range[0] - g) / range[0];
    // quick turn to 0
    g = g * dist * dist * dist * dist * dist;
  }

  if (b > range[1]) {
    // distance to range[1] in [1, 0];
    float dist = 1.0 - (b - range[1]) / (1.0 - range[1]);
    // quick turn to 0
    b = b * dist * dist * dist;
  } else if (b < range[0]) {
    // distance to range[0] in [1, 0];
    float dist = 1.0 - (range[0] - b) / range[0];
    // quick turn to 0
    b = b * dist * dist * dist * dist * dist;
  }


  // fuse colors
  float c = r + g + b;
  color=vec4(r * c, g * c, b * c, 1.0);
  color=vec4(r, g, b, 1.0);

  //color = vec4(vec3(n, n, n), 1.0);
  //color = vec4(vec3(1.0, 0.5, 0.0) + vec3(n, n, n), 1.0);
}
    ]])
}

local obj = { transform = Transform(), geometry = fullscreen (), effect = effect }
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
