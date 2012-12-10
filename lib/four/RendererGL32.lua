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
       programs = {}, -- Maps program sources to a weak reference of it program.
       queue = {},    -- Array of maps from effects to lists of renderables
       world_to_camera = nil,
       camera_to_clip = nil,
       camera_viewport_origin = nil,
       camera_resolution = nil
    }
    setmetatable(self.buffers, { __mode = "k"})
    setmetatable(self.geometries, { __mode = "k" })
    setmetatable(self.effects, { __mode = "k"})
    setmetatable(self.programs, { __mode = "v"})
    setmetatable(self, lib)
    return self
end

local typeGLenum =
  { [Buffer.FLOAT] = lo.GL_FLOAT,
    [Buffer.DOUBLE] = lo.GL_DOUBLE,
    [Buffer.INT] = lo.GL_INT,
    [Buffer.UNSIGNED_INT] = lo.GL_UNSIGNED_INT }

local typeGLenumIsInt =
  { [lo.GL_FLOAT] = false,
    [lo.GL_DOUBLE] = false,
    [lo.GL_INT] = true,
    [lo.GL_UNSIGNED_INT] = true }

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

local depthFuncGLenum = 
  { [Effect.DEPTH_FUNC_NEVER] = lo.GL_NEVER,
    [Effect.DEPTH_FUNC_LESS] = lo.GL_LESS,
    [Effect.DEPTH_FUNC_EQUAL] = lo.GL_EQUAL,
    [Effect.DEPTH_FUNC_LEQUAL] = lo.GL_LEQUAL,
    [Effect.DEPTH_FUNC_GREATER] = lo.GL_GREATER,
    [Effect.DEPTH_FUNC_NOTEQUAL] = lo.GL_NOTEQUAL,
    [Effect.DEPTH_FUNC_GEQUAL] = lo.GL_GEQUAL,
    [Effect.DEPTH_FUNC_ALWAYS] = lo.GL_ALWAYS }

local vec_kind = 1
local mat_kind = 2
local samp_kind = 3

