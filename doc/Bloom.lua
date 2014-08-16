--[[------------------------------------------------------

  # Simple bloom 'glow' filter

  In this tutorial, we show how to use render to texture to create a simple
  glow effect.

  ![effect screenshot](example/four/img/Bloom.png)

  Note that you must run this example with `luajit` since plain lua is not
  supported by four.

  ## Download source

  [SimpleShader.lua](example/four/Bloom.lua)

--]]------------------------------------------------------
-- doc:lit

-- # Require
--
-- We need the scheduling library 'lens' and window setup 'lui'.
local lens = require 'lens'
local lui  = require 'lui'
local four = require 'four'

-- Autoload this script.
lens.run(function() lens.FileWatch() end)

-- Declare some constants.
local WIN_SIZE   = {w = 400, h = 400}
local WIN_POS    = {x = 10 , y = 10 }
local SATURATION = 0.4

-- # Geometry
--
-- We must now prepare the geometry that we want to display. In this example,
-- we simply create two triangles that fill the clip space (= screen).
local function square()
  -- Vertex buffer (list of coordinates).
  local vb = four.Buffer { dim = 3,
             scalar_type = four.Buffer.FLOAT } 
  -- Color buffer (colors for each coordinate).
  local cb = four.Buffer { dim = 4,
             scalar_type = four.Buffer.FLOAT }
  -- Index buffer (actual triangles defined with vertices in `vb`).
  local ib = four.Buffer { dim = 1,
             scalar_type = four.Buffer.UNSIGNED_INT }

  local tex = four.Buffer { dim = 2,
             scalar_type = four.Buffer.FLOAT }
  -- The drawing shows the coordinates and index values that we will use
  -- when filling the index.
  --
  --   #txt ascii
  --   (-1, 1)              (1, 1)
  --     +--------------------+
  --     | 2                3 |
  --     |                    |
  --     |                    |
  --     | 0                1 |
  --     +--------------------+
  --   (-1,-1)              (1, -1)
  --
  -- Create four vertices, one for each corner.
  vb:push3D(-1.0, -1.0, 0.0)
  tex:push2D(1.0, 1.0)

  vb:push3D( 1.0, -1.0, 0.0)
  tex:push2D(0.0, 1.0)

  vb:push3D(-1.0,  1.0, 0.0)
  tex:push2D(1.0, 0.0)

  vb:push3D( 1.0,  1.0, 0.0)
  tex:push2D(0.0, 0.0)

  -- Colors for the positions above.
  cb:pushV4(four.Color.red())
  cb:pushV4(four.Color.green())
  cb:pushV4(four.Color.blue())
  cb:pushV4(four.Color.white())

  -- Create two triangles made of 3 vertices. Note that the index is
  -- zero based.
  ib:push3D(0, 1, 2)
  ib:push3D(1, 3, 2)

  -- Create the actual geometry object with four.Geometry. Set the primitive
  -- to triangles and set index and data with the buffered we just prepared.
  return four.Geometry {
    primitive = four.Geometry.TRIANGLE, 
    index = ib,
    data = { vertex = vb, color = cb, tex = tex}
  }

  -- End of the local `square()` function definition.
end


-- # Renderer
--
-- Create the renderer with four.Renderer.
renderer = four.Renderer {
  size = four.V2(WIN_SIZE.w, WIN_SIZE.h),
}

-- # Camera
--
-- Use four.Camera to create a simple camera.
camera = four.Camera {
  transform = four.Transform {
    pos = four.V3(0, 0, 5)
  }
}


