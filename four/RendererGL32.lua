--[[--
  h1. four.RendererGL32
  OpenGL 3.2 / GLSL 1.5 core renderer backend.
  
  *NOTE* Do not use directly, use via @Renderer@.
--]]--

-- Module definition 
local lub  = require 'lub'
local four = require 'four'
local ffi  = require 'ffi'
local lens = require 'lens'

local lib = lub.class 'four.RendererGL32'

local gl = four.gl
local lo = four.gl.lo
local Buffer = four.Buffer
local Geometry = four.Geometry
local Effect = four.Effect
local Texture = four.Texture
local V2 = four.V2
local V4 = four.V4
local M4 = four.M4

local sm, WeakKey, WeakValue = setmetatable, {__mode = 'k'}, {__mode = 'v'}

-- h2. Constructor

-- @RendererGL32(super)@ is a new GL32 renderer, @super@ is a @Renderer@ object.
function lib.new(super)
  local self = 
    {  super = super,
       limits = { max_vertex_attribs = 0 },
       buffers      = sm({}, WeakKey),   -- Weakly maps Buffers to their gl buffer object id
       geometries   = sm({}, WeakKey),   -- Weakly maps Geometry object to gl geometry state
       effects      = sm({}, WeakKey),   -- Weakly maps Effects to their gl shader program id
       textures     = sm({}, WeakKey),   -- Weakly maps Textures to their gl texture object id
       framebuffers = sm({}, WeakKey),   -- Weakly maps Textures to their gl texture object id
       programs     = sm({}, WeakValue), -- Maps program sources to a weak reference of it program.
       queue = {},    -- Array of maps from effects to lists of renderables
       next_active_texture = 0,
       world_to_camera = nil,
       camera_to_clip = nil,
       camera_viewport_origin = nil,
       camera_resolution = nil
    }
    setmetatable(self, lib)
    return self
end

local typeGLenum =
  { [Buffer.FLOAT] = lo.GL_FLOAT,
    [Buffer.DOUBLE] = lo.GL_DOUBLE,
    [Buffer.INT] = lo.GL_INT,
    [Buffer.UNSIGNED_INT] = lo.GL_UNSIGNED_INT, 
    [Buffer.BYTE] = lo.GL_BYTE, 
    [Buffer.UNSIGNED_BYTE] = lo.GL_UNSIGNED_BYTE
}

local typeGLenumIsInt =
  { [lo.GL_FLOAT] = false,
    [lo.GL_DOUBLE] = false,
    [lo.GL_INT] = true,
    [lo.GL_UNSIGNED_INT] = true,
    [lo.GL_BYTE] = true,
    [lo.GL_UNSIGNED_BYTE] = true }

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

local texTargetGLenum = 
  { [Texture.TYPE_1D] = lo.GL_TEXTURE_1D,
    [Texture.TYPE_2D] = lo.GL_TEXTURE_2D,
    [Texture.TYPE_3D] = lo.GL_TEXTURE_3D,
    [Texture.TYPE_BUFFER] = lo.GL_TEXTURE_BUFFER }

local texFilterGLenum = 
  { [Texture.MIN_NEAREST] = lo.GL_NEAREST,
    [Texture.MIN_LINEAR] = lo.GL_LINEAR,
    [Texture.MIN_NEAREST_MIPMAP_NEAREST] = lo.GL_NEAREST_MIPMAP_NEAREST,
    [Texture.MIN_LINEAR_MIPMAP_NEAREST] = lo.GL_LINEAR_MIPMAP_NEAREST,
    [Texture.MIN_NEAREST_MIPMAP_LINEAR] = lo.GL_NEAREST_MIPMAP_LINEAR,
    [Texture.MIN_LINEAR_MIPMAP_LINEAR] = lo.GL_LINEAR_MIPMAP_LINEAR,
    [Texture.MAG_NEAREST] = lo.GL_NEAREST,
    [Texture.MAG_LINEAR] = lo.GL_LINEAR }

