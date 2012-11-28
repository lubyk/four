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
local Geometry = four.Geometry
local Effect = four.Effect
local V2 = four.V2
local V4 = four.V4
local M4 = four.M4

-- h2. Constructor

-- @RendererGL32(super)@ is a new GL32 renderer, @super@ is a @Renderer@ object.
function lib.new(super)
  local self = 
    {  super = super,
       limits = { max_vertex_attribs = 0 },
       buffers = {},    -- Weakly maps Buffers to their buffer object id
       geometries = {}, -- Weakly maps Geometry object to gl geometry state
       effects = {},    -- Weakly maps Effects to their shader program id
       queue = {},      -- Maps gl programs ids to lists of renderables
       world_to_camera = nil,
       camera_to_clip = nil,
       camera_viewport_origin = nil,
       camera_resolution = nil
    }
    setmetatable(self.buffers, { __mode = "k"})
    setmetatable(self.geometries, { __mode = "k" })
    setmetatable(self.effects, { __mode = "k"})
    setmetatable(self, lib)
    return self
end

local typeGLenum =
  { [Buffer.FLOAT] = lo.GL_FLOAT,
    [Buffer.DOUBLE] = lo.GL_DOUBLE,
    [Buffer.INT] = lo.GL_INT,
    [Buffer.UNSIGNED_INT] = lo.GL_UNSIGNED_INT }

local modeGLenum =
  { [Geometry.POINTS] = lo.GL_POINTS,
    [Geometry.LINE_STRIP] = lo.GL_LINE_STRIP,
    [Geometry.LINE_LOOP] = lo.GL_LINE_LOOP,
    [Geometry.LINES] = lo.GL_LINES,
    [Geometry.LINE_STRIP_ADJACENCY] = lo.GL_LINE_STRIP_ADJACENCY,
    [Geometry.LINES_ADJACENCY] = lo.GL_LINES_ADJACENCY,
    [Geometry.TRIANGLE_STRIP] = lo.GL_TRIANGLE_STRIP,
    [Geometry.TRIANGLE_FAN] = lo.GL_TRIANGLE_FAN,
    [Geometry.TRIANGLES] = lo.GL_TRIANGLES,
    [Geometry.TRIANGLE_STRIP_ADJACENCY] = lo.GL_TRIANGLE_STRIP_ADJACENCY,
    [Geometry.TRIANGLES_ADJACENCY] = lo.GL_TRIANGLES_ADJACENCY }

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

function lib:getGlLimits()
  local geti = gl.hi.glGetIntegerv
  self.limits.max_vertex_attribs = geti(lo.GL_MAX_VERTEX_ATTRIBS)
  self.limits.max_vertex_uniform_comps = 
    geti(lo.GL_MAX_VERTEX_UNIFORM_COMPONENTS )
  self.limits.max_geometry_uniform_comps = 
    geti(lo.GL_MAX_GEOMETRY_UNIFORM_COMPONENTS )
  self.limits.max_fragment_uniform_comps = 
    geti(lo.GL_MAX_FRAGMENT_UNIFORM_COMPONENTS )
  self.limits.max_geometry_output_vertices = 
    geti(lo.GL_MAX_GEOMETRY_OUTPUT_VERTICES)
end

function lib:bufferDataParams(buffer)
  local len = buffer:scalarLength()
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

local bufferSpecForScalarType = 
{ [Buffer.FLOAT] = { byte_count = 4, ffi_spec = "GLfloat[?]" },
  [Buffer.DOUBLE] = { byte_count = 8, ffi_spec = "GLdouble[?]" },
  [Buffer.INT] = { byte_count = 4, ffi_spec = "GLint[?]" },
  [Buffer.UNSIGNED_INT] = { byte_count = 4, ffi_spec = "GLint[?]" }}

