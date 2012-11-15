--[[--
  h1. four.RendererGL32
  OpenGL 3.2 / GLSL 1.5 core renderer backend.
  
  *NOTE* Do not use directly, use via @Renderer@.
--]]--

-- Module definition 

local lib = { type = 'four.RendererGL32' }
lib.__index = lib
four.RendererGL32 = lib
setmetatable(lib, { __call = function(lib, ...) return lib.new(...) end })

local ffi = require 'ffi'
local gl = four.gl
local lo = four.gl.lo
local Buffer = four.Buffer
local Effect = four.Effect
local V2 = four.V2
local V4 = four.V4

-- h2. Constructor

-- @RendererGL32(super)@ is a new GL32 renderer, @super@ is a @Renderer@ object.
function lib.new(super)
  local self = 
    {  super = super,
       -- Renderer info
       info = { vendor = "", renderer = "", version = "",
                shading_language_version = "", extensions = "" },
       limits = { max_vertex_attribs = 0 },
       caps = {},
       
       -- GL state internal to the renderer
       geometries = {}, -- Weakly maps Geometry object to the following table
                        -- { vao = id     -- the vertex array buffer id
                        --   bufs = ids } -- array of buffer objects id 
       effects = {},    -- Weakly maps Effects to their shader program id
       queue = {}       -- Maps gl programs ids to lists of renderables
    }
    setmetatable(self.geometries, { __mode = "k" })
    setmetatable(self.effects, { __mode = "k"})
    setmetatable(self, lib)
    return self
end

local typeGLenum = -- TODO remove keep in sync with Buffer.scalar_type values
  { lo.GL_FLOAT,
    lo.GL_DOUBLE,
    lo.GL_INT,
    lo.GL_UNSIGNED_INT }

local modeGLenum = -- TODO remove keep in sync with Geometry.primitive values
{ lo.GL_POINTS,
  lo.GL_LINE_STRIP,
  lo.GL_LINE_LOOP,
  lo.GL_LINES,
  lo.GL_LINE_STRIP_ADJACENCY,
  lo.GL_LINES_ADJACENCY,
  lo.GL_TRIANGLE_STRIP,
  lo.GL_TRIANGLE_FAN,
  lo.GL_TRIANGLES,
  lo.GL_TRIANGLE_STRIP_ADJACENCY,
  lo.GL_TRIANGLES_ADJACENCY,
--  lo.GL_PATCHES 
}

function lib:err_max_vertex_attribs(g)
  local n = g.name or "" 
  return string.format("Geometry %s: too much data per vertex (max is %d)",
                       n, self.limits.max_vertex_attribs)
end

function lib:warn_unused_geom_attrib(g, att)
  local n = g.name or ""
  return string.format("Geometry %s: `%s` per vertex data unused by shader",
                       n, att)
end

local function err_gl(e)
  if e == lo.GL_NO_ERROR then return "no error" 
  elseif e == lo.GL_INVALID_ENUM then return "invalid enum"
  elseif e == lo.GL_INVALID_VALUE then return "invalid value"
  elseif e == lo.GL_INVALID_OPERATION then return "invalid operation"
  elseif e == lo.GL_INVALID_FRAMEBUFFER_OPERATION then 
    return "invalid framebuffer operation"
  elseif e == lo.GL_OUT_OF_MEMORY then 
    return "out of memory"
  else
    return string.format("unknown error %d", e)
  end
end

function lib:log(s) self.super:log(s) end
function lib:dlog(s) if self.super.debug then self.super:log(s) end end
function lib:logGlError()
  local e = lo.glGetError ()
  if e ~= lo.GL_NO_ERROR then self:log("GL error: " .. err_gl(e)) end
end

function lib:initGlState()  
  lo.glDepthFunc(lo.GL_LEQUAL)
  lo.glEnable(lo.GL_DEPTH_TEST)

--  lk.log("TODO enable backface culling")
--  lo.glFrontFace(lo.GL_CCW)
--  lo.glCullFace (lo.GL_BACK)
--  lo.glEnable(lo.GL_CULL_FACE)
  
  lo.glBlendEquation(lo.GL_FUNC_ADD)
  lo.glBlendFunc(lo.GL_SRC_ALPHA, lo.GL_ONE_MINUS_SRC_ALPHA)
  lo.glEnable(lo.GL_BLEND)
end

function lib:getGlInfo()
  local get = gl.hi.glGetString
  self.info.vendor = get(lo.GL_VENDOR)
  self.info.renderer = get(lo.GL_RENDERER)
  self.info.version = get(lo.GL_VERSION)
  self.info.shading_language_version = get(lo.GL_SHADING_LANGUAGE_VERSION)
  -- TODO segfaults 
  -- self._info.extensions = gl.hi.glGetString(lo.GL_EXTENSIONS)
end

function lib:getGlCaps() self.caps = {} end
function lib:getGlLimits()
  local geti = gl.hi.glGetIntegerv
  self.limits.max_vertex_attribs = geti(lo.GL_MAX_VERTEX_ATTRIBS)
end

