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
                         index = is, data = {vertex = vs} }
end

local effect = Effect
{
  default_uniforms = 
    { resolution = Effect.CAMERA_RESOLUTION,
      time = Effect.RENDER_FRAME_START_TIME },

  vertex = Effect.Shader [[
    in vec3 vertex;
    void main() { gl_Position = vec4(vertex, 1.0); }
  ]],  

  fragment = Effect.Shader [[
    uniform vec2 resolution;
    uniform float time;
    out vec4 color;
    void main() 
    {
      float time = time / 500;
      vec2 p = -1.0 + 2.0 * gl_FragCoord.xy / resolution.xy;
      float a = time*40.0;
      float d,e,f,g=1.0/40.0,h,i,r,q;
      e=400.0*(p.x*0.5+0.5);
      f=400.0*(p.y*0.5+0.5);
      i=200.0+sin(e*g+a/150.0)*20.0;
      d=200.0+cos(f*g/2.0)*18.0+cos(e*g)*7.0;
      r=sqrt(pow(i-e,2.0)+pow(d-f,2.0));
      q=f/r;
      e=(r*cos(q))-a/2.0;f=(r*sin(q))-a/2.0;
      d=sin(e*g)*176.0+sin(e*g)*164.0+r;
      h=((f+d)+a/2.0)*g;
      i=cos(h+r*p.x/1.3)*(e+e+a)+cos(q*g*6.0)*(r+h/3.0);
      h=sin(f*g)*144.0-sin(e*g)*212.0*p.x;
      h=(h+(f-e)*q+sin(r-(a+h)/7.0)*10.0+i/4.0)*g;
      i+=cos(h*2.3*sin(a/350.0-q))*184.0*sin(q-(r*4.3+a/12.0)*g)+tan(r*g+h)*
         184.0*cos(r*g+h);
      i=mod(i/5.6,256.0)/64.0;
      if(i<0.0) i+=4.0;
      if(i>=2.0) i=4.0-i;
      d=r/350.0;
      d+=sin(d*d*8.0)*0.52;
      f=(sin(a*g)+1.0)/2.0;
      color=vec4(vec3(f*i/1.6,i/2.0+d/13.0,i)*d*p.x+
            vec3(i/1.3+d/8.0,i/2.0+d/18.0,i)*d*(1.0-p.x),1.0);
    }
  ]]
}

local obj = { geometry = fullscreen (), effect = effect }
local camera = four.Camera {}

-- Render

local time = 0
local w, h = 640, 360
local renderer = four.Renderer { size = V2(w, h) }
local win = mimas.GLWindow()
function win:initializeGL() renderer:logInfo() end  
function win:paintGL() renderer:render(camera, {obj}) end
function win:resizeGL(w, h) 
  renderer.size = V2(w, h)
  camera.aspect = w / h
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

win:move(650, 50)
win:resize(w, h)
win:showFullScreen(false)

local step = 1/60
timer = lk.Timer(step * 1000, function() time = time + 0.05 win:update() end)
timer:start()

run ()