function lib:bufferStateAllocate(b, force)
  local function releaseState(state) gl.hi.glDeleteBuffer(state.id) end

  local state = self.buffers[b]
  if state and not force then return state end
  state = { id = gl.hi.glGenBuffer() }
  setmetatable(state, { __gc = releaseState })
  
  local len = b:scalarLength()
  local gltype = typeGLenum[b.scalar_type]
  local spec = bufferSpecForScalarType[b.scalar_type]
  local bytes = spec.byte_count * len
  local data = ffi.new(spec.ffi_spec, len, b.data)
  lo.glBindBuffer(lo.GL_ARRAY_BUFFER, state.id)
  lo.glBufferData(lo.GL_ARRAY_BUFFER, bytes, data, lo.GL_STATIC_DRAW)

  self.buffers[b] = state
  return state
end

function lib:geometryStateAllocate(g)
  local function releaseState(state) gl.hi.glDeleteVertexArray(state.vao) end

  local state = self.geometries[g]
  if state and (g.immutable or not g.dirty) then return state end

  state = { primitive = modeGLenum[g.primitive],
            index_length = g.index:scalarLength (),
            index_scalar_type = typeGLenum[g.index.scalar_type],
            index = nil,    -- g.index buffer object id
            data = {},      -- maps g.data keys to array with all info 
                            -- for binding the buffer object 
            data_loc = {}}  -- maps g.data keys to current binding index
  setmetatable(state, { __gc = releaseState })

  -- Allocate and bind vertex array object
  state.vao = gl.hi.glGenVertexArray ()
  lo.glBindVertexArray(state.vao)

  -- Allocate and bind index buffer
  local index = self:bufferStateAllocate(g.index)
  state.index = index.id
  lo.glBindBuffer(lo.GL_ELEMENT_ARRAY_BUFFER, state.index)
  
  -- Allocate each vertex data buffer.
  for k, buffer in pairs(g.data) do
    local data = self:bufferStateAllocate(buffer)
    local gltype = typeGLenum[buffer.scalar_type]
    state.data[k] = { id = data.id, dim = buffer.dim, scalar_type = gltype, 
                      normalize = buffer.normalize }
    state.data_loc[k] = nil -- never bound yet
  end

  -- Important, unbind *first* the vao and then the index buffer
  lo.glBindVertexArray(0);
  lo.glBindBuffer(lo.GL_ARRAY_BUFFER, 0)
  lo.glBindBuffer(lo.GL_ELEMENT_ARRAY_BUFFER, 0)

  self.geometries[g] = state
  if (g.immutable) then g:disposeBuffers() end
  g.dirty = false
  return state
end 



local typeGLenumIsInt =
  { [lo.GL_FLOAT] = false,
    [lo.GL_DOUBLE] = false,
    [lo.GL_INT] = true,
    [lo.GL_UNSIGNED_INT] = true }
  
function lib:geometryStateBind(gstate, estate)
  lo.glBindVertexArray(gstate.vao)
  for k, loc in pairs(estate.data_locs) do
    if gstate.data_loc[k] ~= loc then  
      -- Program binding doesn't correspond to vao binding, rebind vao.
      local data = gstate.data[k]
      local ints = typeGLenumIsInt[data.scalar_type]
      print(k, loc, data.id)
      lo.glBindBuffer(lo.GL_ARRAY_BUFFER, data.id)
      lo.glEnableVertexAttribArray(loc)
      if ints then
        lo.glVertexAttribIPointer(loc, data.dim, data.scalar_type, 0, nil)
      else
        lo.glVertexAttribPointer(loc, data.dim, data.scalar_type, 
                                 data.normalize, 0, nil)
      end
      gstate.data_loc[k] = loc
      self:logGlError()
    end
  end
end

function lib:rewriteShaderInfoLog(src, log)
  local lines = lk.split(log,'\n')
  for i, l in ipairs(lines) do
    local function rewrite(t, f, l, msg)
      local line = tonumber(l) + src.line - 2
      if line then
        lines[i] = string.format("%s: %s:%d: %s", t, src.file, line, msg)
      end
    end
    string.gsub(l, self.super.error_line_pattern, rewrite)
  end
  return table.concat(lines,'\n')