-- N.B. this includes more types than is allowed in GL 3.2, list taken from
-- GL 4.2. Apparently they don't know about parametric polymorphism.
local uniformTypeInfo = { 
  [lo.GL_FLOAT] = 
    { kind = vec_kind, dim = 1, bind = lo.glUniform1f, glsl = "float" }, 
  [lo.GL_FLOAT_VEC2] = 
    { kind = vec_kind, dim = 2, bind = lo.glUniform2f, glsl = "vec2" }, 
  [lo.GL_FLOAT_VEC3] = 
    { kind = vec_kind, dim = 3, bind = lo.glUniform3f, glsl = "vec3" },
  [lo.GL_FLOAT_VEC4] = 
    { kind = vec_kind, dim = 4, bind = lo.glUniform4f, glsl = "vec4" },
  [lo.GL_DOUBLE] = 
    { kind = vec_kind, dim = 1, unsupported = true, glsl = "double" },
  [lo.GL_DOUBLE_VEC2] = 
    { kind = vec_kind, dim = 2, unsupported = true, glsl = "dvec2" },
  [lo.GL_DOUBLE_VEC3] = 
    { kind = vec_kind, dim = 3, unsupported = true, glsl = "dvec3" },
  [lo.GL_DOUBLE_VEC4] = 
    { kind = vec_kind, dim = 4, unsupported = true, glsl = "dvec4" },
  [lo.GL_INT] = 
    { kind = vec_kind, dim = 1, bind = lo.glUniform1i, glsl = "int" },
  [lo.GL_INT_VEC2] = 
    { kind = vec_kind, dim = 2, bind = lo.glUniform2i, glsl = "ivec2" },
  [lo.GL_INT_VEC3] = 
    { kind = vec_kind, dim = 3, bind = lo.glUniform3i, glsl = "ivec3" },
  [lo.GL_INT_VEC4] = 
    { kind = vec_kind, dim = 4, bind = lo.glUniform4i, glsl = "ivec4" },
  [lo.GL_UNSIGNED_INT] = 
    { kind = vec_kind, dim = 1, bind = lo.glUniform1ui, glsl = "unsigned int" },
  [lo.GL_UNSIGNED_INT_VEC2] = 
    { kind = vec_kind, dim = 2, bind = lo.glUniform2ui, glsl = "uvec2" },
  [lo.GL_UNSIGNED_INT_VEC3] = 
    { kind = vec_kind, dim = 3, bind = lo.glUniform3ui, glsl = "uvec3" },
  [lo.GL_UNSIGNED_INT_VEC4] = 
    { kind = vec_kind, dim = 4, bind = lo.glUniform4ui, glsl = "uvec4" },
  [lo.GL_BOOL] = 
    { kind = vec_kind, dim = 1, bind = lo.glUniform1f, glsl = "bool" },
  [lo.GL_BOOL_VEC2] = 
    { kind = vec_kind, dim = 2, bind = lo.glUniform2f, glsl = "bvec2" },
  [lo.GL_BOOL_VEC3] = 
    { kind = vec_kind, dim = 3, bind = lo.glUniform3f, glsl = "bvec3" },
  [lo.GL_BOOL_VEC4] = 
    { kind = vec_kind, dim = 4, bind = lo.glUniform4f, glsl = "bvec4" },
  [lo.GL_FLOAT_MAT2] = 
    { kind = mat_kind, dim = 4, bind = lo.glUniformMatrix2fv, glsl = "mat2" },
  [lo.GL_FLOAT_MAT3] = 
    { kind = mat_kind, dim = 9, bind = lo.glUniformMatrix3fv, glsl = "mat3" },
  [lo.GL_FLOAT_MAT4] = 
    { kind = mat_kind, dim = 16, bind = lo.glUniformMatrix4fv, glsl = "mat4" },
  [lo.GL_FLOAT_MAT2x3] = 
    { kind = mat_kind, dim = 6, unsupported = true, glsl = "mat2x3" },
  [lo.GL_FLOAT_MAT2x4] = 
    { kind = mat_kind, dim = 8, unsupported = true, glsl = "mat2x4" },
  [lo.GL_FLOAT_MAT3x2] = 
    { kind = mat_kind, dim = 6, unsupported = true, glsl = "mat3x2" },
  [lo.GL_FLOAT_MAT3x4] = 
    { kind = mat_kind, dim = 12, unsupported = true, glsl = "mat3x4" },
  [lo.GL_FLOAT_MAT4x2] = 
    { kind = mat_kind, dim = 8, unsupported = true, glsl = "mat4x2" },
  [lo.GL_FLOAT_MAT4x3] = 
    { kind = mat_kind, dim = 12, unsupported = true, glsl = "mat4x3" },
  [lo.GL_DOUBLE_MAT2] = 
    { kind = mat_kind, dim = 4, unsupported = true, glsl = "dmat2" },
  [lo.GL_DOUBLE_MAT3] = 
    { kind = mat_kind, dim = 9, unsupported = true, glsl = "dmat3" },
  [lo.GL_DOUBLE_MAT4] = 
    { kind = mat_kind, dim = 16, unsupported = true, glsl = "dmat4" },
  [lo.GL_DOUBLE_MAT2x3] = 
    { kind = mat_kind, dim = 6, unsupported = true, glsl = "dmat2x3" },
  [lo.GL_DOUBLE_MAT2x4] = 
    { kind = mat_kind, dim = 8, unsupported = true, glsl = "dmat2x4" },
  [lo.GL_DOUBLE_MAT3x2] = 
    { kind = mat_kind, dim = 6, unsupported = true, glsl = "dmat3x2" },
  [lo.GL_DOUBLE_MAT3x4] = 
    { kind = mat_kind, dim = 12, unsupported = true, glsl = "dmat3x4" },
  [lo.GL_DOUBLE_MAT4x2] = 
    { kind = mat_kind, dim = 8, unsupported = true, glsl = "dmat4x2" },
  [lo.GL_DOUBLE_MAT4x3] = 
    { kind = mat_kind, dim = 12, unsupported = true, glsl = "dmat4x3" },
  [lo.GL_SAMPLER_1D] = 
    { kind = samp_kind, dim = 1, unsupported = true, glsl = "sampler1D" },
  [lo.GL_SAMPLER_2D] = 
    { kind = samp_kind, dim = 2, unsupported = true, glsl = "sampler2D" },
  [lo.GL_SAMPLER_3D] = 
    { kind = samp_kind, dim = 3, unsupported = true, glsl = "sampler3D" },
  [lo.GL_SAMPLER_CUBE] = 
    { kind = samp_kind, dim = 3, unsupported = true, glsl = "samplerCube" },
  [lo.GL_SAMPLER_1D_SHADOW] = 
    { kind = samp_kind, dim = 1, unsupported = true, glsl = "sampler1DShadow" },
  [lo.GL_SAMPLER_2D_SHADOW] = 
    { kind = samp_kind, dim = 2, unsupported = true, glsl = "sampler2DShadow" },
  [lo.GL_SAMPLER_1D_ARRAY] = 
    { kind = samp_kind, dim = 1, unsupported = true, glsl = "sampler1DArray" },
  [lo.GL_SAMPLER_2D_ARRAY] = 
    { kind = samp_kind, dim = 2, unsupported = true, glsl = "sampler2DArray" },
  [lo.GL_SAMPLER_1D_ARRAY_SHADOW] = 
    { kind = samp_kind, dim = 1, unsupported = true, 
      glsl = "sampler1DArrayShadow" },
  [lo.GL_SAMPLER_2D_ARRAY_SHADOW] = 
    { kind = samp_kind, dim = 2, unsupported = true, 
      glsl = "sampler2DArrayShadow" },
  [lo.GL_SAMPLER_2D_MULTISAMPLE] = 
    { kind = samp_kind, dim = 2, unsupported = true, glsl = "sampler2DMS" },
  [lo.GL_SAMPLER_2D_MULTISAMPLE_ARRAY] = 
    { kind = samp_kind, dim = 2, unsupported = true, 
      glsl = "sampler2DMSArray" },
  [lo.GL_SAMPLER_CUBE_SHADOW] = 
    { kind = samp_kind, dim = 3, unsupported = true, 
      glsl = "samplerCubeShadow" },
  [lo.GL_SAMPLER_BUFFER] = 
    { kind = samp_kind, dim = 1, unsupported = true, glsl = "samplerBuffer" },
  [lo.GL_SAMPLER_2D_RECT] = 
    { kind = samp_kind, dim = 2, unsupported = true, glsl = "sampler2DRect" },
  [lo.GL_SAMPLER_2D_RECT_SHADOW] = 
    { kind = samp_kind, dim = 2, unsupported = true, 
      glsl = "sampler2DRectShadow" },
  [lo.GL_INT_SAMPLER_1D] = 
    { kind = samp_kind, dim = 1, unsupported = true, glsl = "isampler1D" },
  [lo.GL_INT_SAMPLER_2D] = 
    { kind = samp_kind, dim = 2, unsupported = true, glsl = "isampler2D" },
  [lo.GL_INT_SAMPLER_3D] = 
    { kind = samp_kind, dim = 3, unsupported = true, glsl = "isampler3D" },
  [lo.GL_INT_SAMPLER_CUBE] = 
    { kind = samp_kind, dim = 3, unsupported = true, glsl = "isamplerCube" },
  [lo.GL_INT_SAMPLER_1D_ARRAY] = 
    { kind = samp_kind, dim = 1, unsupported = true, glsl = "isampler1DArray" },
  [lo.GL_INT_SAMPLER_2D_ARRAY] = 
    { kind = samp_kind, dim = 2, unsupported = true, glsl = "isampler2DArray" },
  [lo.GL_INT_SAMPLER_2D_MULTISAMPLE] = 
    { kind = samp_kind, dim = 2, unsupported = true, glsl = "isampler2DMS" },
  [lo.GL_INT_SAMPLER_2D_MULTISAMPLE_ARRAY] = 
   { kind = samp_kind, dim = 2, unsupported = true, 
     glsl = "isampler2DMSArray" },
  [lo.GL_INT_SAMPLER_BUFFER] = 
    { kind = samp_kind, dim = 1, unsupported = true, glsl = "isamplerBuffer" },
  [lo.GL_INT_SAMPLER_2D_RECT] = 
    { kind = samp_kind, dim = 2, unsupported = true, glsl = "isampler2DRect" },
  [lo.GL_UNSIGNED_INT_SAMPLER_1D] = 
    { kind = samp_kind, dim = 1, unsupported = true, glsl = "usampler1D" },
  [lo.GL_UNSIGNED_INT_SAMPLER_2D] = 
    { kind = samp_kind, dim = 2, unsupported = true, glsl = "usampler2D" },
  [lo.GL_UNSIGNED_INT_SAMPLER_3D] = 
    { kind = samp_kind, dim = 3, unsupported = true, glsl = "usampler3D" },
  [lo.GL_UNSIGNED_INT_SAMPLER_CUBE] = 
    { kind = samp_kind, dim = 3, unsupported = true, glsl = "usamplerCube" },
  [lo.GL_UNSIGNED_INT_SAMPLER_1D_ARRAY] = 
    { kind = samp_kind, dim = 1, unsupported = true, glsl = "usampler2DArray" },
  [lo.GL_UNSIGNED_INT_SAMPLER_2D_ARRAY] = 
    { kind = samp_kind, dim = 2, unsupported = true, glsl = "usampler2DArray" },
  [lo.GL_UNSIGNED_INT_SAMPLER_2D_MULTISAMPLE] = 
    { kind = samp_kind, dim = 2, unsupported = true, glsl = "usampler2DMS" },
  [lo.GL_UNSIGNED_INT_SAMPLER_2D_MULTISAMPLE_ARRAY] = 
    { kind = samp_kind, dim = 2, unsupported = true, 
      glsl = "usampler2DMSArray" },
  [lo.GL_UNSIGNED_INT_SAMPLER_BUFFER] = 
    { kind = samp_kind, dim = 1, unsupported = true, glsl = "usamplerBuffer" },
  [lo.GL_UNSIGNED_INT_SAMPLER_2D_RECT] = 
    { kind = samp_kind, dim = 2, unsupported = true, glsl = "usampler2DRect" },
  [lo.GL_IMAGE_1D] = 
    { kind = samp_kind, dim = 1, unsupported = true, glsl = "image1D" },
  [lo.GL_IMAGE_2D] = 
    { kind = samp_kind, dim = 2, unsupported = true, glsl = "image2D" },
  [lo.GL_IMAGE_3D] = 
    { kind = samp_kind, dim = 3, unsupported = true, glsl = "image3D" },
  [lo.GL_IMAGE_2D_RECT] = 
    { kind = samp_kind, dim = 2, unsupported = true, glsl = "image2DRect" },
  [lo.GL_IMAGE_CUBE] = 
    { kind = samp_kind, dim = 3, unsupported = true, glsl = "imageCube" },
  [lo.GL_IMAGE_BUFFER] = 
    { kind = samp_kind, dim = 1, unsupported = true, glsl = "imageBuffer" },
  [lo.GL_IMAGE_1D_ARRAY] = 
    { kind = samp_kind, dim = 1, unsupported = true, glsl = "image1DArray" },
  [lo.GL_IMAGE_2D_ARRAY] = 
    { kind = samp_kind, dim = 2, unsupported = true, glsl = "image2DArray" },
  [lo.GL_IMAGE_2D_MULTISAMPLE] = 
    { kind = samp_kind, dim = 2, unsupported = true, glsl = "image2DMS" },
  [lo.GL_IMAGE_2D_MULTISAMPLE_ARRAY] = 
    { kind = samp_kind, dim = 2, unsupported = true, glsl = "image2DMSArray" },
  [lo.GL_INT_IMAGE_1D] = 
    { kind = samp_kind, dim = 1, unsupported = true, glsl = "iimage1D" },
  [lo.GL_INT_IMAGE_2D] = 
    { kind = samp_kind, dim = 2, unsupported = true, glsl = "iimage2D" },
  [lo.GL_INT_IMAGE_3D] = 
    { kind = samp_kind, dim = 3, unsupported = true, glsl = "iimage3D" },
  [lo.GL_INT_IMAGE_2D_RECT] = 
    { kind = samp_kind, dim = 2, unsupported = true, glsl = "iimage2DRect" },
  [lo.GL_INT_IMAGE_CUBE] = 
    { kind = samp_kind, dim = 3, unsupported = true, glsl = "iimageCube" },
  [lo.GL_INT_IMAGE_BUFFER] = 
    { kind = samp_kind, dim = 1, unsupported = true, glsl = "iimageBuffer" },
  [lo.GL_INT_IMAGE_1D_ARRAY] = 
    { kind = samp_kind, dim = 1, unsupported = true, glsl = "iimage1DArray" },
  [lo.GL_INT_IMAGE_2D_ARRAY] = 
    { kind = samp_kind, dim = 2, unsupported = true, glsl = "iimage2DArray" },
  [lo.GL_INT_IMAGE_2D_MULTISAMPLE] = 
    { kind = samp_kind, dim = 2, unsupported = true, glsl = "iimage2DMS" },
  [lo.GL_INT_IMAGE_2D_MULTISAMPLE_ARRAY] = 
    { kind = samp_kind, dim = 2, unsupported = true, glsl = "iimage2DMSArray" },
  [lo.GL_UNSIGNED_INT_IMAGE_1D] = 
    { kind = samp_kind, dim = 1, unsupported = true, glsl = "uimage1D" },
  [lo.GL_UNSIGNED_INT_IMAGE_2D] = 
    { kind = samp_kind, dim = 2, unsupported = true, glsl = "uimage2D" },
  [lo.GL_UNSIGNED_INT_IMAGE_3D] = 
    { kind = samp_kind, dim = 3, unsupported = true, glsl = "uimage3D" },
  [lo.GL_UNSIGNED_INT_IMAGE_2D_RECT] = 
    { kind = samp_kind, dim = 3, unsupported = true, glsl = "uimage2DRect" },
  [lo.GL_UNSIGNED_INT_IMAGE_CUBE] = 
    { kind = samp_kind, dim = 3, unsupported = true, glsl = "uimageCube" },
  [lo.GL_UNSIGNED_INT_IMAGE_BUFFER] = 
    { kind = samp_kind, dim = 1, unsupported = true, glsl = "uimageBuffer" },
  [lo.GL_UNSIGNED_INT_IMAGE_1D_ARRAY] = 
    { kind = samp_kind, dim = 1, unsupported = true, glsl = "uimage1DArray" },
  [lo.GL_UNSIGNED_INT_IMAGE_2D_ARRAY] = 
    { kind = samp_kind, dim = 2, unsupported = true, glsl = "uimage2DArray" },
  [lo.GL_UNSIGNED_INT_IMAGE_2D_MULTISAMPLE] = 
    { kind = samp_kind, dim = 2, unsupported = true, glsl = "uimage2DMS" },
  [lo.GL_UNSIGNED_INT_IMAGE_2D_MULTISAMPLE_ARRAY] = 
    { kind = samp_kind, dim = 2, unsupported = true, glsl = "uimage2DMSArray" },
  [lo.GL_UNSIGNED_INT_ATOMIC_COUNTER] = 
    { kind = samp_kind, dim = 1, unsupported = true, glsl = "atomic_uint" }
}

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
function lib:logGlError(loc)
  local e = lo.glGetError ()
  local loc = loc or ""
  if e ~= lo.GL_NO_ERROR then self:log(loc .. " GL error:" .. err_gl(e)) end