local texWrapGLenum = 
  { [Texture.WRAP_CLAMP_TO_EDGE] = lo.GL_CLAMP_TO_EDGE,
    [Texture.WRAP_REPEAT] = lo.GL_REPEAT }

local texInternalFormatGLenum =
  { [Texture.R_8UN] = lo.GL_R8,
    [Texture.R_32F] = lo.GL_R32F,
    [Texture.RG_8UN] = lo.GL_RG8,
    [Texture.RG_32F] = lo.GL_RG32F,
    [Texture.RGB_8UN] = lo.GL_RGB8,
    [Texture.RGB_32F] = lo.GL_RGB32F,
    [Texture.RGBA_8UN] = lo.GL_RGBA8,
    [Texture.RGBA_32F] = lo.GL_RGBA32F,
    [Texture.SRGB_8UN] = lo.GL_SRGB8_ALPHA8,
    [Texture.SRGBA_8UN] = lo.GL_SRGB8,
    [Texture.DEPTH_24UN] = lo.GL_DEPTH_COMPONENT24,
    [Texture.DEPTH_STENCIL_24UN_8UN] = lo.GL_DEPTH24_STENCIL8,
    [Texture.DEPTH_32F] = lo.GL_DEPTH_COMPONENT32F,
    [Texture.DEPTH_STENCIL_32F_8UN] = lo.GL_DEPTH32F_STENCIL8,
    [Texture.BGRA_8UN] = lo.GL_RGBA8,
  }

local texFormatGLenum =
  { [Texture.R_8UN] = lo.GL_RED,
    [Texture.R_32F] = lo.GL_RED,
    [Texture.RG_8UN] = lo.GL_RG,
    [Texture.RG_32F] = lo.GL_RG,
    [Texture.RGB_8UN] = lo.GL_RGB,
    [Texture.RGB_32F] = lo.GL_RGB,
    [Texture.RGBA_8UN] = lo.GL_RGBA,
    [Texture.RGBA_32F] = lo.GL_RGBA,
    [Texture.SRGB_8UN] = lo.GL_RGB,
    [Texture.SRGBA_8UN] = lo.GL_RGBA,
    [Texture.DEPTH_24UN] = lo.GL_DEPTH_COMPONENT,
    [Texture.DEPTH_STENCIL_24UN_8UN] = lo.GL_DEPTH_STENCIL,
    [Texture.DEPTH_32F] = lo.GL_DEPTH_COMPONENT,
    [Texture.DEPTH_STENCIL_32F_8UN] = lo.GL_DEPTH_STENCIL,
    [Texture.BGRA_8UN] = lo.GL_BGRA,
  }

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
    { kind = samp_kind, dim = 1, unsupported = false, glsl = "sampler1D" },
  [lo.GL_SAMPLER_2D] = 
    { kind = samp_kind, dim = 2, unsupported = false, glsl = "sampler2D" },
  [lo.GL_SAMPLER_3D] = 
    { kind = samp_kind, dim = 3, unsupported = false, glsl = "sampler3D" },
  [lo.GL_SAMPLER_CUBE] = 
    { kind = samp_kind, dim = 3, unsupported = true, glsl = "samplerCube" },
  [lo.GL_SAMPLER_1D_SHADOW] = 
    { kind = samp_kind, dim = 1, unsupported = true, 
      glsl = "sampler1DShadow" },
  [lo.GL_SAMPLER_2D_SHADOW] = 
    { kind = samp_kind, dim = 2, unsupported = true, 
      glsl = "sampler2DShadow" },
  [lo.GL_SAMPLER_1D_ARRAY] = 
    { kind = samp_kind, dim = 1, unsupported = true, 
      glsl = "sampler1DArray" },
  [lo.GL_SAMPLER_2D_ARRAY] = 
    { kind = samp_kind, dim = 2, unsupported = true, 
      glsl = "sampler2DArray" },
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
    { kind = samp_kind, dim = 1, unsupported = false, glsl = "samplerBuffer" },
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
    { kind = samp_kind, dim = 1, unsupported = false, glsl = "isamplerBuffer" },
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
    { kind = samp_kind, dim = 1, unsupported = false, glsl = "usamplerBuffer" },
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