end

function lib:compileShader(src, type)
  local s = lo.glCreateShader(type)
  gl.hi.glShaderSource(s, src.src)
  lo.glCompileShader(s)
  if gl.hi.glGetShaderiv(s, lo.GL_COMPILE_STATUS) == 0 or self.super.debug 
  then
    local msg = gl.hi.glGetShaderInfoLog(s)
    if msg ~= "" then self:log(self:rewriteShaderInfoLog(src, msg)) end
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

function lib:getSpecialUniform(u, m2w)
  if u.special == Effect.model_to_world then return m2w
  elseif u.special == Effect.world_to_camera then return self.world_to_camera
  elseif u.special == Effect.camera_to_clip then return self.camera_to_clip
  elseif u.special == Effect.model_to_camera then 
    return self.world_to_camera * m2w 
  elseif u.special == Effect.model_to_clip then 
    return self.camera_to_clip * self.world_to_camera * m2w
  elseif u.special == Effect.normals_model_to_camera then
    -- We don't have a M3 type yet. Do it the had-hoc way.
    local m = M4.transpose(M4.inv(self.world_to_camera * m2w))
    local m3 = { m[1], m[2], m[3],    -- fst col
                 m[5], m[6], m[7],    -- snd col
                 m[9], m[10], m[11] } -- trd col
    return m3;
  elseif u.special == Effect.camera_resolution then 
    return self.camera_resolution
  end
end

function lib:effectBindUniforms(m2w, estate, effect)
  for k, u in pairs(effect:getUniforms()) do 
    local v = u.v
    local loc = lo.glGetUniformLocation(estate.program, k)
    if u.special then v = self:getSpecialUniform(u, m2w) end
    if u.dim == 1 then
      if u.scalar_type == Effect.float_scalar or u.scalar_type == Effect.bool_scalar then 
        lo.glUniform1f(loc, v[1])
      elseif u.scalar_type == Effect.int_scalar then 
        lo.glUniform1i(loc, v[1])
      elseif u.scalar_type == Effect.uint_scalar then 
        lo.glUniform1ui(loc, v[1])
      else assert(false) end
    elseif u.dim == 2 then
      if u.scalar_type == Effect.float_scalar or u.scalar_type == Effect.bool_scalar then 
        lo.glUniform2f(loc, v[1], v[2])
      elseif u.scalar_type == Effect.int_scalar then 
        lo.glUniform2i(loc, v[1], v[2])
      elseif u.scalar_type == Effect.uint_scalar then 
        lo.glUniform2ui(loc, v[1], v[2])
      else assert(false) end
    elseif u.dim == 3 then
      if u.scalar_type == Effect.float_scalar or u.scalar_type == Effect.bool_scalar then 
        lo.glUniform3f(loc, v[1], v[2], v[3])
      elseif u.scalar_type == Effect.int_scalar then 
        lo.glUniform3i(loc, v[1], v[2], v[3])
      elseif u.scalar_type == Effect.uint_scalar then 
        lo.glUniform3ui(loc, v[1], v[2], v[3])
      else assert(false) end
    elseif u.dim == 4 then
      if u.scalar_type == Effect.float_scalar or u.scalar_type == Effect.bool_scalar then 
        lo.glUniform4f(loc, v[1], v[2], v[3], v[4])
      elseif u.scalar_type == Effect.int_scalar then 
        lo.glUniform4i(loc, v[1], v[2], v[3], v[4])
      elseif u.scalar_type == Effect.uint_scalar then 
        lo.glUniform4ui(loc, v[1], v[2], v[3], v[4])
      else assert(false) end
    elseif u.dim == 9 then 
      local m = ffi.new("GLfloat[?]", 9, v)
      lo.glUniformMatrix3fv(loc, 1, lo.GL_FALSE, m)
    elseif u.dim == 16 then
      local m = ffi.new("GLfloat[?]", 16, v)
      lo.glUniformMatrix4fv(loc, 1, lo.GL_FALSE, m)
    else assert(false)
    end
  end
