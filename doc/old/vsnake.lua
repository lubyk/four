require 'lubyk'

math.randomseed(os.time())

--=============================================== WORLD SETUP
local broadphase = bt.DbvtBroadphase()
local collisionConfiguration = bt.DefaultCollisionConfiguration()
local dispatcher = bt.CollisionDispatcher(collisionConfiguration)
local solver = bt.SequentialImpulseConstraintSolver()
local dynamicsWorld = bt.DiscreteDynamicsWorld(dispatcher,broadphase,solver,collisionConfiguration)

dynamicsWorld:setGravity(bt.Vector3(0,-10,0))

local groundShape = bt.StaticPlaneShape(bt.Vector3(0,1,0),1)
local groundMotionState = bt.DefaultMotionState(
  bt.Transform(
    bt.Quaternion(0,0,0,1),
    bt.Vector3(0,-1,0)
  )
)

local groundRigidBodyCI = bt.RigidBody.RigidBodyConstructionInfo(
  0,
  groundMotionState,
  groundShape,
  bt.Vector3(0,0,0)
)
groundRigidBodyCI.m_restitution = 1.0

local groundRigidBody = bt.RigidBody(groundRigidBodyCI)
dynamicsWorld:addRigidBody(groundRigidBody)

--=============================================== SHAPES
local snake = {}
local SNAKE_SIZE = 8
local MAX_BODIES = 15
local ELEM_SIZE = SNAKE_SIZE / MAX_BODIES
local BALL_MARGIN = 0.4 -- Margin + ball = 1.0
local BALL_RADIUS = (ELEM_SIZE * (1 - BALL_MARGIN)) / 2

local elem
local ORIGIN_X = -SNAKE_SIZE
local ORIGIN_Y = 0
local ORIGIN_Z = 0

--=============================================== Compute inertia
local MASS = 1
local INERTIA = bt.Vector3(0,0,0)
local ELEM_SHAPE = bt.BoxShape(bt.Vector3(BALL_RADIUS, BALL_RADIUS, BALL_RADIUS))
ELEM_SHAPE:calculateLocalInertia(MASS, INERTIA)

local x = ORIGIN_X - (SNAKE_SIZE / 2)
local y = BALL_RADIUS
local z = ORIGIN_Z

-- snake: BALL ----- + ----- BALL -- + -- BALL
--         forw ---->|<---- back
local back = bt.Vector3(-ELEM_SIZE/2, 0, 0)
local forw = bt.Vector3(ELEM_SIZE/2, 0, 0)
local NoRotation = bt.Quaternion(0,0,0,1)
local UP_AXIS = bt.Vector3(0, 1, 0)

for i=1,MAX_BODIES do
  local prev = elem
  elem = {shape = ELEM_SHAPE}

  mstate = bt.MotionState(bt.Quaternion(0, 0, 0, 1), bt.Vector3(x, y, z))

  elem.motion = mstate

  local ci = bt.RigidBody.RigidBodyConstructionInfo(
    MASS,
    elem.motion,
    ELEM_SHAPE,
    INERTIA
  )
  elem.ci = ci
  ci.m_restitution = 0.5
  ci.m_linearDamping = 0 --.2

  local body = bt.RigidBody(elem.ci)
  body:setActivationState(bt.DISABLE_DEACTIVATION)
  body:setAnisotropicFriction(bt.Vector3(0.05, 0, 2))
  body:setFriction(0.5)

  elem.body = body
  dynamicsWorld:addRigidBody(body)
  table.insert(snake, elem)

  if prev then
    -- Create constraint
    elem.constraint = bt.HingeConstraint(
      prev.body,
      elem.body,
      forw,
      back,
      UP_AXIS,
      UP_AXIS
    )
    dynamicsWorld:addConstraint(elem.constraint)
  end

  x = x + ELEM_SIZE
end

local PHASE_PER_ELEM = 2 * math.pi / MAX_BODIES
local ANGULAR_SPEED  = 2 * math.pi / 4
--=============================================== Motor oscillations
function updateMotors(snake, t)
  -- use low velocities during startup
  local damp = (1 - math.exp(-t/8))
  local phi = t * ANGULAR_SPEED
  for i, elem in ipairs(snake) do
    local constraint = elem.constraint
    local pos_damp = (MAX_BODIES-i)/(MAX_BODIES-1)
    pos_damp = 1 - (pos_damp * pos_damp * pos_damp)
    if constraint then
      -- sin oscillation
      constraint:enableAngularMotor(
        true,1 * math.cos(phi + i * PHASE_PER_ELEM) * damp * pos_damp,
        5
      )
    end
  end
