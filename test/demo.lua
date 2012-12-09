--[[--
  h1. Demo
  
  Utilities for simple demos.
--]]--

local lib = {}

require 'lubyk' 
local Models = require 'Models'
local V2 = four.V2
local Geometry = four.Geometry
local Renderer = four.Renderer
local Geokit = require 'geokit'

-- h2. Application object to simplify demos

--[[--
  @App(def)@ is a new application object. @def@ keys:
  * @pos@, window position.
  * @size@, window size.
  * @renderer@, the renderer to use.
  * @win@, the window to use.
  * @event@, the event function.
  * @objs@, objects to render.
  * @camera@, camera to use for rendering.
--]]--
function lib.App(def)
  local app = { event = function (app, e) return end } 

  if def.pos then app.pos = def.pos else app.pos = V2(650, 50) end
  if def.size then app.size = def.size else app.size = V2(640, 360) end
  if def.renderer then app.renderer = def.renderer 
  else app.renderer = four.Renderer { size = app.size } end

  if def.win then app.win = def.win else app.win = mimas.GLWindow() end
  if def.event then app.event = def.event end
  if def.camera then app.camera = def.camera else app.camera = four.Camera () 
  end
  if def.objs then app.objs = def.objs else app.objs = {} end

  function app.init ()
    app.win:move(V2.x(app.pos), V2.y(app.pos))
    app.win:resize(V2.x(app.size), V2.y(app.size))
    app.win:show()
  end

  function app.win:initializeGL() app.renderer:logInfo() end
  function app.win:paintGL() app.renderer:render(app.camera, app.objs) end
  function app.win:resizeGL(w, h)
    local size = V2(w, h)
    local e = {} 
    e.Resize = true
    e.size = size
    app.size = size
    app.renderer.size = size
    app.event(app, e)
  end

  function app.win:keyboard(key, down, utf8, modifiers)
    local e = {}
    e.KeyDown = down
    e.KeyUp = not down
    e.key = key
    e.utf8 = utf8
    e.modifiers = modifiers
    app.event(app, e)
  end
  
  function app.win:click(x, y, op)
    local e = {} 
    e.MouseDown = op == mimas.MousePress or op == mimas.DoubleClick;
    e.MouseUp = op == mimas.MouseRelease
    e.double = op == mimas.DoubleClick
    e.pos = app.renderer:normalizeScreenPos(V2(x, y))
    app.event(app, e)
  end
  
  function app.win:mouse(x, y)
    local e = {}
    e.MouseMove = true
    e.pos = app.renderer:normalizeScreenPos(V2(x, y))
    app.event(app, e)
  end

  return app;
end


-- h2. Geometry 

--[[--
  @geometryCycle(def)@ is an argument less function returning 
  new geometry objects in a cyclic fashion. @def@ keys:
  * @geometries@, an array of argument less functions that returns geometry
    objects. Default has the geometries of @four.Geometry@ and the Stanford 
    Bunny.
  * @normals@, @true@ if vertex normals should be computed, defaults to @false@.
--]]--
function lib.geometryCycler(def)
  local id = -1
  local normals = def.normals or false
  local adjacency = def.adjacency or false
  local geoms = def.geometries or 
    { function () return Geometry.Cube(1) end,
      function () return Geometry.Sphere(0.5, 4) end,
      function () return Geometry.Plane(four.V2(1,1)) end,
      function () return Models.bunny(1) end }
  local function next ()  
    id = (id + 1) % #geoms
    local g = geoms[id + 1] ()
    if normals then g:computeVertexNormals() end
    if adjacency then
      g.index = Geokit.trianglesAdjacencyIndex(g.index)
      g.primitive = Geometry.TRIANGLES_ADJACENCY
    end
    return g
  end
  return next
end

-- h2. Effects

--[[--
  @effectCycle(def)@ is an argument less function returning 
  new effects in a cyclic fashion. @def@ keys:
  * @effects@, an array of argument less functions that returns effect
    objects. Default has the effect of @four.Effect@ TODO.
--]]--
function lib.effectCycler(def)
  local id = -1 
  local effects = def.effects or {} -- TODO
  local function next () 
    id = (id + 1) % #effects
    return effects[id + 1] ()
  end
  return next
end


return lib

