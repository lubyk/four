--[[--
  # four.RendererGL32
  OpenGL 3.2 / GLSL 1.5 core renderer.
  
  NOTE. Do not use directly use via Renderer.lua.
--]]--

-- Module definition 

local lib = { type = 'four.RendererGL32' }
lib.__index = lib
four.RendererGL32 = lib
setmetatable(lib, { __call = function(lib, ...) return lib.new(...) end })

local ffi = require 'ffi'
local gl = four.gl
-- local lo = four.gl.lo
local Buffer = four.Buffer
local Effect = four.Effect
local V2 = four.V2
local V4 = four.V4

-- Constructor

function lib.new(super)
  local self = 
    {  super = super,
       -- Renderer info
       info = { vendor = "", renderer = "", version = "",
                shading_language_version = "", extensions = "" },
       limits = { max_vertex_attribs = 0 },
       caps = {},
       
       -- GL state internal to the renderer
       geometries = {}, -- Maps Geometry.id to the following table
                        -- { vao = id     -- the vertex array buffer id
                        --   bufs = ids } -- array of buffer objects id 
       effects = {},    -- Maps Effects.ids to their shader program id
       queue = {}       -- Maps gl programs ids to lists of renderables
    }
    setmetatable(self, lib)
    return self
end

local typeGLenum = -- Warning keep in sync with Buffer.scalar_type values
  { gl.lo.GL_FLOAT,
    gl.lo.GL_DOUBLE,
    gl.lo.GL_INT,
    gl.lo.GL_UNSIGNED_INT }

local modeGLenum = -- Warning keep in sync with Geometry.primitive values
{ gl.lo.GL_POINTS,
  gl.lo.GL_LINE_STRIP,
  gl.lo.GL_LINE_LOOP,
  gl.lo.GL_LINES,
  gl.lo.GL_LINE_STRIP_ADJACENCY,
  gl.lo.GL_LINES_ADJACENCY,
  gl.lo.GL_TRIANGLE_STRIP,
  gl.lo.GL_TRIANGLE_FAN,
  gl.lo.GL_TRIANGLES,
  gl.lo.GL_TRIANGLE_STRIP_ADJACENCY,
  gl.lo.GL_TRIANGLES_ADJACENCY,
--  gl.lo.GL_PATCHES 
}

local function err_max_vertex_attribs(g)
  return string.format("Geometry %d: too much data per vertex for renderer",
                       g.id)
end

local function err_gl(e)
  if e == gl.lo.GL_NO_ERROR then return "no error" 
  elseif e == gl.lo.GL_INVALID_ENUM then return "invalid enum"
  elseif e == gl.lo.GL_INVALID_VALUE then return "invalid value"
  elseif e == gl.lo.GL_INVALID_OPERATION then return "invalid operation"
  elseif e == gl.lo.GL_INVALID_FRAMEBUFFER_OPERATION then 
    return "invalid framebuffer operation"
  elseif e == gl.lo.GL_OUT_OF_MEMORY then 
    return "out of memory"
  else
    return string.format("unknown error %d", e)
  end
end

function lib:log(s) self.super:log(s) end
function lib:dlog(s) if self.super.debug then self.super:log(s) end end
function lib:logGlError()
  local e = gl.lo.glGetError ()
  if e ~= gl.lo.GL_NO_ERROR then self:log("GL error: " .. err_gl(e)) end
end

function lib:initGlState()  
  gl.lo.glDepthFunc(gl.lo.GL_LEQUAL)
  gl.lo.glEnable(gl.lo.GL_DEPTH_TEST)

--  lk.log("TODO enable backface culling")
--  gl.lo.glFrontFace(gl.lo.GL_CCW)
--  gl.lo.glCullFace (gl.lo.GL_BACK)
--  gl.lo.glEnable(gl.lo.GL_CULL_FACE)
  
  gl.lo.glBlendEquation(gl.lo.GL_FUNC_ADD)
  gl.lo.glBlendFunc(gl.lo.GL_SRC_ALPHA, gl.lo.GL_ONE_MINUS_SRC_ALPHA)
  gl.lo.glEnable(gl.lo.GL_BLEND)
end

function lib:getGlInfo()
  local get = gl.hi.glGetString
  self.info.vendor = get(gl.lo.GL_VENDOR)
  self.info.renderer = get(gl.lo.GL_RENDERER)
  self.info.version = get(gl.lo.GL_VERSION)
  self.info.shading_language_version = get(gl.lo.GL_SHADING_LANGUAGE_VERSION)
  -- TODO segfaults 
  -- self._info.extensions = gl.hi.glGetString(gl.lo.GL_EXTENSIONS)
end