end

function lib:initGlState()  
  lo.glFrontFace(lo.GL_CCW)

  -- TODO move that to blend state
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

local bufferSpecForScalarType = 
{ [Buffer.FLOAT] = { byte_count = 4, ffi_spec = "GLfloat[?]" },
  [Buffer.DOUBLE] = { byte_count = 8, ffi_spec = "GLdouble[?]" },
  [Buffer.INT] = { byte_count = 4, ffi_spec = "GLint[?]" },
  [Buffer.UNSIGNED_INT] = { byte_count = 4, ffi_spec = "GLint[?]" }}

local bufferUsageHintType = 
{ [Buffer.UPDATE_NEVER] = lo.GL_STATIC_DRAW,
  [Buffer.UPDATE_SOMETIMES] = lo.GL_DYNAMIC_DRAW,
  [Buffer.UPDATE_OFTEN] = lo.GL_STREAM_DRAW }

function lib:bufferStateAllocate(b, update)
  local state = self.buffers[b]
  if state and not update then return state end

  if not state then 
    state = { id = gl.hi.glGenBuffer() }
    local function finalize () gl.hi.glDeleteBuffer(state.id) end
    state.finalizer = lk.Finalizer(finalize)
    self.buffers[b] = state
  end

  local len = b:scalarLength()
  local gltype = typeGLenum[b.scalar_type]
  local spec = bufferSpecForScalarType[b.scalar_type]
  local bytes = spec.byte_count * len
  local data = ffi.new(spec.ffi_spec, len, b.data)
  lo.glBindBuffer(lo.GL_ARRAY_BUFFER, state.id)
  
  -- TODO if we don't change size use glSubBufferData
  lo.glBufferData(lo.GL_ARRAY_BUFFER, bytes, data, 
                  bufferUsageHintType[b.update])
  assert(lo.glGetError () == lo.GL_NO_ERROR)
  b.updated = false
  return state