end

-- Rendering 

local Demo = require 'demo'
local Models = require 'models' 
local Shadefuns = require 'shadefuns'
local Gooch = require 'gooch'
local Manip = require 'manip'

local V2 = four.V2
local V3 = four.V3
local M4 = four.M4
local Color = four.Color
local Quat = four.Quat
local Transform = four.Transform
local Geometry = four.Geometry
local Effect = four.Effect
local Buffer = four.Buffer
local Camera = four.Camera

function setSnakeGeometry(snake, geometry) snake.geometry = geometry end
function setSnakeEffect(snake, effect) snake.effect = effect end
function makeSnakeRenderTransforms(snake)
--  snake.transform = Transform{} 
  snake.m = {}
  for i, elem in ipairs(snake) do 
    snake.m[i] = Transform()
    function elem.motion:setWorldTransform(w)
      snake.m[i].pos = V3(w:getOrigin())
      snake.m[i].rot = Quat(w:getRotation())
    end
  end
end



--[[--
  @SegmentedCuboid(V3(w, h, d) [, V2(xseg, yseg, zseg))@ is a cuboid centered 
  with 
  extents @w, h, d@ centered on the origin. Each of its faces are divided in 
  @xseg@, @yseg@, @zseg@ segments in the corresponding dimensions (all default
  to @1@).
--]]--                                                                
function SegmentedCuboid(extents, segs, mats_count)
  local segs = segs or V3(1, 1, 1)
  local w, h, d = V3.tuple(extents)
  local xseg, yseg, zseg = V3.tuple(segs)
  local dx = w / xseg
  local dy = h / yseg
  local dz = d / zseg
  local x0 = -0.5 * w
  local y0 = -0.5 * h
  local z0 = -0.5 * d
  local vs = Buffer { dim = 3, scalar_type = Buffer.FLOAT } 
  local m_weights = Buffer { dim = 3, scalar_type = Buffer.FLOAT }
  local m_indices = Buffer { dim = 3, scalar_type = Buffer.UNSIGNED_INT }
  local is = Buffer { dim = 3, scalar_type = Buffer.UNSIGNED_INT }

  -- Vertices
  for z = 0, zseg do
    for y = 0, yseg do 
      for x = 0, xseg do
        if (z == 0 or z == zseg) or
           (y == 0 or y == yseg) or
           (x == 0 or x == xseg) then 
          vs:push3D(x0 + x * dx, y0 + y * dy, y0 + z * dz)

          m_indices:push3D(x == 0 and 0 or x - 1, 
                           x,
                           x == xseg and xseg or x + 1)
          m_weights:push3D(0.25, 0.5, 0.25)
        end
      end
    end
  end

  local function vi(x, y, z) -- index zero based. 
    if z == 0 then return y * (xseg + 1) + x 
    else
      local b0 = (yseg + 1) * (xseg + 1) +              -- rear vertices
        (z - 1) * (2 * (xseg + 1) + 2 * (yseg + 1) - 4) -- chunks
      
      if z == zseg then return b0 + y * (xseg + 1) + x
      else    
        if y == 0 then return b0 + x
        else
          local b1 = xseg + 1 +  -- bottom line vertices
            2 * (y - 1) -- left/right pairs
          if y == yseg then return b0 + b1 + x 
          else
          if x == 0 then return b0 + b1 
          elseif x == xseg then return b0 + b1 + 1 
          else
            return -1
          end
        end
        end
      end
    end
  end

  -- rear
  for y = 0, yseg - 1 do 
    for x = 0, xseg - 1 do 
      is:push3D(vi(x, y, 0), vi(x + 1, y + 1, 0), vi(x + 1, y, 0))
      is:push3D(vi(x, y, 0), vi(x, y + 1, 0), vi(x + 1, y + 1, 0))
    end
  end

  -- front 
  for y = 0, yseg - 1 do 
    for x = 0, xseg - 1 do 
      is:push3D(vi(x, y, zseg), vi(x + 1, y, zseg), vi(x + 1, y + 1, zseg))
      is:push3D(vi(x, y, zseg), vi(x + 1, y + 1, zseg), vi(x, y + 1, zseg))
    end
  end

  -- bottom 
  for z = 0, zseg - 1 do 
    for x = 0, xseg - 1 do 
      is:push3D(vi(x, 0, z), vi(x + 1, 0, z + 1), vi(x, 0, z + 1))
      is:push3D(vi(x, 0, z), vi(x + 1, 0, z), vi(x + 1, 0, z + 1))
    end
  end

  -- top
  for z = 0, zseg - 1 do 
    for x = 0, xseg - 1 do 
      is:push3D(vi(x, yseg, z), vi(x, yseg, z + 1), vi(x + 1, yseg, z + 1))
      is:push3D(vi(x, yseg, z), vi(x + 1, yseg, z + 1), vi(x + 1, yseg, z))
    end
  end

  -- left 
  for z = 0, zseg - 1 do 
    for y = 0, yseg - 1 do 
      is:push3D(vi(0, y, z), vi(0, y + 1, z + 1), vi(0, y + 1, z))
      is:push3D(vi(0, y, z), vi(0, y, z + 1), vi(0, y + 1, z + 1))
    end
  end
  
  -- right
  for z = 0, zseg - 1 do 
    for y = 0, yseg - 1 do 
      is:push3D(vi(xseg, y, z), vi(xseg, y + 1, z), vi(xseg, y + 1, z + 1))
      is:push3D(vi(xseg, y, z), vi(xseg, y + 1, z + 1), vi(xseg, y, z + 1))
    end
  end
  
  return Geometry { name = "snake", primitive = Geometry.TRIANGLES,
                    data = { vertex = vs, 
                             m_indices = m_indices, 
                             m_weights = m_weights }, index = is, 
                    extents = extents } 
end



local geometries = 
  { function () 
      local g = SegmentedCuboid(V3(0, 0.5, 0.5), V3(14, 1, 1)) 
--      g.pre_transform = M4.move(V3(-4, 0, 0))
      return g
    end }

local nextGeometry = Demo.geometryCycler { normals = true, 
                                           geometries = geometries} 

local vertexSkin = Effect.Shader [=[
  uniform mat4 model_to_clip;
  uniform mat4 m[15];
  in vec3 vertex;
  in ivec3 m_indices;
  in vec3 m_weights;

  out vec3 v_tex_coord;
  void main () 
  {
    vec4 p = vec4(vertex, 1.0);
    p = m_weights[0] * m[m_indices[0]] * p + 
        m_weights[1] * m[m_indices[1]] * p + 
        m_weights[2] * m[m_indices[2]] * p;
    v_tex_coord = vertex;
    gl_Position = model_to_clip * p;
  }]=]

function sinskin () return Effect 
{
  default_uniforms = 
    { world_to_clip = Effect.WORLD_TO_CLIP,
      model_to_clip = Effect.MODEL_TO_CLIP,
      delta = V3(0,0,0),
      time = Effect.RENDER_FRAME_START_TIME },

  vertex = vertexSkin,
  fragment = { 
    Shadefuns.smoothcut,
    Effect.Shader [[ 
    uniform float time;
    out vec4 color;
    in vec3 v_tex_coord;

    void main( void )
    {
      float time = time * 1e-3;
      vec3 c = 0.5 + 0.5 * sin(v_tex_coord + time / vec3(2, 3, 4));
      c.g = (c.g - 0.5) *  sin(v_tex_coord.x * time / 2) + 0.5;

      const float e0 = 0.2;
      const float e1 = 0.7;
      float r = smoothcut(e0, e1, c.r);
      float g = smoothcut(e0, e1, c.g);
      float b = smoothcut(e0, e1, c.b);

      // fuse colors
      float sum = r + g + b;
      color=vec4(sum * vec3(r, g, b), 1.0);
    }]]
  }
}
end

function snoiseskin () return Effect 
{
  default_uniforms = 
    { world_to_clip = Effect.WORLD_TO_CLIP, 
      model_to_clip = Effect.MODEL_TO_CLIP,
      delta = V3(0,0,0),
      time = Effect.RENDER_FRAME_START_TIME },
  
  vertex = vertexSkin,
  fragment = { 
    Shadefuns.smoothcut,
    Shadefuns.snoise,
    Effect.Shader [[ 
    uniform float time;
    in vec3 v_tex_coord;
    out vec4 color;
    void main( void )
    {
      float time = time * 1e-5;
      vec3 c = vec3(snoise(v_tex_coord * 0.3 - vec3(0.0, 0.0, time * 5.6)),
                    snoise(v_tex_coord * 0.3 - vec3(0.0, 0.0, time * 4.8)),
                    snoise(v_tex_coord * 0.3 - vec3(0.0, 0.0, time * 4.9)));
 
      const float e0 = 0.2;
      const float e1 = 0.7;

      float r = smoothcut(e0, e1, c.r);
      float g = smoothcut(e0, e1, c.g);
      float b = smoothcut(e0, e1, c.b);

      // fuse colors
      float sum = r + g + b;
      color=vec4(sum * vec3(r, g, b), 1.0);
    }]]
  }
}
end


local effects = 
  { sinskin,
    snoiseskin,
    function () 
      local e = Effect.Wireframe() 
      e.vertex = vertexSkin
      e.default_uniforms["world_to_clip"] = Effect.WORLD_TO_CLIP
      return e
    end,
    Gooch.effect, }  

local nextEffect = Demo.effectCycler { effects = effects } 

local cam_pos = V3(-3, 8, 20)
local cam_rot = Quat.rotMap(V3(0, 0, -1), V3.unit(-cam_pos)) -- look origin
local camera = Camera { transform = Transform { pos = cam_pos,
                                                rot = cam_rot }}

function command(app, c)
  if c.ExitFullscreen then app.win:showFullScreen(false)
  elseif c.ToggleFullscreen then app.win:swapFullScreen()
  elseif c.Resize then camera.aspect = V2.x(app.size) / V2.y(app.size)
  elseif c.CycleGeometry then setSnakeGeometry(snake, nextGeometry())
  elseif c.CycleEffect then setSnakeEffect(snake, nextEffect())
  elseif c.StartRotation then 
    local pos = camera:screenToDevice(c.pos)
    app.rotator = Manip.Rot(camera.transform.rot, pos)
  elseif c.Rotation then 
    local pos = camera:screenToDevice(c.pos)
    camera.transform.rot = Manip.rotUpdate(app.rotator, pos)
  elseif c.ZoomIn then 
    -- TODO factor that out 
    local forward = V3.unit(M4.col(Quat.toM4(camera.transform.rot),3))
    camera.transform.pos = camera.transform.pos - forward
  elseif c.ZoomOut then 
    -- TODO factor that out 
    local forward = V3.unit(M4.col(Quat.toM4(camera.transform.rot),3))
    camera.transform.pos = camera.transform.pos + forward
  end
end

function event(app, e) 
  local c = {} 
  if e.Resize then c.Resize = true end
  if e.KeyDown then 
    if e.key == mimas.Key_Escape then c.ExitFullscreen = true
    elseif e.key == mimas.Key_Space then c.ToggleFullscreen = true
    elseif e.key == mimas.Key_Up then c.ZoomIn = true
    elseif e.key == mimas.Key_Down then c.ZoomOut = true 
    elseif e.utf8 == 'g' then c.CycleGeometry = true
    elseif e.utf8 == 'e' then c.CycleEffect = true
    end
  end
  if e.MouseDown then c.StartRotation = true c.pos = e.pos end
  if e.MouseMove then c.Rotation = true c.pos = e.pos end
  command(app, c)
end

-- Application

local app = Demo.App { event = event, camera = camera, objs = { snake } }

function app.win:initializeGL() 
  app.renderer:logInfo() 
  local limits = app.renderer:limits ()
  for k, v in pairs(limits) do print(k, v) end
end

app.init ()
setSnakeGeometry(snake, nextGeometry())
setSnakeEffect(snake, nextEffect())
makeSnakeRenderTransforms(snake)

-- Run simulation

local step = 1/60
local t = 0
timer = lk.Timer(step * 1000, function()
  t = t + step
  updateMotors(snake, t)
  dynamicsWorld:stepSimulation(step, 10)
  app.win:update()
end)
timer:start()

run()