function lib:bufferDataParams(buffer)
  local len = #buffer.data 
  local data = buffer.data
  local type = buffer.scalar_type 
  local gltype = typeGLenum[type]

  -- TODO better code
  if type == Buffer.FLOAT then 
    return false, gltype, len * 4, ffi.new("GLfloat[?]", len, data)
  elseif type == Buffer.DOUBLE then 
    return false, gltype, len * 8, ffi.new("GLdouble[?]", len, data)
  elseif type == Buffer.INT then 
    return true, gltype, len * 4, ffi.new("GLint[?]", len, data)
  elseif type == Buffer.UNSIGNED_INT then 
    return true, gltype, len * 4, ffi.new("GLuint[?]", len, data)
  else assert(false) end
end

function lib:geometryStateAllocate(g)
  local function releaseState(state)
    gl.hi.glDeleteVertexArray(state.vao)
    gl.hi.glDeleteBuffer(state.index) -- index buffer
    for _, id in pairs(state.data) do gl.hi.glDeleteBuffer(id) end
  end

  local state = self.geometries[g]
  if state and (g.immutable or not g.dirty) then return end

  state = { index_length = g.index:length (),
            index_scalar_type = typeGLenum[g.index.scalar_type],
            index = nil,    -- g.index buffer object id
            data = {},      -- maps g.data keys to buffer object ids
            data_loc = {}}  -- maps g.data keys to binding index

  -- Allocate and bind vertex array object
  state.vao = gl.hi.glGenVertexArray ()
  lo.glBindVertexArray(state.vao)

  -- Allocate and bind index buffer
  local ints, gltype, bytes, data = self:bufferDataParams(g.index)
  state.index = gl.hi.glGenBuffer()
  lo.glBindBuffer(lo.GL_ELEMENT_ARRAY_BUFFER, state.index)
  lo.glBufferData(lo.GL_ELEMENT_ARRAY_BUFFER, bytes, data,
                  lo.GL_STATIC_DRAW)
  assert(lo.glGetError() == 0)  
  -- For each vertex data in g's buffers
  local i = 0
  for k, buffer in pairs(g.data) do
    if i == self.limits.max_vertex_attribs then 
      self:dlog(self:err_max_vertex_attribs(g))
      break
    end

    ints, gltype, bytes, data = self:bufferDataParams(buffer)
    
    -- Allocate and bind vertex buffer
    local buf_id = gl.hi.glGenBuffer()
    state.data[k] = buf_id
    state.data_loc[k] = i
    lo.glBindBuffer(lo.GL_ARRAY_BUFFER, buf_id)
    lo.glBufferData(lo.GL_ARRAY_BUFFER, bytes, data, lo.GL_STATIC_DRAW)

    -- Set as vertex array
    lo.glEnableVertexAttribArray(i)
    if ints then
      lo.glVertexAttribIPointer(i, buffer.dim, gltype, 0, nil)
    else
      lo.glVertexAttribPointer(i, buffer.dim, gltype, buffer.normalize, 0, nil)
    end
    i = i + 1
  end

  -- Important, unbind *first* the vao and then the buffers
  lo.glBindBuffer(lo.GL_ARRAY_BUFFER, 0)
  lo.glBindVertexArray(0);
  lo.glBindBuffer(lo.GL_ELEMENT_ARRAY_BUFFER, 0)

  setmetatable(state, { __gc = releaseState })
  self.geometries[g] = state
  if (g.immutable) then g:disposeBuffers() end
  g.dirty = false
end 

function lib:geometryStateBind(pid, gstate)
  assert(lo.glGetError() == 0)  
  lo.glBindVertexArray(gstate.vao)
  for attr, loc in pairs(gstate.data_loc) do
    lo.glBindAttribLocation(pid, loc, attr)
  end
  assert(lo.glGetError() == 0)  

  -- TODO for now we need to relink the shader due to 
  -- attrib binding we could try to see if in the same
  -- layout holds for successive objects    
  self:linkProgram(pid)
  lo.glUseProgram(pid)
  assert(lo.glGetError() == 0)  
end


function lib:compileShader(src, type)
  local s = lo.glCreateShader(type)
  gl.hi.glShaderSource(s, src)
  lo.glCompileShader(s)
  if gl.hi.glGetShaderiv(s, lo.GL_COMPILE_STATUS) == 0 or self.super.debug 
  then
    local msg = gl.hi.glGetShaderInfoLog(s)
    if msg ~= "" then self:log(msg) end
  end
  return s
end

function lib:linkProgram(pid)
  lo.glLinkProgram(pid)
  if gl.hi.glGetProgramiv(pid, lo.GL_LINK_STATUS) == 0 or self.super.debug 
  then
    local msg = gl.hi.glGetProgramInfoLog(pid)
    if msg ~= "" then self:log(msg) end
  end
end


function lib:effectBindUniforms(pid, effect)
  for k, u in pairs(effect.uniforms) do 
    local v = u.v
    local loc = lo.glGetUniformLocation(pid, k)
    if u.dim == 1 then
      if u.typ == Effect.ft or u.typ == Effect.bt then 