function lib:getGlCaps() self.caps = {} end
function lib:getGlLimits()
  local geti = gl.hi.glGetIntegerv
  self.limits.max_vertex_attribs = geti(gl.lo.GL_MAX_VERTEX_ATTRIBS)
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

function lib:geometryAllocate(geom)
  local state = self.geometries[geom.id]
  if state and (geom.immutable or not geom.dirty) then return end
  if state then self:geometryDispose(state) end

  state = { bufs = {}}

  -- Allocate and bind vertex array object
  state.vao = gl.hi.glGenVertexArray ()
  gl.lo.glBindVertexArray(state.vao)

  -- Allocate and bind index buffer
  local ints, gltype, bytes, data = self:bufferDataParams(geom.indices)
  state.bufs[0] = gl.hi.glGenBuffer()
  gl.lo.glBindBuffer(gl.lo.GL_ELEMENT_ARRAY_BUFFER, state.bufs[0])
  gl.lo.glBufferData(gl.lo.GL_ELEMENT_ARRAY_BUFFER, bytes, data, 
                     gl.lo.GL_STATIC_DRAW)
  
  -- For each vertex data in geom's buffers
  for i, buffer in ipairs(geom.data) do
    if i > self.limits.max_vertex_attribs then 
      self:dlog(err_max_vertex_attribs(g))
      break
    end

    ints, gltype, bytes, data = self:bufferDataParams(buffer)
    
    -- Allocate and bind vertex buffer
    state.bufs[i] = gl.hi.glGenBuffer()
    gl.lo.glBindBuffer(gl.lo.GL_ARRAY_BUFFER, state.bufs[i])
    gl.lo.glBufferData(gl.lo.GL_ARRAY_BUFFER, bytes, data, gl.lo.GL_STATIC_DRAW)

    -- Set as vertex array
    gl.lo.glEnableVertexAttribArray(i - 1)
    if ints then 
      gl.lo.glVertexAttribIPointer(i - 1, buffer.dim, gltype, 0, nil)
    else
      gl.lo.glVertexAttribPointer(i - 1, buffer.dim, gltype, 
                                  buffer.normalize,
                                  0, nil)
    end
  end

  -- Important, unbind *first* the vao and then the buffers
  gl.lo.glBindBuffer(gl.lo.GL_ARRAY_BUFFER, 0)
  gl.lo.glBindVertexArray(0);
  gl.lo.glBindBuffer(gl.lo.GL_ELEMENT_ARRAY_BUFFER, 0)

  self.geometries[geom.id] = state
  if (geom.immutable) then geom:disposeBuffers() end
  geom.dirty = false
  -- TODO geom's finalizer should call _glGeometryDispose
end 

function lib:geometryDispose(state)
  gl.hi.glDeleteVertexArray(state.vao)
  gl.hi.glDeleteBuffer(state.bufs[0]) -- index buffer
  for _, id in ipairs(state.bufs) do gl.hi.glDeleteBuffer(state.id) end
  state = { bufs = {}}
end

function lib:compileShader(src, type)
  local s = gl.lo.glCreateShader(type)
  gl.hi.glShaderSource(s, src)
  gl.lo.glCompileShader(s)
  if gl.hi.glGetShaderiv(s, gl.lo.GL_COMPILE_STATUS) == 0 or self.super.debug 
  then
    local msg = gl.hi.glGetShaderInfoLog(s)
    if msg ~= "" then self:log(msg) end
  end
  return s
end

function lib:linkProgram(pid)
  gl.lo.glLinkProgram(pid)
  if gl.hi.glGetProgramiv(pid, gl.lo.GL_LINK_STATUS) == 0 or self.super.debug 
  then
    local msg = gl.hi.glGetProgramInfoLog(pid)
    if msg ~= "" then self:log(msg) end
  end
end

function lib:effectBindUniforms(pid, effect)
  for k, u in pairs(effect.uniforms) do 
    local v = u.v
    local loc = gl.lo.glGetUniformLocation(pid, k)
    if u.dim == 1 then
      if u.typ == Effect.ft or u.typ == Effect.bt then 
--        lk.log(v[1])
        gl.lo.glUniform1f(loc, v[1])
      elseif u.typ == Effect.it then 
        gl.lo.glUniform1i(loc, v[1])
      elseif u.typ == Effect.ut then 
        gl.lo.glUniform1ui(loc, v[1])
      else assert(false) end
    elseif u.dim == 2 then
      if u.typ == Effect.ft or u.typ == Effect.bt then 
