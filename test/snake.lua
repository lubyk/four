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
        elem.transform.pos = V3(w:getOrigin():getX(),
                                w:getOrigin():getY(),
                                w:getOrigin():getZ())
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

local cam_rotator = nil
local cam_pos = V3(-3, 8, 20)
local cam_rot = Quat.rotMap(V3(0, 0, -1), V3.unit(-cam_pos)) -- look origin
local camera = Camera { transform = Transform { pos = cam_pos,
                                                rot = cam_rot }}
local snake_geom_id = -1
local snake_effect_id = -1

function screen_to_ndc (renderer, pos)
  -- TODO factor out conversion to ndc.
  local pos = V2.div (pos, renderer.size)
  pos[2] = 1 - pos[2] -- Mimas is upside down w.r.t. OpenGL screen coords
  pos = 2 * pos - V2(1.0, 1.0)
  return pos
end

function handle_command(cmd, win, renderer)
  if cmd.Exit_fullscreen then 
    win:showFullScreen(false)
  elseif cmd.Toggle_fullscreen then 
    win:swapFullScreen()
  elseif cmd.Resize then 
    renderer.size = cmd.size
    camera.aspect = cmd.aspect
  elseif cmd.Cycle_geometry then
    snake_geom_id = snake_geom_id + 1; 
    local g, scale = geometryWithID(snake_geom_id)()
    g:computeVertexNormals()
    setSnakeGeometry(snake, g, scale)
  elseif cmd.Cycle_effect then    
    snake_effect_id = snake_effect_id + 1;
    setSnakeEffect(snake, effectWithID(snake_effect_id)())
  elseif cmd.Start_rotation then 
    local pos = screen_to_ndc(renderer, cmd.pos)
    cam_rotator = Manip.Rot(pos, camera.transform.rot)
  elseif cmd.Rotation then 
    local pos = screen_to_ndc(renderer, cmd.pos)
    camera.transform.rot = Manip.rotUpdate(cam_rotator, pos)
  elseif cmd.Zoom_in then 
    -- TODO factor that out 
    local forward = V3.unit(M4.col(Quat.toM4(camera.transform.rot),3))
    camera.transform.pos = camera.transform.pos - forward
  elseif cmd.Zoom_out then 
    -- TODO factor that out 
    local forward = V3.unit(M4.col(Quat.toM4(camera.transform.rot),3))
    camera.transform.pos = camera.transform.pos + forward
  elseif cmd.Quit then
  end
end

local w, h = 640, 360
local renderer = four.Renderer { size = V2(w, h) }
local win = mimas.GLWindow ()

function win:initializeGL() 
  renderer:logInfo() 
  handle_command({ Cycle_geometry = true }, self, renderer) -- init geom
  handle_command({ Cycle_effect = true }, self, renderer)   -- init effect
  makeSnakeRenderTransforms(snake)
end

function win:paintGL() renderer:render(camera, snake) end
function win:resizeGL(w, h) 
  local cmd = { Resize = true, size = V2(w, h), aspect = w / h }
  handle_command(cmd, self, renderer)
  self:update()
end

function win:keyboard(key, down, utf8, modifiers)
  local cmd = {}
  if down then
    if key == mimas.Key_Escape then cmd.Exit_fullscreen = true
    elseif key == mimas.Key_Space then cmd.Toggle_fullscreen = true
    elseif key == mimas.Key_Down then cmd.Zoom_out = true
    elseif key == mimas.Key_Up then cmd.Zoom_in = true
    elseif utf8 == 'g' then cmd.Cycle_geometry = true
    elseif utf8 == 'e' then cmd.Cycle_effect = true
    end
  end
  handle_command(cmd, self, renderer)
  self:update()
end

function win:click(x, y, op)
  local cmd = {} 
  if op == mimas.MousePress then 
    cmd = { Start_rotation = true, pos = V2(x, y) }
  end
  handle_command(cmd, self, renderer)
  self:update()
end

function win:mouse(x, y)
  local cmd = { Rotation = true, pos = V2(x, y) }
  handle_command(cmd, self, renderer)
  self:update()
end

win:move(650, 50)
win:resize(w, h)
win:show()

-- Run simulation
local step = 1/60
local t = 0
timer = lk.Timer(step * 1000, function()
  t = t + step
  updateMotors(snake, t)
  dynamicsWorld:stepSimulation(step, 10)
  win:update()
end)
timer:start()

run()