--        lk.log(v[1])
        lo.glUniform1f(loc, v[1])
      elseif u.typ == Effect.it then 
        lo.glUniform1i(loc, v[1])
      elseif u.typ == Effect.ut then 
        lo.glUniform1ui(loc, v[1])
      else assert(false) end
    elseif u.dim == 2 then
      if u.typ == Effect.ft or u.typ == Effect.bt then 
--        lk.log("RES", v[1], v[2])
        lo.glUniform2f(loc, v[1], v[2])
      elseif u.typ == Effect.it then 
        lo.glUniform2i(loc, v[1], v[2])
      elseif u.typ == Effect.ut then 
        lo.glUniform2ui(loc, v[1], v[2])
      else assert(false) end
    elseif u.dim == 3 then
      if u.typ == Effect.ft or u.typ == Effect.bt then 
        lo.glUniform3f(loc, v[1], v[2], v[3])
      elseif u.typ == Effect.it then 
        lo.glUniform3i(loc, v[1], v[2], v[3])
      elseif u.typ == Effect.ut then 
        lo.glUniform3ui(loc, v[1], v[2], v[3])
      else assert(false) end
    elseif u.dim == 4 then
      if u.typ == Effect.ft or u.typ == Effect.bt then 
        lo.glUniform4f(loc, v[1], v[2], v[3], v[4])
      elseif u.typ == Effect.it then 
        lo.glUniform4i(loc, v[1], v[2], v[3], v[4])
      elseif u.typ == Effect.ut then 
        lo.glUniform4ui(loc, v[1], v[2], v[3], v[4])
      else assert(false) end
    elseif u.dim == 16 then
      local m = ffi.new("GLfloat[?]", 16, v)
      lo.glUniformMatrix4fv(loc, 16, false, m)
    else assert(false)
    end
  end
end

function lib:effectStateAllocate(effect)
  local pid = self.effects[effect.id]
  if pid then return pid end

  local vsrc = effect:vertexShader() 
  local gsrc = effect:geometryShader()
  local fsrc = effect:fragmentShader()

  local vid = self:compileShader(vsrc, lo.GL_VERTEX_SHADER)
  local gid = gsrc and self:compileShader(gsrc, lo.GL_GEOMETRY_SHADER)
  local fid = self:compileShader(fsrc, lo.GL_FRAGMENT_SHADER)

  pid = lo.glCreateProgram() -- TODO error handling
  lo.glAttachShader(pid, vid); lo.glDeleteShader(vid)
  if gs then lo.glAttachShader(p, gs); lo.glDeleteShader(gid) end
  lo.glAttachShader(pid, fid); lo.glDeleteShader(fid)
  self:linkProgram(pid)
  self.effects[effect.id] = pid
  -- TODO Effect's finalizer should dispose program
  return pid 
end

function lib:effectDispose(pid) lo.glDeleteProgram(pid) end

function lib:initFramebuffer(cam)
  -- Setup viewport 
  local wsize = self.super.size 
  local x, y = V2.tuple(V2.mul(cam.viewport.origin, wsize))
  local w, h = V2.tuple(V2.mul(cam.viewport.size, wsize))
  lo.glViewport(x, y, w, h) 

  -- Clear buffers 
  local cbits = 0 
  local color = cam.background.color 
  local depth = cam.background.depth
  local stencil = cam.background.sentil 

  if color then 
    local r, g, b, a = V4.tuple(color)
    lo.glClearColor(r, g, b, a)
    cbits = cbits + lo.GL_COLOR_BUFFER_BIT 
  end

  if depth then
    lo.glClearDepth(depth)
    cbits = cbits + lo.GL_DEPTH_BUFFER_BIT
  end

  if stencil then 
    lo.glClearStencil(stencil)
    cbits = cbits + lo.GL_STENCIL_BUFFER_BIT
  end
  
  lo.glClear(cbits)
end

-- Renderer interface implementation

function lib:init()
  self:getGlInfo()
  self:getGlLimits()
  self:getGlCaps()
  self:initGlState()
end

function lib:getInfo() return self.info end
function lib:getCaps() return self.caps end
function lib:getLimits() return self.limits end

function lib:renderQueueAdd(cam, o)
  self:geometryStateAllocate(o.geometry)
  local effect = cam.effect_override or o.effect or cam.effect_default
  local pid = self:effectStateAllocate(o.effect)        
  if pid then
    self.queue[pid] = self.queue[pid] or {} 
    table.insert(self.queue[pid], o)          
  end
end


function lib:renderQueueFlush(cam)
  self:initFramebuffer(cam)
  for pid, batch in pairs(self.queue) do
    lo.glUseProgram(pid)
    for _, o in ipairs(batch) do
      local g = o.geometry
      local gstate = self.geometries[g]
      local effect = o.effect or cam.effect_default

      self:geometryStateBind(pid, gstate)
      self:effectBindUniforms(pid, effect)
      assert(lo.glGetError() == 0)  
      lo.glDrawElements(modeGLenum[g.primitive], gstate.index_length, 
                           gstate.index_scalar_type, nil)
      assert(lo.glGetError() == 0)  
      lo.glBindVertexArray(0)
    end
  end

  self.queue = {}
  if self.super.debug then self:logGlError() end
end









