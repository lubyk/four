--[[--
  h1. four.Renderer

  Renders renderables object with a camera.
--]]--

-- Module definition

local ffi = require 'ffi'
local lib = { type = 'four.Renderer' }
lib.__index = lib
four.Renderer = lib
setmetatable(lib, { __call = function(lib, ...) return lib.new(...) end })

local V2 = four.V2
local V4 = four.V4
local Buffer = four.Buffer
local Geometry = four.Geometry

-- h2. Renderer backends

lib.GL32 = 1
lib.GLES = 2
lib.DEFAULT = lib.GL32

-- h2. Constructor

--[[--
  @Renderer(def)@ is a new renderer. @def@ keys:
  * @backend@, the renderer backend (defaults to @GL32@).
  * @size@, a @V2@ defining the viewport size (defaults to V2(480,270).
  * @error_line_pattern@, a string used to parse GPU compiler logs.
    Must split a line in three part, before the GLSL file number,
    the file number, after the file number.
--]]-- 
function lib.new(def)
  local self = 
    {  backend = lib.DEFAULT,   
       frame_start_time = -1,
       size = V2(480, 270),     
       stats = lib.statsTable (), 
       error_line_pattern = "([^:]+: *)(%d+)(:.*)",
       debug = true,            -- More logging/diagnostics
       r = nil,                 -- Backend renderer object (private)
       initialized = false }    -- true when backend was initalized
    setmetatable(self, lib)
    if def then self:set(def) end
    self:_setBackend()
    return self
end

function lib:set(def) 
  if def.backend then self.backend = def.backend end
  if def.size then self.size = def.size end
  if def.error_line_pattern then
    self.error_line_pattern = def.error_line_pattern 
  end
end

function lib:_setBackend()
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


-- h2. Renderer info

function lib:info() self:_init() return self.r:getInfo() end
function lib:caps() self:_init() return self.r:getCaps() end
function lib:limits() self:_init() return self.r:getLimits() end


-- h2. Render statistics

function lib:stats() return self.stats end

function lib.statsTable () 
  return 
    { frame_stamp = nil,          -- start time of last frame
      sample_stamp = nil,         -- start time of sample 
      sample_frame_count = 0,     -- number of frames in sample
      frame_hz = 0,               -- frame rate
      max_frame_hz = -math.huge,
      min_frame_hz = math.huge,
      frame_time = 0,            -- duration of last frame
      max_frame_time = -math.huge,     
      min_frame_time = math.huge,
      frame_vertex_count = 0,     -- vertex count of current frame
      frame_face_count = 0 }      -- face count of current frame
end

function lib:resetStats() self.stats = lib.statsTable () end
function lib:updateStats(now) 
  local stats = self.stats
  stats.frame_vertex_count = 0;
  stats.frame_face_count = 0;
  if not stats.frame_stamp then 
    stats.frame_stamp = now
    stats.sample_stamp = now
  else 
    local sample_duration = now - stats.sample_stamp
    stats.sample_frame_count = stats.sample_frame_count + 1;
    if sample_duration >= 1000 then 
      stats.frame_hz = (stats.sample_frame_count / sample_duration) * 1000
      stats.max_frame_hz = math.max(stats.frame_hz, stats.max_frame_hz)
      stats.min_frame_hz = math.min(stats.frame_hz, stats.min_frame_hz)
      stats.sample_frame_count = 0;
      stats.sample_stamp = now
    end
    stats.frame_time = now - stats.frame_stamp
    stats.max_frame_time = math.max(stats.frame_time, stats.max_frame_time)
    stats.min_frame_time = math.min(stats.frame_time, stats.min_frame_time)
    stats.frame_stamp = now
  end
end

function lib:addGeometryStats(g)
  local stats = self.stats
  local v_count = g.index:length()
  local f_count = 0
  if g.primitive == Geometry.TRIANGLES then f_count = v_count / 3
  elseif g.primitive == Geometry.TRIANGLE_STRIP then f_count = v_count - 2
  elseif g.primitive == Geometry.TRIANGLE_FAN then f_count = v_count - 2
  elseif g.primitive == Geometry.TRIANGLES_ADJACENCY then f_count = v_count / 6
  elseif g.primitive == Geometry.TRIANGLE_STRIP_ADJACENCY then 
    fcount = v_count / 2 - 4
  end
  stats.frame_vertex_count = stats.frame_vertex_count + v_count
  stats.frame_face_count = stats.frame_face_count + f_count
end

-- h2. Renderer log

--[[--
  @self:log(msg)@ is called by the backend renderer to log message 
  @msg@. Clients can override the function to redirect the renderer 
  log (the default implementation @print@s the message).
--]]--
function lib:log(msg) print(msg) end
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

-- h2. Screen coordinates

--[[--
  @r:normalizeScreenPos(pos [,noflip])@ is the normalized position of 
  @pos@ expressed relative to the top left (bottom left if @noflip@ is true)
  corner of the rendering surface.
--]]--
function lib:normalizeScreenPos(pos, noflip)  
  local np = V2.div (pos, self.size)
  if not noflip then np[2] = 1 - np[2] end
  return np
end

-- h2. Rendering objects 

-- @renderable(cam, o)@ is @true@ if @o@ can be rendered with @cam@.
function lib:isRenderable(cam, o)
  local visible = o.visible == nil or o.visible
  local effect = cam.effect_override or o.effect
  return visible and o.geometry and effect
end

-- @render(cam, objs)@ renders the renderables in @objs@ with @cam@.
function lib:render(cam, objs)
  local now = now () 
  self:_init ()
  self.frame_start_time = now
  self:updateStats(now)
  for _, o in ipairs(objs) do  
    if self:isRenderable(cam, o) and not cam.cull(o) then
      self:addGeometryStats(o.geometry)
      self.r:renderQueueAdd(cam, o)
    end
  end
  self.r:renderQueueFlush(cam)
end