function lib.debug()
  local lob,   glGetError,    GL_NO_ERROR =
        lo, lo.glGetError, lo.GL_NO_ERROR
  local function gldebug(func_name)
    local e = glGetError ()
    local loc = loc or ""
    if e ~= GL_NO_ERROR then
      error(" GL error in '"..func_name.."' " .. err_gl(e))
    end
  end
    
  lo = setmetatable({}, {
    __index = function(_, k)
      local v = lob[k]
      if type(v):match('cdata') then
        return function(...)
          local res = v(...)
          gldebug(k)
          return res
        end
      end
      return lob[k]
    end
  })
end

function lib:log(s) self.super:log(s) end
function lib:dlog(s) if self.super.debug then self.super:log(s) end end
function lib:logGlError(loc)
  local e = lo.glGetError ()
  local loc = loc or ""
  if e ~= lo.GL_NO_ERROR then self:log(loc .. " GL error: " .. err_gl(e)) end
end

function lib:initGlState()  
  lo.glFrontFace(lo.GL_CCW)
  lo.glDisable(lo.GL_CULL_FACE)

  -- TODO move that to blend state or NOT
  lo.glEnable(lo.GL_BLEND)
  lo.glBlendEquation(lo.GL_FUNC_ADD)
  lo.glBlendFunc(lo.GL_SRC_ALPHA, lo.GL_ONE_MINUS_SRC_ALPHA)
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
  [Buffer.UNSIGNED_INT] = { byte_count = 4, ffi_spec = "GLuint[?]" },
  [Buffer.BYTE] = { byte_count = 1, ffi_spec = "GLbyte[?]" }, 
  [Buffer.UNSIGNED_BYTE] = { byte_count = 1, ffi_spec = "GLubyte[?]" } }

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
    state.finalizer = lens.Finalizer(finalize)
    self.buffers[b] = state
  end

  local spec = bufferSpecForScalarType[b.scalar_type]

  local data, len
  local cdata = b.cdata
  if cdata then
    data = cdata()
    len  = b.csize()
  else
    len = b:scalarLength()
    data = ffi.new(spec.ffi_spec, len, b.data)
  end

  local gltype = typeGLenum[b.scalar_type]
  local bytes = spec.byte_count * len
  lo.glBindBuffer(lo.GL_ARRAY_BUFFER, state.id)
  
  -- TODO if we don't change size use glSubBufferData
  lo.glBufferData(lo.GL_ARRAY_BUFFER, bytes, data, 
                  bufferUsageHintType[b.update])
  b.updated = false
  if b.disposable then b:disposeBuffer() end
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
  state.finalizer = lens.Finalizer(finalize)

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

