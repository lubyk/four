require 'lubyk'
require 'bunny_geometry'
local V2 = four.V2
local V3 = four.V3
local V4 = four.V4
local Quat = four.Quat
local Color = four.Color
local Transform = four.Transform
local Effect = four.Effect
local Camera = four.Camera 
local Manip = four.Manip

function fullscreen() -- Two triangles
  local vs = four.Buffer { dim = 3, scalar_type = four.Buffer.FLOAT } 
  local is = four.Buffer { dim = 1, scalar_type = four.Buffer.UNSIGNED_INT }
  
  -- Vertices
  vs:push3D( 1,  1, 1)  
  vs:push3D(-1,  1, 1)
  vs:push3D( 1, -1, 1)
  vs:push3D(-1, -1, 1)

  -- Index for two triangle
  is:push3D(0, 1, 2)         
  is:push3D(2, 1, 3)         

  return four.Geometry { primitive = four.Geometry.TRIANGLE, 
                         index = is, data = {vertex = vs}}
end

local sinox = Effect {
  uniforms = 
    { resolution = V2.zero(),
      time = 0 },

  vertex = Effect.Shader [[ 
    in vec3 vertex;
    void main() { gl_Position = vec4(vertex, 1.0); }
  ]],  

  fragment = Effect.Shader [[ 
    out vec4 color;
    void main() 
    {
      // p in [0.0, 1.0]
      vec2 p =  gl_FragCoord.xy / resolution.xy;
      // time = temps en [s]
      float t = time / 5;
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
    }
    ]]
}


local gooch = Effect
{
  uniforms = 
    { model_to_clip = Effect.modelToClip,
      model_to_cam = Effect.modelToCamera,
      normal_to_cam = Effect.normalModelToCamera,
      camera_to_clip = Effect.cameraToClip,
      light_pos = V3(0, 10, 4),
      surf_color = V3(0.75, 0.75, 075),
      warm_color = V3(0.6, 0.6, 0.0),
      cool_color = V3(0.0, 0.0, 0.6),
      diffuse_warm = 0.45,
      diffuse_cool = 0.45,
      time = 0,
    },
      
    vertex = Effect.Shader [[
      in vec3 vertex;
      in vec3 normal;
      out vec3 reflect;
      out vec3 view;
      out vec3 kool;
      void main() 
      { 
        // scale
        vec3 vs = vertex * 80;
        vec3 d_pos = vec3(
          0.99 + 0.01 * sin(vs.x + time * 3),
          0.99 + 0.01 * sin(vs.y + time * 2),
          0.99 + 0.01 * sin(vs.z + time * 1)
          );
        vec3 warp_pos = vec3(vertex.x * d_pos.x, vertex.y * d_pos.y, vertex.z * d_pos.z);

        vec3 ecPos = vec3(model_to_cam * vec4(warp_pos, 1.0));
        vec3 tnorm = normalize(vec3(normal_to_cam * vec4(normal, 0.0)));
        vec3 light = normalize(light_pos - ecPos);
        reflect = normalize(reflect(-light, tnorm));
        view = normalize(-ecPos);

        // vec3 d_pos = 0.001 * (-1 + sin(2 * time)) * tnorm; // geom pulse

        gl_Position = camera_to_clip * vec4(ecPos.x * d_pos.x, ecPos.y * d_pos.y, ecPos.z * d_pos.z, 1.0);

        vec3 vs2 = vertex * (20 + 10 * sin(time/5));
        vs2.x = 5*sin(time/20) + vs2.x;
        float loc = vs2.x * vs2.y * vs2.z;
        kool = vec3( 
          0.5 + 0.5 * sin(loc + 2* time) * sin(loc + time) * sin(loc), 
          0.5 + 0.5 * sin(loc*4) * sin(loc*4 + 2*time) * sin(loc*4),
          0.5 + 0.5 * sin(loc) * sin(loc) * sin(loc + time)
        );
      }
    ]],  

  fragment = Effect.Shader [[
    in vec3 reflect;
    in vec3 view;
    in vec3 kool;
    out vec4 color;
    void main(void)
    {
      // vec2 p =  gl_FragCoord.xy / resolution.xy;
      vec3 cool2 = kool; 
      // vec3(0.5 + 0.5 * sin(gl_FragCoord.z * gl_FragCoord.x * gl_FragCoord.y), cool_color.g, cool_color.b);
      vec3 warm2 = vec3(warm_color.r, warm_color.g, warm_color.b);
      vec3 kcool = min(cool2 + diffuse_cool * surf_color, 1.0);
      vec3 kwarm = min(warm2 + diffuse_warm * surf_color, 1.0);
      vec3 kfinal = kool;
      vec3 nreflect = normalize(reflect);
      vec3 nview = normalize(view);
      float spec = max(dot(nreflect, nview), 0.0);
      spec = pow(spec, 32.0);
      color = vec4(min (kfinal + spec, 1.0), 1.0);
    }
  ]]
}

local bunny = 
  { transform = Transform { pos = V3(0, -0.1, 0),
                            rot = Quat.rotZYX(V3(0, math.pi/6, 0))} ,
    geometry = bunny (),
    effect = gooch }

bunny.geometry:computeVertexNormals()

local camera = Camera { transform = Transform { pos = V3(0, 0, 0.5) },
                        range = V2(0.1, 5) }

local rotator = nil

-- Render

local w, h = 640, 360
local renderer = four.Renderer { size = V2(w, h) }
local win = mimas.GLWindow ()

function win:resizeGL(w, h) 
  local size = V2(w, h)
  renderer.size = size
  camera.aspect = w / h
  sinox.uniforms.resolution = size
end

local obj = { geometry = fullscreen (), effect = sinox }
function win:paintGL() 
  local t = now() / 1000
  gooch.uniforms.time = t
  gooch.uniforms.cool_color = V3(0.0, 0.0, 0.5 + 0.5 * math.sin(t/1.2))
  gooch.uniforms.warm_color = V3(0.5 + 0.5 * math.sin(t/1.5), 0.5 + 0.5 * math.sin(t), 0.0)
  gooch.uniforms.surf_color = V3(0.57 + 0.25 * math.cos(t/3), 0.75 + 0.25 * math.cos(t/3.5), 0.75 + 0.25 * math.cos(t/4))
  sinox.uniforms.time = t
  renderer:render(camera, {bunny, obj}) 
end

function win:initializeGL(w, h)
  renderer:logInfo()
  sinox.uniforms.resolution = V2(w, h)
end
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

    rotator = Manip.Rot(pos, bunny.transform.rot)
  end
end

function win:closed()
  timer:stop()
end

function win:mouse(x, y)
  -- TODO factor out conversion to ndc.
  local pos = V2.div (V2(x, y), renderer.size)
  pos[2] = 1 - pos[2]
  pos = 2 * pos - V2(1.0, 1.0)
  -- END todo
 
  bunny.transform.rot = Manip.rotUpdate(rotator, pos)
  local rot = Manip.rotUpdate(rotator, pos)
  win:update()
end

win:move(650, 50)
win:resize(w, h)
win:show()

local step = 1/60
timer = lk.Timer(step * 1000, function() win:update() end)
timer:start()
run ()



