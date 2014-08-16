require 'lubyk'

local Effect = four.Effect
local V3 = four.V3

local prepare = function(e)
  e.uniforms.time = now() / 1000
end

-- x,y,z model based colors
function psyche2()
  return Effect {
    uniforms = {
      model_to_clip = Effect.modelToClip,
      model_to_cam = Effect.modelToCamera,
      model_to_world = Effect.modelToWorld,
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
    prepare = prepare,

    vertex = Effect.Shader [[
    in vec3 vertex;
    in vec3 normal;
    out vec3 reflect;
    out vec3 view;
    out vec3 kool;
    void main() 
    { 
      // scale
      vec3 wpos = vec3(model_to_world * vec4(vertex, 1.0));
      vec3 vs = wpos; // * 80;
      float t = time;
      vec3 d_pos = vec3(
      0.99 + 0.01 * sin(vs.x + t * 3),
      0.99 + 0.01 * sin(vs.y + t * 2),
      0.99 + 0.01 * sin(vs.z + t * 1)
      );
      //
      vec3 warp_pos = vertex; // vec3(vertex.x * d_pos.x, vertex.y * d_pos.y, vertex.z * d_pos.z);

      vec3 ecPos = vec3(model_to_cam * vec4(warp_pos, 1.0));
      vec3 tnorm = normalize(vec3(normal_to_cam * vec4(normal, 0.0)));
      vec3 light = normalize(light_pos - ecPos);
      reflect = normalize(reflect(-light, tnorm));
      view = normalize(-ecPos);

      // vec3 d_pos = 0.001 * (-1 + sin(2 * t)) * tnorm; // geom pulse

      gl_Position = camera_to_clip * vec4(ecPos.x * d_pos.x, ecPos.y * d_pos.y, ecPos.z * d_pos.z, 1.0);

      vec3 vs2 = wpos / 80; // vertex;
      vs2 = vs2 * (20 + 10 * sin(t/5));
      vs2.x = 5*sin(t/20) + vs2.x;
      float loc = vs2.x * vs2.y * vs2.z;
      kool = vec3( 
      0.5 + 0.5 * sin(loc + 2* t) * sin(loc + t) * sin(loc), 
      0.5 + 0.5 * sin(loc*4) * sin(loc*4 + 2*t) * sin(loc*4),
      0.5 + 0.5 * sin(loc) * sin(loc) * sin(loc + t)
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
end

