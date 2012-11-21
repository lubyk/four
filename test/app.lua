require 'lubyk'

-- Application object to simplify demos

local V2 = four.V2
local Renderer = four.Renderer

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
function App(def)
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