end

function lib:geometryStateAllocate(g)
  local state = self.geometries[g]
  if state then
    for k, buffer in pairs(g.data) do 
      if buffer.updated then self:bufferStateAllocate(buffer, true) end
    end
    if g.index.updated then 
      self:bufferStateAllocate(g.index, true) 
      state.index_length = g.index:scalarLength()
    end
    return state 
  end

  state = { vao = gl.hi.glGenVertexArray (),
            primitive = modeGLenum[g.primitive],
            index_length = g.index:scalarLength (),
            index_scalar_type = typeGLenum[g.index.scalar_type],
            index = nil,    -- g.index buffer object id
            data = {},      -- maps g.data keys to array with all info 
                            -- for binding the buffer object 
            data_loc = {}}  -- maps g.data keys to current binding index
  function finalize () gl.hi.glDeleteVertexArray(state.vao) end
  state.finalizer = lk.Finalizer(finalize)

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
  return state
end 
  
function lib:geometryStateBind(gstate, estate)
  lo.glBindVertexArray(gstate.vao)
  for a, aspec in pairs(estate.program.attribs) do
    if gstate.data_loc[a] ~= aspec.loc then 
      -- Program binding doesn't correspond to vao binding, rebind all vao
      -- vertex attributes and leave outer loop.
      for a, aspec in pairs(estate.program.attribs) do
        local data = gstate.data[a]
        if data then
          local ints = typeGLenumIsInt[data.scalar_type]
          local loc = aspec.loc
          lo.glBindBuffer(lo.GL_ARRAY_BUFFER, data.id)
          lo.glEnableVertexAttribArray(loc)
          if ints then
            lo.glVertexAttribIPointer(loc, data.dim, data.scalar_type, 0, nil)
          else
            lo.glVertexAttribPointer(loc, data.dim, data.scalar_type, 
                                     data.normalize, 0, nil)
          end
          gstate.data_loc[a] = loc
        else 
          self:log(string.format("Geometry is missing %s attribute", a))
        end
      end
      break
    end
  end