function lib:textureStateAllocate(t)
  local state = self.textures[t]
  local updated = t.updated or (t.data and t.data.updated)
  if state and not updated then return state end
  
  local img = nil
  if state and (t.data and t.data.updated) then 
    img = self:bufferStateAllocate(t.data, true)
    if t.type == Texture.TYPE_BUFFER then 
      -- No need to respecify the buffer
      return state 
    end
  end

  if not state then
    state = { id = gl.hi.glGenTexture() }
    local function finalize () gl.hi.glDeleteTexture(state.id) end
    state.finalizer = lens.Finalizer(finalize)
    self.textures[t] = state
    if t.data then img = self:bufferStateAllocate(t.data, false) end
  end

  lo.glPixelStorei(lo.GL_UNPACK_ALIGNMENT, 1)  
  if img then lo.glBindBuffer(lo.GL_PIXEL_UNPACK_BUFFER, img.id) end
  local target = texTargetGLenum[t.type] 
  local w, h, d = four.V3.tuple(t.size)
  lo.glBindTexture(target, state.id)
  if t.type == Texture.TYPE_1D then 
    lo.glTexParameteri(target, lo.GL_TEXTURE_MAG_FILTER, 
                       texFilterGLenum[t.mag_filter])
    lo.glTexParameteri(target, lo.GL_TEXTURE_MIN_FILTER, 
                       texFilterGLenum[t.min_filter])
    lo.glTexParameteri(target, lo.GL_TEXTURE_WRAP_S, texWrapGLenum[t.wrap_s])
    lo.glTexImage1D(target, 0, texInternalFormatGLenum[t.internal_format],
                    w, 0, texFormatGLenum[t.internal_format], 
                    typeGLenum[t.data.scalar_type], nil)
    if (t.generate_mipmaps) then lo.glGenerateMipmap(target) end
  elseif t.type == Texture.TYPE_2D then 
    lo.glTexParameteri(target, lo.GL_TEXTURE_MAG_FILTER, 
                       texFilterGLenum[t.mag_filter])
    lo.glTexParameteri(target, lo.GL_TEXTURE_MIN_FILTER, 
                       texFilterGLenum[t.min_filter])
    lo.glTexParameteri(target, lo.GL_TEXTURE_WRAP_S, texWrapGLenum[t.wrap_s])
    lo.glTexParameteri(target, lo.GL_TEXTURE_WRAP_T, texWrapGLenum[t.wrap_t])
    local scalar_type
    if t.data then
      scalar_type = typeGLenum[t.data.scalar_type]
    else
      scalar_type = lo.GL_UNSIGNED_BYTE
    end
      
    lo.glTexImage2D(target, 0, texInternalFormatGLenum[t.internal_format],
                    w, h, 0, texFormatGLenum[t.internal_format], 
                    scalar_type, nil)
    if (t.generate_mipmaps) then lo.glGenerateMipmap(target) end
  elseif t.type == Texture.TYPE_3D then 
    lo.glTexParameteri(target, lo.GL_TEXTURE_MAG_FILTER, 
                       texFilterGLenum[t.mag_filter])
    lo.glTexParameteri(target, lo.GL_TEXTURE_MIN_FILTER, 
                       texFilterGLenum[t.min_filter])
    lo.glTexParameteri(target, lo.GL_TEXTURE_WRAP_S, texWrapGLenum[t.wrap_s])
    lo.glTexParameteri(target, lo.GL_TEXTURE_WRAP_T, texWrapGLenum[t.wrap_t])
    lo.glTexParameteri(target, lo.GL_TEXTURE_WRAP_R, texWrapGLenum[t.wrap_r])
    lo.glTexImage3D(target, 0, texInternalFormatGLenum[t.internal_format],
                    w, h, d, 0, texFormatGLenum[t.internal_format], 
                    typeGLenum[t.data.scalar_type], nil)
    if (t.generate_mipmaps) then lo.glGenerateMipmap(target) end
  elseif t.type == Texture.TYPE_BUFFER then 
    lo.glTexBuffer(target,texInternalFormatGLenum[t.internal_format], img.id)
  end
  lo.glBindTexture(target, 0)
  lo.glBindBuffer(lo.GL_PIXEL_UNPACK_BUFFER, 0)
  t.updated = false
  return state
end

function lib:framebufferStateAllocate(t)
  local state = self.framebuffers[t]
  local updated = t.updated
  if state and not updated then return state end
  
  if not state then
    state = { id = gl.hi.glGenFramebuffer() }
    local function finalize() gl.hi.glDeleteFramebuffer(state.id) end
    state.finalizer = lens.Finalizer(finalize)
    self.framebuffers[t] = state
  end

  t.updated = false
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
  local lines = lub.split(log,'\n')
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
    local type = type[0]
    local info = uniformTypeInfo[type]
    local size = size[0]
    if info == nil or info.unsupported then 
      self:log(string.format("Unsupported uniform type: %s", info.glsl))
    else
      if string.find(name, "%[%d%]") == nil then
        assert(size == 1)
        local loc = lo.glGetUniformLocation(p, name)
        pstate.uniforms[name] = { loc = loc, info = info }
      else
        -- Array of uniforms
        local locs = {}
        for i = 1,size do 
          local aname = string.gsub(name, "%d", i - 1)
          locs[i] = lo.glGetUniformLocation(p, aname)
        end
        local n, _ = string.gsub(name, "%[%d%]", "")
        pstate.uniforms[n] = { locs = locs, info = info } 
      end
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
    -- TODO it seems that Lua will sometime call the finalizer while 
    -- state is still available in the weak table self.programs[fullsrc]. 
    -- This may lead another effect to pick it up and use it even though 
    -- it's no longer valid for OpenGL. We therefore clean the weaktable here.
    -- Something seems very broken and rotten (behaviour happens at least 
    -- in Luajit 2.0.0).
    self.programs[fullsrc] = nil
    if state.id ~= -1 then lo.glDeleteProgram(state.id) end
  end
  state.finalizer = lens.Finalizer(finalize) 

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
  elseif u == Effect.WORLD_TO_CLIP then
    return self.camera_to_clip * self.world_to_camera
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
    return self.super.frame_start_time
  end
  return nil
