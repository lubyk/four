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

  mstate = bt.MotionState()

  function mstate:getWorldTransform(w)
    w:setRotation(bt.Quaternion(0, 0, 0, 1))
    w:setOrigin(bt.Vector3(x, y, z))
  end

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
        true,
        1 * math.cos(phi + i * PHASE_PER_ELEM) * damp * pos_damp,
        5
      )
    end
  end
end

-- Rendering 

require 'bunny_geometry' -- hin hin
require 'gooch'

local V2 = four.V2
local V3 = four.V3
local M4 = four.M4
local Color = four.Color
local Quat = four.Quat
local Transform = four.Transform
local Geometry = four.Geometry
local Effect = four.Effect
local Camera = four.Camera
local Manip = four.Manip

function setSnakeGeometry(snake, geometry, scale)
  for _, elem in ipairs(snake) do 
    if elem.transform and scale then elem.transform.scale = scale end
    elem.geometry = geometry
  end
end

function setSnakeEffect(snake, effect)
  for _, elem in ipairs(snake) do elem.effect = effect end
end

function makeSnakeRenderTransforms(snake)
  for _, elem in ipairs(snake) do 
    if not elem.transform then 
      elem.transform = Transform()
      function elem.motion:setWorldTransform(w)
        elem.transform.pos = V3(w:getOrigin())
        elem.transform.rot = Quat(w:getRotation())
      end
    end
  end
end

function geometryWithID(i)
  local geoms =
    { function () return Geometry.Cube(0.5), V3(1, 1, 1) end,
      function () return Geometry.Sphere(0.25, 3), V3(1, 1, 1) end,
      function () return bunny (), V3(-3,3,3) end }
  return geoms[(i % #geoms) + 1]
end 

function effectWithID(i)
  local effects = 
    { function () return Effect.Wireframe() end,
      function () return gooch () end }
  return effects[(i % #effects) + 1]
end

local cam_pos = V3(-3, 8, 20)
local cam_rot = Quat.rotMap(V3(0, 0, -1), V3.unit(-cam_pos)) -- look origin
local camera = Camera { transform = Transform { pos = cam_pos,
                                                rot = cam_rot }}
local snake_geom_id = -1
local snake_effect_id = -1

function command(app, c)
  if c.ExitFullscreen then app.win:showFullScreen(false)
  elseif c.ToggleFullscreen then app.win:swapFullScreen()
  elseif c.Resize then camera.aspect = V2.x(app.size) / V2.y(app.size)
  elseif c.CycleGeometry then
    snake_geom_id = snake_geom_id + 1; 
    local g, scale = geometryWithID(snake_geom_id)()
    g:computeVertexNormals()
    setSnakeGeometry(snake, g, scale)
  elseif c.CycleEffect then    
    snake_effect_id = snake_effect_id + 1;
    setSnakeEffect(snake, effectWithID(snake_effect_id)())
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

local app = App { event = event, camera = camera, objs = snake }

function app.win:initializeGL() 
  app.renderer:logInfo() 
  command(app, { CycleGeometry = true }) -- init geom
  command(app, { CycleEffect = true })   -- init effect
  makeSnakeRenderTransforms(snake)
end

app.init ()

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