end

function lib:rewriteShaderInfoLog(src, log)
  local lines = lk.split(log,'\n')
  for i, l in ipairs(lines) do
    local function rewrite(pre, f, post)      
      local file = tonumber(f)
      lines[i] = string.format("%s%s%s", pre, src.files[file], post)
    end
    string.gsub(l, self.super.error_line_pattern, rewrite)
  end
  return table.concat(lines,'\n')
end

function lib:compileShader(src, type)
  local s = lo.glCreateShader(type)
  gl.hi.glShaderSource(s, src.src)
  lo.glCompileShader(s)
  local fail = gl.hi.glGetShaderiv(s, lo.GL_COMPILE_STATUS) == lo.GL_FALSE
  if fail or self.super.debug then
    local msg = gl.hi.glGetShaderInfoLog(s)
    if msg ~= "" then self:log(self:rewriteShaderInfoLog(src, msg)) end
  end
  if fail then lo.glDeleteShader(s) s = -1 end
  return s
end

function lib:linkProgram(pid)
  lo.glLinkProgram(pid)
  local fail = gl.hi.glGetProgramiv(pid, lo.GL_LINK_STATUS) == lo.GL_FALSE
  if fail or self.super.debug 
  then
    local msg = gl.hi.glGetProgramInfoLog(pid)
    if msg ~= "" then self:log(msg) end
  end
  return not fail