--        lk.log("RES", v[1], v[2])
        gl.lo.glUniform2f(loc, v[1], v[2])
      elseif u.typ == Effect.it then 
        gl.lo.glUniform2i(loc, v[1], v[2])
      elseif u.typ == Effect.ut then 
        gl.lo.glUniform2ui(loc, v[1], v[2])
      else assert(false) end
    elseif u.dim == 3 then
      if u.typ == Effect.ft or u.typ == Effect.bt then 
        gl.lo.glUniform3f(loc, v[1], v[2], v[3])
      elseif u.typ == Effect.it then 
        gl.lo.glUniform3i(loc, v[1], v[2], v[3])
      elseif u.typ == Effect.ut then 
        gl.lo.glUniform3ui(loc, v[1], v[2], v[3])
      else assert(false) end
    elseif u.dim == 4 then
      if u.typ == Effect.ft or u.typ == Effect.bt then 
        gl.lo.glUniform4f(loc, v[1], v[2], v[3], v[4])
      elseif u.typ == Effect.it then 
        gl.lo.glUniform4i(loc, v[1], v[2], v[3], v[4])
      elseif u.typ == Effect.ut then 
        gl.lo.glUniform4ui(loc, v[1], v[2], v[3], v[4])
      else assert(false) end
    elseif u.dim == 16 then
      local m = ffi.new("GLfloat[?]", 16, v)
      gl.lo.glUniformMatrix4fv(loc, 16, false, m)
    else assert(false)
    end
  end
end

function lib:effectAllocate(effect)
  local pid = self.effects[effect.id]
  if pid then return pid end

  local vsrc = effect:vertexShader() 
  local gsrc = effect:geometryShader()
  local fsrc = effect:fragmentShader()

  local vid = self:compileShader(vsrc, gl.lo.GL_VERTEX_SHADER)
  local gid = gsrc and self:compileShader(gsrc, gl.lo.GL_GEOMETRY_SHADER)
  local fid = self:compileShader(fsrc, gl.lo.GL_FRAGMENT_SHADER)

  pid = gl.lo.glCreateProgram()
  gl.lo.glAttachShader(pid, vid); gl.lo.glDeleteShader(vid)
  if gs then gl.lo.glAttachShader(p, gs); gl.lo.glDeleteShader(gid) end
  gl.lo.glAttachShader(pid, fid); gl.lo.glDeleteShader(fid)
  self:linkProgram(pid)
  self.effects[effect.id] = pid
  -- TODO Effect's finalizer should dispose program
  return pid 
end

function lib:effectDispose(pid) gl.lo.glDeleteProgram(pid) end

function lib:initFramebuffer(cam)
  -- Setup viewport 
  local wsize = self.super.size 
  local x, y = V2.tuple(V2.mul(cam.viewport.origin, wsize))
  local w, h = V2.tuple(V2.mul(cam.viewport.size, wsize))
  gl.lo.glViewport(x, y, w, h) 

  -- Clear buffers 
  local cbits = 0 
  local color = cam.background.color 
  local depth = cam.background.depth
  local stencil = cam.background.sentil 

  if color then 
    local r, g, b, a = V4.tuple(color)
    gl.lo.glClearColor(r, g, b, a)
    cbits = cbits + gl.lo.GL_COLOR_BUFFER_BIT 
  end

  if depth then
    gl.lo.glClearDepth(depth)
    cbits = cbits + gl.lo.GL_DEPTH_BUFFER_BIT
  end

  if stencil then 
    gl.lo.glClearStencil(stencil)
    cbits = cbits + gl.lo.GL_STENCIL_BUFFER_BIT
  end
  
  gl.lo.glClear(cbits)
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
  self:geometryAllocate(o.geometry)

  local effect = cam.effect_override or o.effect or cam.effect_default
  local pid = self:effectAllocate(o.effect)        
  if pid then
    self.queue[pid] = self.queue[pid] or {} 
    table.insert(self.queue[pid], o)          
  end
end

function lib:renderQueueFlush(cam)
  self:initFramebuffer(cam)
  for pid, batch in pairs(self.queue) do
    for _, o in ipairs(batch) do
      local geom = o.geometry
      local effect = o.effect or cam.effect_default
      local vao = self.geometries[geom.id].vao
      gl.lo.glBindVertexArray(vao)
      for attr, i in pairs(o.geometry.semantics) do
        gl.lo.glBindAttribLocation(pid, i - 1, attr)
      end
      -- TODO for now we need to relink the shader due to 
      -- attrib binding we could try to see if in the same
      -- layout holds for successive objects    
      self:linkProgram(pid)
      gl.lo.glUseProgram(pid)
      self:effectBindUniforms(pid, effect)
      
      gl.lo.glDrawElements(modeGLenum[geom.primitive], geom:indicesCount(),
                           typeGLenum[geom:indicesScalarType()], nil)
      gl.lo.glBindVertexArray(0)
    end
  end

  self.queue = {}
  if self.super.debug then self:logGlError() end
end