end

local str = string.format
local GLFloatPtr = ffi.typeof("GLfloat [?]")

function lib:effectBindUniforms(effect, estate, cam, o)
  local m2w = o.transform and o.transform.matrix or M4.id ()
  if o.geometry.pre_transform then m2w = m2w * o.geometry.pre_transform end
  
  self.next_active_texture = 0
  for u, uspec in pairs(estate.program.uniforms) do 
    local info = uspec.info
    
    
    -- FIXME: performance issue ?
    -- local uv = effect.uniform(effect, cam, o, u)
    uv = o[u] or cam[u] or effect.default_uniforms[u]

    if uv == nil then
      local name = uspec.locs and str("%s[%d]", u, #uspec.locs) or u
      self:log(str("Uniform value %s %s: not found", info.glsl, name))
    elseif uspec.locs and type(uv) ~= "table" then
      local name = str("%s[%d]", u, #uspec.locs)
      self:log(str("Uniform value %s %s: found %s instead of table", 
                   info.glsl, name, type(uv)))
                     
    elseif uspec.locs and #uv ~= #uspec.locs then 
      local name = str("%s[%d]", u, #uspec.locs)
      self:log(str("Uniform value %s %s: table too short (%d)", 
                   info.glsl, name, #uv))
    else
      local uvals = uspec.locs and uv or { uv }
      local locs = uspec.locs or { uspec.loc } 
      if info.kind == vec_kind then 
        if info.dim == 1 then
          for i, loc in ipairs(locs) do 
            local v = uvals[i]
            if type(v) == "table" and v.special_uniform then 
              v = self:getSpecialUniform(v, m2w)
            end
            info.bind(loc, v)
          end
        elseif info.dim == 2 then 
          for i, loc in ipairs(locs) do 
            local v = uvals[i]
            if type(v) == "table" and v.special_uniform then 
              v = self:getSpecialUniform(v, m2w)
            end
            info.bind(loc, v[1], v[2])
          end
        elseif info.dim == 3 then 
          for i, loc in ipairs(locs) do 
            local v = uvals[i]
            if type(v) == "table" and v.special_uniform then 
              v = self:getSpecialUniform(v, m2w)
            end
            info.bind(loc, v[1], v[2], v[3])
          end
        elseif info.dim == 4 then
          for i, loc in ipairs(locs) do 
            local v = uvals[i]
            if type(v) == "table" and v.special_uniform then 
              v = self:getSpecialUniform(v, m2w)
            end
            info.bind(loc, v[1], v[2], v[3], v[4])
          end
        else assert(false) 
        end
      elseif info.kind == mat_kind then 
        for i, loc in ipairs(locs) do 
          local v = uvals[i]
          if type(v) == "table" and v.special_uniform then 
            v = self:getSpecialUniform(v, m2w)
          elseif v.type == 'four.Transform' then 
            v = v.matrix 
          end
          local m = GLFloatPtr(info.dim, v)
          info.bind(loc, 1, lo.GL_FALSE, m)
        end
      elseif info.kind == samp_kind then 
        for i, loc in ipairs(locs) do 
          local v = uvals[i]
          if type(v) == "table" and v.special_uniform then 
            v = getSpecialUniform(v, m2w)
          end
          local t = self:textureStateAllocate(v)
          lo.glActiveTexture(lo.GL_TEXTURE0 + self.next_active_texture)
          local target = texTargetGLenum[v.type] 
          lo.glBindTexture(target,t.id)
          lo.glUniform1i(loc, self.next_active_texture)
          self.next_active_texture = self.next_active_texture + 1
        end
      end
    end
  end
end

function lib:setupRasterizationState(r)
  if r.cull_face == Effect.CULL_NONE then 
    lo.glDisable(lo.GL_CULL_FACE)
  else 
    lo.glEnable(lo.GL_CULL_FACE)
    if r.cull_face == Effect.CULL_FRONT then 
      lo.glCullFace(lo.GL_FRONT)
    else 
      lo.glCullFace(lo.GL_BACK) 
    end
  end
end

function lib:setupDepthState(d)
  if not d.test then
    lo.glDisable(lo.GL_DEPTH_TEST) 
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

  if d.write then lo.glDepthMask(lo.GL_TRUE) 
  else lo.glDepthMask(lo.GL_FALSE) end
end

function lib:setupEffect(effect, estate)
  local program = estate.program.id
  if program == -1 then return false end

  -- TODO if all these GL calls are too expensive track current state in 
  -- the renderer. Same goes for setupXXState()
  lo.glUseProgram(program)
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
  local stencil = cam.background.stencil 

  if color then 
    local r, g, b, a = V4.tuple(color)
    lo.glClearColor(r, g, b, a)
    cbits = cbits + lo.GL_COLOR_BUFFER_BIT 
  end

  if depth then
    lo.glClearDepth(depth)
    lo.glDepthMask(lo.GL_TRUE) -- if set to lo.GL_FALSE, clearing has no effect.
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

function lib:setupFramebuffer(t)
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
      self.queue[pass] = self.queue[pass] or { opak = {}, nopak = {} } 
      local q = e.opaque and self.queue[pass].opak or self.queue[pass].nopak 
      q[e] = q[e] or {} 
      table.insert(q[e], o)
    else
      for _, ep in ipairs(e) do addPasses(ep) end
    end
  end

  local gstate = self:geometryStateAllocate(o.geometry) 
  local effect = cam.effect_override or o.effect
  addPasses(effect)
end

function lib:renderBatch(cam, effect, batch) 
  local estate = self.effects[effect] 
  if self:setupEffect(effect, estate) then
    for _, o in ipairs(batch) do
      self:effectBindUniforms(effect, estate, cam, o)
      local gstate = self.geometries[o.geometry]
      self:geometryStateBind(gstate, estate)
      if (o.instance_count) then
        lo.glDrawElementsInstanced(gstate.primitive, gstate.index_length,
                                   gstate.index_scalar_type, nil, 
                                   o.instance_count)
      else
        lo.glDrawElements(gstate.primitive, gstate.index_length, 
                          gstate.index_scalar_type, nil)
      end
      lo.glBindVertexArray(0)
    end
  end
end


function lib:renderQueueFlush(cam, framebuffer)
  self:setupCameraParameters(cam)
  if framebuffer then
    local state = self:framebufferStateAllocate(framebuffer)
    lo.glBindFramebuffer(lo.GL_FRAMEBUFFER, state.id)
    local texture = self:textureStateAllocate(framebuffer.texture)
    lo.glFramebufferTexture2D(lo.GL_FRAMEBUFFER, lo.GL_COLOR_ATTACHMENT0, lo.GL_TEXTURE_2D, texture.id, 0)
    self.had_framebuffer = true
  elseif self.had_framebuffer then
    self.had_framebuffer = nil
    -- bind back to screen
    lo.glBindFramebuffer(lo.GL_FRAMEBUFFER, 0)
  end

  self:clearFramebuffer(cam)
  for _, pass in ipairs(self.queue) do 
    for e, batch in pairs(pass.opak) do self:renderBatch(cam, e, batch) end
    for e, batch in pairs(pass.nopak) do self:renderBatch(cam, e, batch) end
  end
  self.queue = {}
  if self.super.debug then self:logGlError() end
end

return lib