end

function lib:setProgramInfo(pstate)
  local p = pstate.id
  local a_name_max = gl.hi.glGetProgramiv(p,lo.GL_ACTIVE_ATTRIBUTE_MAX_LENGTH)
  local u_name_max = gl.hi.glGetProgramiv(p, lo.GL_ACTIVE_UNIFORM_MAX_LENGTH)
  local a_count = gl.hi.glGetProgramiv(p, lo.GL_ACTIVE_ATTRIBUTES)
  local u_count = gl.hi.glGetProgramiv(p, lo.GL_ACTIVE_UNIFORMS)
  local max_len = math.max(a_name_max, u_name_max)
  local s = ffi.new("GLchar [?]", max_len)
  local len = ffi.new("GLsizei [1]", 0)
  local size = ffi.new("GLsizei [1]", 0)
  local type = ffi.new("GLenum [1]", 0)
  
  for loc = 0, a_count - 1, 1 do 
    lo.glGetActiveAttrib(p, loc, max_len, len, size, type, s)
    local name = ffi.string (s, len[0])
    pstate.attribs[name] = { loc = loc, type = type[0], size = size[0] } 
  end
  
  for i = 0, u_count - 1, 1 do 
    lo.glGetActiveUniform(p, i, max_len, len, size, type, s)
    local name = ffi.string (s, len[0])
    local type_info = uniformTypeInfo[type[0]]
    if type_info.unsupported then 
      self:log(string.format("Unsupported uniform type: %s", type_info.glsl))
    else
      local loc = lo.glGetUniformLocation(p, name)
      pstate.uniforms[name] = { loc = loc, type = type[0], size = size[0] }
    end
  end