end

function lib:effectStateAllocate(effect)
  local function releaseState(state) lo.glDeleteProgram(state.program) end
  local state = self.effects[effect] 
  if state then return state end

  local state = { program = lo.glCreateProgram(), data_locs = {}}
  setmetatable(state, { __gc = releaseState })

  local vsrc = effect:vertexShaderSource() 
  local gsrc = effect:geometryShaderSource()
  local fsrc = effect:fragmentShaderSource()

  local vid = self:compileShader(vsrc, lo.GL_VERTEX_SHADER)
  local gid = gsrc and self:compileShader(gsrc, lo.GL_GEOMETRY_SHADER)
  local fid = self:compileShader(fsrc, lo.GL_FRAGMENT_SHADER)

  lo.glAttachShader(state.program, vid); lo.glDeleteShader(vid)
  if gid then lo.glAttachShader(state.program, gid); lo.glDeleteShader(gid) end
  lo.glAttachShader(state.program, fid); lo.glDeleteShader(fid)
  
  self:linkProgram(state.program)

  for data, _ in pairs(effect.vertex_in) do 
    local loc = lo.glGetAttribLocation(state.program, data)
    state.data_locs[data] = loc
  end

  self.effects[effect] = state
  return state
end

function lib:initFramebuffer(cam)
  -- Setup viewport 
  local wsize = self.super.size 
  local x, y = V2.tuple(self.camera_viewport_origin)
  local w, h = V2.tuple(self.camera_resolution)
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

function lib:setupCameraParameters(cam)
  self.world_to_camera = M4.inv(cam.transform.matrix)
  self.camera_to_clip = cam.projection_matrix
  
  local wsize = self.super.size 
  self.camera_viewport_origin = V2.mul(cam.viewport.origin, wsize)
  self.camera_resolution = V2.mul(cam.viewport.size, wsize)
end

-- Renderer interface implementation

function lib:init()
  self:initGlState()
  self:getGlLimits()
end

function lib:getInfo()
  local get = gl.hi.glGetString
  return { vendor = get(lo.GL_VENDOR),
           renderer = get(lo.GL_RENDERER),
           version = get(lo.GL_VERSION),
           shading_language_version = get(lo.GL_SHADING_LANGUAGE_VERSION),
-- TODO segfaults       extensions = gl.hi.glGetString(lo.GL_EXTENSIONS)
         }
end

function lib:getCaps() return {} end 
function lib:getLimits() return self.limits end 
function lib:renderQueueAdd(cam, o) 
  local effect = cam.effect_override or o.effect
  local estate = self:effectStateAllocate(effect) 
  local gstate = self:geometryStateAllocate(o.geometry) 
  self.queue[effect] = self.queue[effect] or {} 
  table.insert(self.queue[effect], o) 
end

function lib:renderQueueFlush(cam)
  self:setupCameraParameters(cam)
  self:initFramebuffer(cam)
  
  for effect, batch in pairs(self.queue) do
    local estate = self.effects[effect]
    lo.glUseProgram(estate.program)
    for _, o in ipairs(batch) do
      local gstate = self.geometries[o.geometry]
      local m2w = o.transform and o.transform.matrix or M4.id ()
      self:geometryStateBind(gstate, estate)

      -- TODO optimize uniform binding. 
      self:effectBindUniforms(m2w, estate, effect)


      lo.glDrawElements(gstate.primitive, gstate.index_length, 
                        gstate.index_scalar_type, nil)
      lo.glBindVertexArray(0)
    end
  end

  self.queue = {}
  if self.super.debug then self:logGlError() end
end









