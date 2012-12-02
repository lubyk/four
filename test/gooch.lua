-- Gooch effect

local lib = {}

require 'lubyk'
local Effect = four.Effect
local V3 = four.V3

function lib.effect () return Effect
{
  default_uniforms = 
    { model_to_cam = Effect.MODEL_TO_CAMERA,
      normal_to_cam = Effect.MODEL_NORMAL_TO_CAMERA,
      camera_to_clip = Effect.CAMERA_TO_CLIP,
      light_pos = V3(0, 10, 4),
      surf_color = V3(0.75, 0.75, 075),
      warm_color = V3(0.6, 0.6, 0.0),
      cool_color = V3(0.0, 0.0, 0.6),
      diffuse_warm = 0.45,
      diffuse_cool = 0.45 },
      
   vertex = Effect.Shader [[
     uniform mat4 model_to_cam; 
     uniform mat3 normal_to_cam;
     uniform mat4 camera_to_clip;
     uniform vec3 light_pos;
     in vec3 vertex;
     in vec3 normal;
     out float n_dot_l;
     out vec3 reflect;
     out vec3 view;
     void main() 
     { 
       vec3 ecPos = vec3(model_to_cam * vec4(vertex, 1.0));
       vec3 tnorm = normalize(normal_to_cam * normal);
       vec3 light = normalize(light_pos - ecPos);
       reflect = normalize(reflect(-light, tnorm));
       view = normalize(-ecPos);
       n_dot_l = 0.5 * (dot(light, tnorm) + 1.0);
       gl_Position = camera_to_clip * vec4(ecPos, 1.0);
     }
   ]],  

  fragment = Effect.Shader [[
    uniform vec3 surf_color;
    uniform vec3 warm_color;
    uniform vec3 cool_color;
    uniform float diffuse_warm; 
    uniform float diffuse_cool;
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
end

return lib