end

local glslPreamble = "#version 150 core"

function lib:programStateAllocate(effect)
  local vsrc = effect:vertexShaderSource(glslPreamble) 
  local gsrc = effect:geometryShaderSource(glslPreamble)
  local fsrc = effect:fragmentShaderSource(glslPreamble)
  local fullsrc = vsrc.src .. (gsrc and gsrc.src or "") .. fsrc.src
  local state = self.programs[fullsrc]
  if state then return state end
  
  local state = { id = -1,
                  attribs = {},  -- maps active attrib names to loc/type/siz
                  uniforms = {}} -- maps active uniform names to loc/type/siz
  local function finalize () 
    if state.id ~= -1 then lo.glDeleteProgram(state.id) end
  end
  state.finalizer = lk.Finalizer(finalize) 

  -- Compile and link program
  local vid = self:compileShader(vsrc, lo.GL_VERTEX_SHADER)
  local gid = gsrc and self:compileShader(gsrc, lo.GL_GEOMETRY_SHADER)
  local fid = self:compileShader(fsrc, lo.GL_FRAGMENT_SHADER)

  if vid ~= -1 and (gid == nil or gid ~= -1) and fid ~= -1 then
    local p = lo.glCreateProgram()
    lo.glAttachShader(p, vid); lo.glDeleteShader(vid)
    if gid then lo.glAttachShader(p, gid); lo.glDeleteShader(gid) end
    lo.glAttachShader(p, fid); lo.glDeleteShader(fid)
    if not self:linkProgram(p) then lo.glDeleteProgram(p) 
    else
      state.id = p
      self:setProgramInfo(state)
    end 
  end

  self.programs[fullsrc] = state
  return state
end

function lib:effectStateAllocate(effect)
  local state = self.effects[effect]
  if state and not effect.program_changed then return state end

  local state = { program = self:programStateAllocate(effect) }
  effect.program_changed = false
  self.effects[effect] = state
  return state
end

function lib:getSpecialUniform(u, m2w)
  if u == Effect.MODEL_TO_WORLD then 
    return m2w
  elseif u == Effect.MODEL_TO_CAMERA then 
    return self.world_to_camera * m2w 
  elseif u == Effect.MODEL_TO_CLIP then 
    return self.camera_to_clip * self.world_to_camera * m2w
  elseif u == Effect.WORLD_TO_CAMERA then 
    return self.world_to_camera
  elseif u == Effect.CAMERA_TO_CLIP then 
    return self.camera_to_clip
  elseif u == Effect.MODEL_NORMAL_TO_CAMERA then
    -- We don't have a M3 type yet. Do it the had-hoc here.
    local m = M4.transpose(M4.inv(self.world_to_camera * m2w))
    local m3 = { m[1], m[2], m[3],    -- fst col
                 m[5], m[6], m[7],    -- snd col
                 m[9], m[10], m[11] } -- trd col
    return m3
  elseif u == Effect.CAMERA_RESOLUTION then 
    return self.camera_resolution
  elseif u == Effect.RENDER_FRAME_START_TIME then 
    return { self.super.frame_start_time }
  end
  return nil
end