-- # Effect
--
-- We create a new four.Effect that will process our geometry and make
-- something nice out of it.
--
-- `default_uniforms` declares the uniforms and sets default values in case
-- the renderable (in our case `obj`) does not redefine these values.
--
-- The special value [RENDER_FRAME_START_TIME](four.Effect.html#RENDER_FRAME_START_TIME) set for `time` will
-- give use the current time in seconds (0 = script start).
local bloom = four.Effect {
  default_uniforms = {
    time = four.Effect.RENDER_FRAME_START_TIME,
  },
}

-- Define the vertex shader. This shader simply passes values along to the
-- fragment shader.
bloom.vertex = four.Effect.Shader [[
  in vec4 vertex;
  in vec4 color;
  out vec4 v_vertex;
  out vec4 v_color;

  in  vec2 tex;
  out vec2 v_tex;
  
  void main()
  {
    v_tex    = tex;
    v_vertex = vertex;
    v_color  = color;
    gl_Position = vertex;
  }
]]
  
-- Define the fragment shader. This shader simply creates periodic colors
-- based on pixel position and time.
bloom.fragment = four.Effect.Shader [[
  in vec2 v_tex;
  in vec4 v_vertex;
  in vec4 v_color;

  uniform sampler2D cube_image;
  uniform float time;
  float t = time;

  out vec4 color;

  void main() {
    vec4 v = 140 * (v_vertex + vec4(sin(t/8), sin(t/20), sin(t/30), 0.0));
    vec4 img = texture(cube_image, v_tex + 0.05*vec2(v_vertex.x*sin(t), v_vertex.y * sin(t/2)));

    color = vec4(img.r, img.g, img.b, 1);
  }
]]

-- # Texture and framebuffer

-- Create the texture that will contain the first rendering result.
cube_image = cube_image or four.Texture {
  type = four.Texture.TYPE_2D, 
  internal_format = four.Texture.RGBA_8UN,
  size = four.V3(256, 256, 1),
  wrap_s = four.Texture.WRAP_CLAMP_TO_EDGE,
  wrap_t = four.Texture.WRAP_CLAMP_TO_EDGE,
  mag_filter = four.Texture.MAG_LINEAR,
  min_filter = four.Texture.MIN_LINEAR_MIPMAP_LINEAR,
}

cube_frame = cube_frame or four.Framebuffer {
  texture = cube_image,
}

-- # Renderable

-- Draw a cube during first pass
local angle = math.pi/4
cube_obj = {
  transform = four.Transform {
    rot = four.Quat.rotZYX(four.V3(angle, angle, 0))
  },
  geometry = four.Geometry.Cube(1),
  effect = four.Effect.Wireframe {
    fill_color = four.Color(1,0.5,0.5,1),
    wire_color = four.Color(0.4,0.2,0,1),
    wire_width = 2.0,
  },
}

-- Draw the bloom effect during second pass. The 'cube_image' texture is the result
-- from the first pass.
bloom_obj = bloom_obj or {
  geometry   = square(),
  effect     = bloom,
  cube_image = cube_image,
}

-- # Window
--
-- We create an OpenGL window with lui.View, set the size and position.
if not win then
  win = lui.View()
  win:resize(WIN_SIZE.w, WIN_SIZE.h)
  win:move(WIN_POS.x, WIN_POS.y)
end

-- Swap fullscreen on mouse down.
function win:mouseDown()
  self:swapFullscreen()
end

-- In case we resize the window, we want our content to scale so we need to
-- update the renderer's `size` attribute.
function win:resized(w, h)
  renderer.size = four.V2(w, h)
end

-- The window's draw function calls four.Renderer.render with our camera
-- and object and then swaps OpenGL buffers.
function win:draw()
  -- First render to framebuffer
  renderer:render(camera, {cube_obj}, cube_frame)

  -- Render bloom effect to screen
  renderer:render(camera, {bloom_obj})
  self:swapBuffers()
end

-- Show the window once all the the callbacks are in place.
win:show()

renderer:logInfo()


-- # Runtime

-- ## Timer
-- Since our effect is a function of time, we update at 60 Hz. For this we
-- create a timer to update window content every few milliseconds.
--
-- We also change the uniform's saturation with a random value between
-- [0, 0.8] for a stupid blink effect.
timer = timer or lens.Timer(200)

function timer:timeout()
  win:draw()
end
timer:setInterval(1/60)

-- Start the timer.
if not timer:running() then
  timer:start(1)
end


--[[
  ## Download source

  [SimpleShader.lua](example/four/SimpleShader.lua)
--]]


