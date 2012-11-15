--[[--
  h1. four.Renderer

  Renders renderables object from a camera viewpoint.
--]]--

-- Module definition

local ffi = require 'ffi'
local gl = four.gl
local lib = { type = 'four.Renderer' }
lib.__index = lib
four.Renderer = lib
setmetatable(lib, { __call = function(lib, ...) return lib.new(...) end })

local V2 = four.V2
local V4 = four.V4
local Buffer = four.Buffer

-- h2. Renderer backends

lib.GL32 = 1
lib.GLES = 2
lib.DEFAULT = lib.GL32

-- h2. Constructor

function lib:set(def) 
  for k, v in pairs(def) do 
    if k ~= "r" and k ~= "initialized" then self[k] = v end
  end
end

-- Returns a new renderer. Initialization keys:
-- @backend@, the renderer backend (defaults to @GL32@)
-- @size@, the viewport size
-- @log_fun@, the renderer logging function (defaults to @print@)
function lib.new(def)
  local self = 
    {  backend = lib.DEFAULT,   -- Backend selection
       size = V2(600, 400),     -- Viewport size
       debug = true,            -- More logging/diagnostics
       log_fun = print,         -- Custom renderer log function
       r = nil,                 -- Backend renderer object (private)
       initialized = false }    -- true when backend was initalized
    setmetatable(self, lib)
    if def then self:set(def) end
    self:setBackend()
    return self
end

function lib:setBackend()
    if self.backend == lib.GL32 then self.r = four.RendererGL32(self)
    elseif self.backend == lib.GLES then
      error ("GLES backend renderer unimplemented") 
    end
end

-- Backend initialization

function lib:_init()
  if not self.initialized then
    self.r:init()
    self.initialized = true
  end
end

-- ## Renderer info

function lib:info() self:_init() return self.r:getInfo() end
function lib:caps() self:_init() return self.r:getCaps() end
function lib:limits() self:_init() return self.r:getLimits() end

-- ## Renderer log

function lib:log(s) self.log_fun(s) end
function lib:logInfo(verbose)
  local info = self:info() 
  local verbose = long and true
  if not verbose then 
    local msg = string.format("Renderer OpenGL %s / GLSL %s\n         %s", 
                              info.version, info.shading_language_version, 
                              info.renderer)
    self:log(msg)
  else
    self:log("Renderer")
    for k, v in pairs(self:info()) do 
      self:log(string.format("* %s = %s", k, v)) 
    end
  end
end

-- ## Render function

function lib:isRenderable(cam, o)
  local effect = cam.effect_override or o.effect or cam.effect_default
  return o.geometry and effect
end

function lib:render(cam, objs)
  self:_init ()
  for _, o in ipairs(objs) do  
    if self:isRenderable(cam, o) and not cam.cull(o) then
      self.r:renderQueueAdd(cam, o)
    end
  end
  self.r:renderQueueFlush(cam)
end