function lib:effectBindUniforms(effect, estate, cam, o)
  local m2w = o.transform and o.transform.matrix or M4.id ()
  if o.geometry.pre_transform then
    m2w = m2w * o.geometry.pre_transform 
  end
  
  for u, uspec in pairs(estate.program.uniforms) do 
    local loc = uspec.loc
    local info = uniformTypeInfo[uspec.type]
    local v = effect.uniform(cam, o, u)
    if v == nil then v = effect.default_uniforms[u] end
    
    -- TODO do we do type checks here 
    local vt = type(v)
    if vt == "boolean" then v = { v and 1 or 0 } 
    elseif vt == "number" then v = { v } 
    elseif vt == "table" then 
      if v.special_uniform then v = self:getSpecialUniform(v, m2w) end
    end
    
    if not v then 
      self:log(string.format("No value found for uniform: %s %s", info.glsl, u))
    elseif uspec.size ~= 1 then
      self:log(string.format("Uniform arrays unsupported yet (%s)", u))
    else
      if info.kind == vec_kind then 
        if info.dim == 1 then info.bind(loc, v[1])
        elseif info.dim == 2 then info.bind(loc, v[1], v[2])
        elseif info.dim == 3 then info.bind(loc, v[1], v[2], v[3])
        elseif info.dim == 4 then info.bind(loc, v[1], v[2], v[3], v[4])
        end
      elseif info.kind == mat_kind then 
        local m = ffi.new("GLfloat [?]", info.dim, v) 
        info.bind(loc, 1, lo.GL_FALSE, m)
      elseif info.kind == samp_kind then 
        -- TODO
      end
    end 
  end
end

function lib:setupRasterizationState(r)
  if r.cull_face == Effect.CULL_NONE then 
    lo.glDisable(lo.GL_CULL_FACE)
  else 
    lo.glEnable(lo.GL_CULL_FACE)
    if r.cull_face == Effect.CULL_FRONT then lo.glCullFace(lo.GL_FRONT)
    else lo.glCullFace(lo.GL_BACK) end
  end
end

function lib:setupDepthState(d)
  if not d.enable then lo.glDisable(lo.GL_DEPTH_TEST) 
  else 
    lo.glEnable(lo.GL_DEPTH_TEST)
    lo.glDepthFunc(depthFuncGLenum[d.func])
    if d.offset.factor == 0 and d.offset.units == 0 then 
      lo.glDisable(lo.GL_POLYGON_OFFSET_FILL)
    else
      lo.glEnable(lo.GL_POLYGON_OFFSET_FILL)
      lo.glPolygonOffset(d.offset.factor, d.offset.units)
    end
  end
end

function lib:setupEffect(effect, estate, current_program)
  local program = estate.program.id
  if program == -1 then return false end
  if program ~= current_program then lo.glUseProgram(program) end

  -- FIXME if all these GL calls are too expensive track current state in 
  -- the renderer.
  self:setupRasterizationState(effect.rasterization)
  self:setupDepthState(effect.depth)
  return true
end

function lib:clearFramebuffer(cam)
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
  local pass = 0
  local addPasses
  addPasses = function(e) 
    if e.type and e.type == 'four.Effect' then 
      local estate = self:effectStateAllocate(e) 
      pass = pass + 1
      self.queue[pass] = self.queue[pass] or {} 
      self.queue[pass][e] = self.queue[pass][e] or {}
      table.insert(self.queue[pass][e], o)
    else
      for _, ep in ipairs(e) do addPasses(ep) end
    end
  end

  local gstate = self:geometryStateAllocate(o.geometry) 
  local effect = cam.effect_override or o.effect
  addPasses(effect)
end

function lib:renderQueueFlush(cam)
  self:setupCameraParameters(cam)
  self:clearFramebuffer(cam)
  local current_program = -1
  for _, pass in ipairs(self.queue) do 
    for effect, batch in pairs(pass) do
      local estate = self.effects[effect] 
      if self:setupEffect(effect, estate, current_program) then  
        current_program = estate.program.id
        for _, o in ipairs(batch) do
          self:effectBindUniforms(effect, estate, cam, o)
          local gstate = self.geometries[o.geometry]
          self:geometryStateBind(gstate, estate)
          lo.glDrawElements(gstate.primitive, gstate.index_length, 
                            gstate.index_scalar_type, nil)
          lo.glBindVertexArray(0)
        end
      end
    end
  end

  self.queue = {}
  if self.super.debug then self:logGlError() end
end
