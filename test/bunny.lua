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
      out float n_dot_l;
      out vec3 reflect;
      out vec3 view;
      void main() 
      { 
        vec3 ecPos = vec3(model_to_cam * vec4(vertex, 1.0));
        vec3 tnorm = normalize(vec3(normal_to_cam * vec4(normal, 0.0)));
        vec3 light = normalize(light_pos - ecPos);
        reflect = normalize(reflect(-light, tnorm));
        view = normalize(-ecPos);
        n_dot_l = 0.5 * (dot(light, tnorm) + 1.0);

        vec3 d_pos = 0.001 * (-1 + sin(2 * time)) * tnorm; // geom pulse
        gl_Position = camera_to_clip * vec4(ecPos + d_pos, 1.0);
      }
    ]],  

  fragment = Effect.Shader [[
    in float n_dot_l; 
    in vec3 reflect;
    in vec3 view;
    out vec4 color;
    void main(void)
    {
      vec3 kcool = min(cool_color + diffuse_cool * surf_color, 1.0);
      vec3 kwarm = min(warm_color + diffuse_warm * surf_color, 1.0);
      vec3 kfinal = mix(kcool, kwarm, n_dot_l);
      vec3 nreflect = normalize(reflect);
      vec3 nview = normalize(view);
      float spec = max(dot(nreflect, nview), 0.0);
      spec = pow(spec, 32.0);
      color = vec4(min (kfinal + spec, 1.0), 1.0);
    }
  ]]
}

local bunny = 
  { transform = Transform {},
    geometry = bunny (),
    effect = gooch }

bunny.geometry:computeVertexNormals()

local camera = Camera { transform = Transform { pos = V3(0, 0.1, 0.5) },
                        range = V2(0.1, 5)
--                        viewport = { origin = V2(0.5, 0.5), 
--                                     size = V2(0.5, 0.5) }
}

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

local bunny_orient = nil

-- Render

local w, h = 640, 360
local renderer = four.Renderer { size = V2(w, h) }
local win = mimas.GLWindow ()

function win:resizeGL(w, h) 
  renderer.size = V2(w, h) 
  camera.aspect = w / h
end

function win:paintGL() 
  gooch.uniforms.time = now() / 1000
  renderer:render(camera, {bunny}) 
end

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

    cube_orient = manip_orient(bunny.transform, pos)
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

local step = 1/60
timer = lk.Timer(step * 1000, function() win:update() end)
timer:start()
run ()



