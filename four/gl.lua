--[[--
  h1. four.gl
  Luajit bindings to OpenGL.
--]]--
local four = require 'four'
local ffi  = require 'ffi'

local libs = 
  { OSX = { x86 = "OpenGL.framework/OpenGL", x64 = "OpenGL.framework/OpenGL" },
    Windows = { x86 = "OPENGL32.DLL", x64 = "OPENGL32.DLL" },
    Linux = { x86 = "libGL.so", x64 = "libGL.so", arm = "libGL.so" },
    BSD = { x86 = "libGL.so", x64 = "libGL.so" },
    POSIX = { x86 = "libGL.so", x64 = "libGL.so" },
    Other = { x86 = "libGL.so", x64 = "libGL.so" }}
  
local lo_lib = libs[ffi.os][ffi.arch]
local lo = ffi.load(lo_lib)
local hi = {}

local lib = { lo = lo, hi = hi }

-- hi, sligthly higher level interface to gl for some calls.

function hi.glGetBooleanv(pname)
  local param = ffi.new ("GLboolean[1]", 0)
  lo.glGetBooleanv(pname, param)
  return (param[0] == 1)
end

function hi.glGetDoublev(pname)
  local param = ffi.new ("GLdouble[1]", 0)
  lo.glGetDoublev(pname, param)
  return param[0]
end

function hi.glGetFloatv(pname)
  local param = ffi.new ("GLfloat[1]", 0)
  lo.glGetDoublev(pname, param)
  return param[0]
end

function hi.glGetIntegerv(pname)
  local param = ffi.new ("GLint[1]", 0)
  lo.glGetIntegerv(pname, param)
  return param[0]
end

function hi.glGetString(pname)
  local ptr = lo.glGetString(pname)
  if ptr == 0 then return "" else return ffi.string(ptr) end
end

function hi.glGetShaderiv (s, flag)
  local flag_v = ffi.new ("GLint[1]", 0)
  lo.glGetShaderiv (s, flag, flag_v);
  return flag_v[0]
end

function hi.glShaderSource (s, src)
   -- TODO check ffi.cast and C null terminated string stuff
  local arr = ffi.new ("const GLchar *[1]", ffi.cast ("GLchar *", src)) 
  lo.glShaderSource (s, 1, arr, nil)
end

function hi.glGetShaderInfoLog (s)
  local len = hi.glGetShaderiv (s, lo.GL_INFO_LOG_LENGTH)
  if (len == 0) then return ""
  else
    local log = ffi.new("GLchar [?]", len)
    lo.glGetShaderInfoLog (s, len, nil, log)
    return ffi.string (log, len - 1)
  end
end

function hi.glGetProgramiv (s, flag)
  local flag_v = ffi.new ("GLint[1]", 0)
  lo.glGetProgramiv (s, flag, flag_v);
  return flag_v[0]
end

function hi.glGetProgramInfoLog (s)
  local len = hi.glGetProgramiv (s, lo.GL_INFO_LOG_LENGTH)
  if (len == 0) then return ""
  else
    local log = ffi.new("GLchar [?]", len)
    lo.glGetProgramInfoLog (s, len, nil, log)
    return ffi.string (log, len - 1)
  end
end

function hi.glGenBuffer()
  local id = ffi.new ("GLuint[1]", 0)
  lo.glGenBuffers(1, id)
  return id[0]
end

function hi.glDeleteBuffer(id)
  local idptr = ffi.new("GLuint[1]", id)
  lo.glDeleteBuffers(1, idptr)
end

function hi.glGenVertexArray()
  local id = ffi.new ("GLuint[1]", 0)
  lo.glGenVertexArrays(1, id)
  return id[0]
end

function hi.glDeleteVertexArray(id)
  local idptr = ffi.new("GLuint[1]", id)
  lo.glDeleteVertexArrays(1, idptr)
end

function hi.glGenTexture()
  local id = ffi.new("GLuint[1]", 0) 
  lo.glGenTextures(1, id)
  return id[0]
end

function hi.glDeleteTexture(id)
  local idptr = ffi.new("GLuint[1]", id) 
  lo.glDeleteTextures(1, idptr)
end

function hi.glGenFramebuffer()
  local id = ffi.new("GLuint[1]", 0) 
  lo.glGenFramebuffers(1, id)
  return id[0]
end

function hi.glDeleteFramebuffer(id)
  local idptr = ffi.new("GLuint[1]", id) 
  lo.glDeleteFramebuffers(1, idptr)
end

-- lo, raw bindings to OpenGL

--[[--
  This was obtained from glcorearb.h version 2012/08/06, mostly via :
  
  s/^#ifndef.*$//
  s/^#ifdef.*$//
  s/^#endif.*$//
  s/^#define +\([^ ]+\) +\([^ ]+\) *$/static const GLenum \1 = \2;/
  s/GLAPI //s
  s/APIENTRY //s
  s/.*APIENTRYP.*\n//s

  and a few manual ajdustements (reorder and manual adjustements). 
--]]--
  
ffi.cdef[[
typedef unsigned int GLenum;
typedef unsigned char GLboolean;
typedef unsigned int GLbitfield;
typedef signed char GLbyte;
typedef short GLshort;
typedef int GLint;
typedef int GLsizei;
typedef unsigned char GLubyte;
typedef unsigned short GLushort;
typedef unsigned int GLuint;
typedef unsigned short GLhalf;
typedef float GLfloat;
typedef float GLclampf;
typedef double GLdouble;
typedef double GLclampd;
typedef void GLvoid;

typedef char GLchar;

typedef ptrdiff_t GLintptr;
typedef ptrdiff_t GLsizeiptr;

typedef ptrdiff_t GLintptrARB;
typedef ptrdiff_t GLsizeiptrARB;

typedef char GLcharARB;
typedef unsigned int GLhandleARB;

typedef unsigned short GLhalfARB;
typedef unsigned short GLhalfNV;

typedef long int int64_t;
typedef unsigned long int uint64_t;
typedef long long int int64_t;
typedef unsigned long long int uint64_t;
typedef int64_t GLint64EXT;
typedef uint64_t GLuint64EXT;
typedef int64_t GLint64;
typedef uint64_t GLuint64;
typedef struct __GLsync *GLsync;

/* AttribMask */
static const GLenum GL_DEPTH_BUFFER_BIT = 0x00000100;
static const GLenum GL_STENCIL_BUFFER_BIT = 0x00000400;
static const GLenum GL_COLOR_BUFFER_BIT = 0x00004000;
/* Boolean */
static const GLenum GL_FALSE = 0;
static const GLenum GL_TRUE = 1;
/* BeginMode */
static const GLenum GL_POINTS = 0x0000;
static const GLenum GL_LINES = 0x0001;
static const GLenum GL_LINE_LOOP = 0x0002;
static const GLenum GL_LINE_STRIP = 0x0003;
static const GLenum GL_TRIANGLES = 0x0004;
static const GLenum GL_TRIANGLE_STRIP = 0x0005;
static const GLenum GL_TRIANGLE_FAN = 0x0006;
/* AlphaFunction */
static const GLenum GL_NEVER = 0x0200;
static const GLenum GL_LESS = 0x0201;
static const GLenum GL_EQUAL = 0x0202;
static const GLenum GL_LEQUAL = 0x0203;
static const GLenum GL_GREATER = 0x0204;
static const GLenum GL_NOTEQUAL = 0x0205;
static const GLenum GL_GEQUAL = 0x0206;
static const GLenum GL_ALWAYS = 0x0207;
/* BlendingFactorDest */
static const GLenum GL_ZERO = 0;
static const GLenum GL_ONE = 1;
static const GLenum GL_SRC_COLOR = 0x0300;
static const GLenum GL_ONE_MINUS_SRC_COLOR = 0x0301;
static const GLenum GL_SRC_ALPHA = 0x0302;
static const GLenum GL_ONE_MINUS_SRC_ALPHA = 0x0303;
static const GLenum GL_DST_ALPHA = 0x0304;
static const GLenum GL_ONE_MINUS_DST_ALPHA = 0x0305;
/* BlendingFactorSrc */
static const GLenum GL_DST_COLOR = 0x0306;
static const GLenum GL_ONE_MINUS_DST_COLOR = 0x0307;
static const GLenum GL_SRC_ALPHA_SATURATE = 0x0308;
/* DrawBufferMode */
static const GLenum GL_NONE = 0;
static const GLenum GL_FRONT_LEFT = 0x0400;
static const GLenum GL_FRONT_RIGHT = 0x0401;
static const GLenum GL_BACK_LEFT = 0x0402;
static const GLenum GL_BACK_RIGHT = 0x0403;
static const GLenum GL_FRONT = 0x0404;
static const GLenum GL_BACK = 0x0405;
static const GLenum GL_LEFT = 0x0406;
static const GLenum GL_RIGHT = 0x0407;
static const GLenum GL_FRONT_AND_BACK = 0x0408;
/* ErrorCode */
static const GLenum GL_NO_ERROR = 0;
static const GLenum GL_INVALID_ENUM = 0x0500;
static const GLenum GL_INVALID_VALUE = 0x0501;
static const GLenum GL_INVALID_OPERATION = 0x0502;
static const GLenum GL_OUT_OF_MEMORY = 0x0505;
/* FrontFaceDirection */
static const GLenum GL_CW = 0x0900;
static const GLenum GL_CCW = 0x0901;
/* GetPName */
static const GLenum GL_POINT_SIZE = 0x0B11;
static const GLenum GL_POINT_SIZE_RANGE = 0x0B12;
static const GLenum GL_POINT_SIZE_GRANULARITY = 0x0B13;
static const GLenum GL_LINE_SMOOTH = 0x0B20;
static const GLenum GL_LINE_WIDTH = 0x0B21;
static const GLenum GL_LINE_WIDTH_RANGE = 0x0B22;
static const GLenum GL_LINE_WIDTH_GRANULARITY = 0x0B23;
static const GLenum GL_POLYGON_SMOOTH = 0x0B41;
static const GLenum GL_CULL_FACE = 0x0B44;
static const GLenum GL_CULL_FACE_MODE = 0x0B45;
static const GLenum GL_FRONT_FACE = 0x0B46;
static const GLenum GL_DEPTH_RANGE = 0x0B70;
static const GLenum GL_DEPTH_TEST = 0x0B71;
static const GLenum GL_DEPTH_WRITEMASK = 0x0B72;
static const GLenum GL_DEPTH_CLEAR_VALUE = 0x0B73;
static const GLenum GL_DEPTH_FUNC = 0x0B74;
static const GLenum GL_STENCIL_TEST = 0x0B90;
static const GLenum GL_STENCIL_CLEAR_VALUE = 0x0B91;
static const GLenum GL_STENCIL_FUNC = 0x0B92;
static const GLenum GL_STENCIL_VALUE_MASK = 0x0B93;
static const GLenum GL_STENCIL_FAIL = 0x0B94;
static const GLenum GL_STENCIL_PASS_DEPTH_FAIL = 0x0B95;
static const GLenum GL_STENCIL_PASS_DEPTH_PASS = 0x0B96;
static const GLenum GL_STENCIL_REF = 0x0B97;
static const GLenum GL_STENCIL_WRITEMASK = 0x0B98;
static const GLenum GL_VIEWPORT = 0x0BA2;
static const GLenum GL_DITHER = 0x0BD0;
static const GLenum GL_BLEND_DST = 0x0BE0;
static const GLenum GL_BLEND_SRC = 0x0BE1;
static const GLenum GL_BLEND = 0x0BE2;
static const GLenum GL_LOGIC_OP_MODE = 0x0BF0;
static const GLenum GL_COLOR_LOGIC_OP = 0x0BF2;
static const GLenum GL_DRAW_BUFFER = 0x0C01;
static const GLenum GL_READ_BUFFER = 0x0C02;
static const GLenum GL_SCISSOR_BOX = 0x0C10;
static const GLenum GL_SCISSOR_TEST = 0x0C11;
static const GLenum GL_COLOR_CLEAR_VALUE = 0x0C22;
static const GLenum GL_COLOR_WRITEMASK = 0x0C23;
static const GLenum GL_DOUBLEBUFFER = 0x0C32;
static const GLenum GL_STEREO = 0x0C33;
static const GLenum GL_LINE_SMOOTH_HINT = 0x0C52;
static const GLenum GL_POLYGON_SMOOTH_HINT = 0x0C53;
static const GLenum GL_UNPACK_SWAP_BYTES = 0x0CF0;
static const GLenum GL_UNPACK_LSB_FIRST = 0x0CF1;
static const GLenum GL_UNPACK_ROW_LENGTH = 0x0CF2;
static const GLenum GL_UNPACK_SKIP_ROWS = 0x0CF3;
static const GLenum GL_UNPACK_SKIP_PIXELS = 0x0CF4;
static const GLenum GL_UNPACK_ALIGNMENT = 0x0CF5;
static const GLenum GL_PACK_SWAP_BYTES = 0x0D00;
static const GLenum GL_PACK_LSB_FIRST = 0x0D01;
static const GLenum GL_PACK_ROW_LENGTH = 0x0D02;
static const GLenum GL_PACK_SKIP_ROWS = 0x0D03;
static const GLenum GL_PACK_SKIP_PIXELS = 0x0D04;
static const GLenum GL_PACK_ALIGNMENT = 0x0D05;
static const GLenum GL_MAX_TEXTURE_SIZE = 0x0D33;
static const GLenum GL_MAX_VIEWPORT_DIMS = 0x0D3A;
static const GLenum GL_SUBPIXEL_BITS = 0x0D50;
static const GLenum GL_TEXTURE_1D = 0x0DE0;
static const GLenum GL_TEXTURE_2D = 0x0DE1;
static const GLenum GL_POLYGON_OFFSET_UNITS = 0x2A00;
static const GLenum GL_POLYGON_OFFSET_POINT = 0x2A01;
static const GLenum GL_POLYGON_OFFSET_LINE = 0x2A02;
static const GLenum GL_POLYGON_OFFSET_FILL = 0x8037;
static const GLenum GL_POLYGON_OFFSET_FACTOR = 0x8038;
static const GLenum GL_TEXTURE_BINDING_1D = 0x8068;
static const GLenum GL_TEXTURE_BINDING_2D = 0x8069;
/* GetTextureParameter */
static const GLenum GL_TEXTURE_WIDTH = 0x1000;
static const GLenum GL_TEXTURE_HEIGHT = 0x1001;
static const GLenum GL_TEXTURE_INTERNAL_FORMAT = 0x1003;
static const GLenum GL_TEXTURE_BORDER_COLOR = 0x1004;
static const GLenum GL_TEXTURE_RED_SIZE = 0x805C;
static const GLenum GL_TEXTURE_GREEN_SIZE = 0x805D;
static const GLenum GL_TEXTURE_BLUE_SIZE = 0x805E;
static const GLenum GL_TEXTURE_ALPHA_SIZE = 0x805F;
/* HintMode */
static const GLenum GL_DONT_CARE = 0x1100;
static const GLenum GL_FASTEST = 0x1101;
static const GLenum GL_NICEST = 0x1102;
/* DataType */
static const GLenum GL_BYTE = 0x1400;
static const GLenum GL_UNSIGNED_BYTE = 0x1401;
static const GLenum GL_SHORT = 0x1402;
static const GLenum GL_UNSIGNED_SHORT = 0x1403;
static const GLenum GL_INT = 0x1404;
static const GLenum GL_UNSIGNED_INT = 0x1405;
static const GLenum GL_FLOAT = 0x1406;
static const GLenum GL_DOUBLE = 0x140A;
/* ErrorCode */
static const GLenum GL_STACK_OVERFLOW = 0x0503;
static const GLenum GL_STACK_UNDERFLOW = 0x0504;
/* LogicOp */
static const GLenum GL_CLEAR = 0x1500;
static const GLenum GL_AND = 0x1501;
static const GLenum GL_AND_REVERSE = 0x1502;
static const GLenum GL_COPY = 0x1503;
static const GLenum GL_AND_INVERTED = 0x1504;
static const GLenum GL_NOOP = 0x1505;
static const GLenum GL_XOR = 0x1506;
static const GLenum GL_OR = 0x1507;
static const GLenum GL_NOR = 0x1508;
static const GLenum GL_EQUIV = 0x1509;
static const GLenum GL_INVERT = 0x150A;
static const GLenum GL_OR_REVERSE = 0x150B;
static const GLenum GL_COPY_INVERTED = 0x150C;
static const GLenum GL_OR_INVERTED = 0x150D;
static const GLenum GL_NAND = 0x150E;
static const GLenum GL_SET = 0x150F;
/* MatrixMode (for gl3.h, FBO attachment type) */
static const GLenum GL_TEXTURE = 0x1702;
/* PixelCopyType */
static const GLenum GL_COLOR = 0x1800;
static const GLenum GL_DEPTH = 0x1801;
static const GLenum GL_STENCIL = 0x1802;
/* PixelFormat */
static const GLenum GL_STENCIL_INDEX = 0x1901;
static const GLenum GL_DEPTH_COMPONENT = 0x1902;
static const GLenum GL_RED = 0x1903;
static const GLenum GL_GREEN = 0x1904;
static const GLenum GL_BLUE = 0x1905;
static const GLenum GL_ALPHA = 0x1906;
static const GLenum GL_RGB = 0x1907;
static const GLenum GL_RGBA = 0x1908;
/* PolygonMode */
static const GLenum GL_POINT = 0x1B00;
static const GLenum GL_LINE = 0x1B01;
static const GLenum GL_FILL = 0x1B02;
/* StencilOp */
static const GLenum GL_KEEP = 0x1E00;
static const GLenum GL_REPLACE = 0x1E01;
static const GLenum GL_INCR = 0x1E02;
static const GLenum GL_DECR = 0x1E03;
/* StringName */
static const GLenum GL_VENDOR = 0x1F00;
static const GLenum GL_RENDERER = 0x1F01;
static const GLenum GL_VERSION = 0x1F02;
static const GLenum GL_EXTENSIONS = 0x1F03;
/* TextureMagFilter */
static const GLenum GL_NEAREST = 0x2600;
static const GLenum GL_LINEAR = 0x2601;
/* TextureMinFilter */
static const GLenum GL_NEAREST_MIPMAP_NEAREST = 0x2700;
static const GLenum GL_LINEAR_MIPMAP_NEAREST = 0x2701;
static const GLenum GL_NEAREST_MIPMAP_LINEAR = 0x2702;
static const GLenum GL_LINEAR_MIPMAP_LINEAR = 0x2703;
/* TextureParameterName */
static const GLenum GL_TEXTURE_MAG_FILTER = 0x2800;
static const GLenum GL_TEXTURE_MIN_FILTER = 0x2801;
static const GLenum GL_TEXTURE_WRAP_S = 0x2802;
static const GLenum GL_TEXTURE_WRAP_T = 0x2803;
/* TextureTarget */
static const GLenum GL_PROXY_TEXTURE_1D = 0x8063;
static const GLenum GL_PROXY_TEXTURE_2D = 0x8064;
/* TextureWrapMode */
static const GLenum GL_REPEAT = 0x2901;
/* PixelInternalFormat */
static const GLenum GL_R3_G3_B2 = 0x2A10;
static const GLenum GL_RGB4 = 0x804F;
static const GLenum GL_RGB5 = 0x8050;
static const GLenum GL_RGB8 = 0x8051;
static const GLenum GL_RGB10 = 0x8052;
static const GLenum GL_RGB12 = 0x8053;
static const GLenum GL_RGB16 = 0x8054;
static const GLenum GL_RGBA2 = 0x8055;
static const GLenum GL_RGBA4 = 0x8056;
static const GLenum GL_RGB5_A1 = 0x8057;
static const GLenum GL_RGBA8 = 0x8058;
static const GLenum GL_RGB10_A2 = 0x8059;
static const GLenum GL_RGBA12 = 0x805A;
static const GLenum GL_RGBA16 = 0x805B;

static const GLenum GL_UNSIGNED_BYTE_3_3_2 = 0x8032;
static const GLenum GL_UNSIGNED_SHORT_4_4_4_4 = 0x8033;
static const GLenum GL_UNSIGNED_SHORT_5_5_5_1 = 0x8034;
static const GLenum GL_UNSIGNED_INT_8_8_8_8 = 0x8035;
static const GLenum GL_UNSIGNED_INT_10_10_10_2 = 0x8036;
static const GLenum GL_TEXTURE_BINDING_3D = 0x806A;
static const GLenum GL_PACK_SKIP_IMAGES = 0x806B;
static const GLenum GL_PACK_IMAGE_HEIGHT = 0x806C;
static const GLenum GL_UNPACK_SKIP_IMAGES = 0x806D;
static const GLenum GL_UNPACK_IMAGE_HEIGHT = 0x806E;
static const GLenum GL_TEXTURE_3D = 0x806F;
static const GLenum GL_PROXY_TEXTURE_3D = 0x8070;
static const GLenum GL_TEXTURE_DEPTH = 0x8071;
static const GLenum GL_TEXTURE_WRAP_R = 0x8072;
static const GLenum GL_MAX_3D_TEXTURE_SIZE = 0x8073;
static const GLenum GL_UNSIGNED_BYTE_2_3_3_REV = 0x8362;
static const GLenum GL_UNSIGNED_SHORT_5_6_5 = 0x8363;
static const GLenum GL_UNSIGNED_SHORT_5_6_5_REV = 0x8364;
static const GLenum GL_UNSIGNED_SHORT_4_4_4_4_REV = 0x8365;
static const GLenum GL_UNSIGNED_SHORT_1_5_5_5_REV = 0x8366;
static const GLenum GL_UNSIGNED_INT_8_8_8_8_REV = 0x8367;
static const GLenum GL_UNSIGNED_INT_2_10_10_10_REV = 0x8368;
static const GLenum GL_BGR = 0x80E0;
static const GLenum GL_BGRA = 0x80E1;
static const GLenum GL_MAX_ELEMENTS_VERTICES = 0x80E8;
static const GLenum GL_MAX_ELEMENTS_INDICES = 0x80E9;
static const GLenum GL_CLAMP_TO_EDGE = 0x812F;
static const GLenum GL_TEXTURE_MIN_LOD = 0x813A;
static const GLenum GL_TEXTURE_MAX_LOD = 0x813B;
static const GLenum GL_TEXTURE_BASE_LEVEL = 0x813C;
static const GLenum GL_TEXTURE_MAX_LEVEL = 0x813D;
static const GLenum GL_SMOOTH_POINT_SIZE_RANGE = 0x0B12;
static const GLenum GL_SMOOTH_POINT_SIZE_GRANULARITY = 0x0B13;
static const GLenum GL_SMOOTH_LINE_WIDTH_RANGE = 0x0B22;
static const GLenum GL_SMOOTH_LINE_WIDTH_GRANULARITY = 0x0B23;
static const GLenum GL_ALIASED_LINE_WIDTH_RANGE = 0x846E;

static const GLenum GL_CONSTANT_COLOR = 0x8001;
static const GLenum GL_ONE_MINUS_CONSTANT_COLOR = 0x8002;
static const GLenum GL_CONSTANT_ALPHA = 0x8003;
static const GLenum GL_ONE_MINUS_CONSTANT_ALPHA = 0x8004;
static const GLenum GL_BLEND_COLOR = 0x8005;
static const GLenum GL_FUNC_ADD = 0x8006;
static const GLenum GL_MIN = 0x8007;
static const GLenum GL_MAX = 0x8008;
static const GLenum GL_BLEND_EQUATION = 0x8009;
static const GLenum GL_FUNC_SUBTRACT = 0x800A;
static const GLenum GL_FUNC_REVERSE_SUBTRACT = 0x800B;

static const GLenum GL_TEXTURE0 = 0x84C0;
static const GLenum GL_TEXTURE1 = 0x84C1;
static const GLenum GL_TEXTURE2 = 0x84C2;
static const GLenum GL_TEXTURE3 = 0x84C3;
static const GLenum GL_TEXTURE4 = 0x84C4;
static const GLenum GL_TEXTURE5 = 0x84C5;
static const GLenum GL_TEXTURE6 = 0x84C6;
static const GLenum GL_TEXTURE7 = 0x84C7;
static const GLenum GL_TEXTURE8 = 0x84C8;
static const GLenum GL_TEXTURE9 = 0x84C9;
static const GLenum GL_TEXTURE10 = 0x84CA;
static const GLenum GL_TEXTURE11 = 0x84CB;
static const GLenum GL_TEXTURE12 = 0x84CC;
static const GLenum GL_TEXTURE13 = 0x84CD;
static const GLenum GL_TEXTURE14 = 0x84CE;
static const GLenum GL_TEXTURE15 = 0x84CF;
static const GLenum GL_TEXTURE16 = 0x84D0;
static const GLenum GL_TEXTURE17 = 0x84D1;
static const GLenum GL_TEXTURE18 = 0x84D2;
static const GLenum GL_TEXTURE19 = 0x84D3;
static const GLenum GL_TEXTURE20 = 0x84D4;
static const GLenum GL_TEXTURE21 = 0x84D5;
static const GLenum GL_TEXTURE22 = 0x84D6;
static const GLenum GL_TEXTURE23 = 0x84D7;
static const GLenum GL_TEXTURE24 = 0x84D8;
static const GLenum GL_TEXTURE25 = 0x84D9;
static const GLenum GL_TEXTURE26 = 0x84DA;
static const GLenum GL_TEXTURE27 = 0x84DB;
static const GLenum GL_TEXTURE28 = 0x84DC;
static const GLenum GL_TEXTURE29 = 0x84DD;
static const GLenum GL_TEXTURE30 = 0x84DE;
static const GLenum GL_TEXTURE31 = 0x84DF;
static const GLenum GL_ACTIVE_TEXTURE = 0x84E0;
static const GLenum GL_MULTISAMPLE = 0x809D;
static const GLenum GL_SAMPLE_ALPHA_TO_COVERAGE = 0x809E;
static const GLenum GL_SAMPLE_ALPHA_TO_ONE = 0x809F;
static const GLenum GL_SAMPLE_COVERAGE = 0x80A0;
static const GLenum GL_SAMPLE_BUFFERS = 0x80A8;
static const GLenum GL_SAMPLES = 0x80A9;
static const GLenum GL_SAMPLE_COVERAGE_VALUE = 0x80AA;
static const GLenum GL_SAMPLE_COVERAGE_INVERT = 0x80AB;
static const GLenum GL_TEXTURE_CUBE_MAP = 0x8513;
static const GLenum GL_TEXTURE_BINDING_CUBE_MAP = 0x8514;
static const GLenum GL_TEXTURE_CUBE_MAP_POSITIVE_X = 0x8515;
static const GLenum GL_TEXTURE_CUBE_MAP_NEGATIVE_X = 0x8516;
static const GLenum GL_TEXTURE_CUBE_MAP_POSITIVE_Y = 0x8517;
static const GLenum GL_TEXTURE_CUBE_MAP_NEGATIVE_Y = 0x8518;
static const GLenum GL_TEXTURE_CUBE_MAP_POSITIVE_Z = 0x8519;
static const GLenum GL_TEXTURE_CUBE_MAP_NEGATIVE_Z = 0x851A;
static const GLenum GL_PROXY_TEXTURE_CUBE_MAP = 0x851B;
static const GLenum GL_MAX_CUBE_MAP_TEXTURE_SIZE = 0x851C;
static const GLenum GL_COMPRESSED_RGB = 0x84ED;
static const GLenum GL_COMPRESSED_RGBA = 0x84EE;
static const GLenum GL_TEXTURE_COMPRESSION_HINT = 0x84EF;
static const GLenum GL_TEXTURE_COMPRESSED_IMAGE_SIZE = 0x86A0;
static const GLenum GL_TEXTURE_COMPRESSED = 0x86A1;
static const GLenum GL_NUM_COMPRESSED_TEXTURE_FORMATS = 0x86A2;
static const GLenum GL_COMPRESSED_TEXTURE_FORMATS = 0x86A3;
static const GLenum GL_CLAMP_TO_BORDER = 0x812D;

static const GLenum GL_BLEND_DST_RGB = 0x80C8;
static const GLenum GL_BLEND_SRC_RGB = 0x80C9;
static const GLenum GL_BLEND_DST_ALPHA = 0x80CA;
static const GLenum GL_BLEND_SRC_ALPHA = 0x80CB;
static const GLenum GL_POINT_FADE_THRESHOLD_SIZE = 0x8128;
static const GLenum GL_DEPTH_COMPONENT16 = 0x81A5;
static const GLenum GL_DEPTH_COMPONENT24 = 0x81A6;
static const GLenum GL_DEPTH_COMPONENT32 = 0x81A7;
static const GLenum GL_MIRRORED_REPEAT = 0x8370;
static const GLenum GL_MAX_TEXTURE_LOD_BIAS = 0x84FD;
static const GLenum GL_TEXTURE_LOD_BIAS = 0x8501;
static const GLenum GL_INCR_WRAP = 0x8507;
static const GLenum GL_DECR_WRAP = 0x8508;
static const GLenum GL_TEXTURE_DEPTH_SIZE = 0x884A;
static const GLenum GL_TEXTURE_COMPARE_MODE = 0x884C;
static const GLenum GL_TEXTURE_COMPARE_FUNC = 0x884D;

static const GLenum GL_BUFFER_SIZE = 0x8764;
static const GLenum GL_BUFFER_USAGE = 0x8765;
static const GLenum GL_QUERY_COUNTER_BITS = 0x8864;
static const GLenum GL_CURRENT_QUERY = 0x8865;
static const GLenum GL_QUERY_RESULT = 0x8866;
static const GLenum GL_QUERY_RESULT_AVAILABLE = 0x8867;
static const GLenum GL_ARRAY_BUFFER = 0x8892;
static const GLenum GL_ELEMENT_ARRAY_BUFFER = 0x8893;
static const GLenum GL_ARRAY_BUFFER_BINDING = 0x8894;
static const GLenum GL_ELEMENT_ARRAY_BUFFER_BINDING = 0x8895;
static const GLenum GL_VERTEX_ATTRIB_ARRAY_BUFFER_BINDING = 0x889F;
static const GLenum GL_READ_ONLY = 0x88B8;
static const GLenum GL_WRITE_ONLY = 0x88B9;
static const GLenum GL_READ_WRITE = 0x88BA;
static const GLenum GL_BUFFER_ACCESS = 0x88BB;
static const GLenum GL_BUFFER_MAPPED = 0x88BC;
static const GLenum GL_BUFFER_MAP_POINTER = 0x88BD;
static const GLenum GL_STREAM_DRAW = 0x88E0;
static const GLenum GL_STREAM_READ = 0x88E1;
static const GLenum GL_STREAM_COPY = 0x88E2;
static const GLenum GL_STATIC_DRAW = 0x88E4;
static const GLenum GL_STATIC_READ = 0x88E5;
static const GLenum GL_STATIC_COPY = 0x88E6;
static const GLenum GL_DYNAMIC_DRAW = 0x88E8;
static const GLenum GL_DYNAMIC_READ = 0x88E9;
static const GLenum GL_DYNAMIC_COPY = 0x88EA;
static const GLenum GL_SAMPLES_PASSED = 0x8914;

static const GLenum GL_BLEND_EQUATION_RGB = 0x8009;
static const GLenum GL_VERTEX_ATTRIB_ARRAY_ENABLED = 0x8622;
static const GLenum GL_VERTEX_ATTRIB_ARRAY_SIZE = 0x8623;
static const GLenum GL_VERTEX_ATTRIB_ARRAY_STRIDE = 0x8624;
static const GLenum GL_VERTEX_ATTRIB_ARRAY_TYPE = 0x8625;
static const GLenum GL_CURRENT_VERTEX_ATTRIB = 0x8626;
static const GLenum GL_VERTEX_PROGRAM_POINT_SIZE = 0x8642;
static const GLenum GL_VERTEX_ATTRIB_ARRAY_POINTER = 0x8645;
static const GLenum GL_STENCIL_BACK_FUNC = 0x8800;
static const GLenum GL_STENCIL_BACK_FAIL = 0x8801;
static const GLenum GL_STENCIL_BACK_PASS_DEPTH_FAIL = 0x8802;
static const GLenum GL_STENCIL_BACK_PASS_DEPTH_PASS = 0x8803;
static const GLenum GL_MAX_DRAW_BUFFERS = 0x8824;
static const GLenum GL_DRAW_BUFFER0 = 0x8825;
static const GLenum GL_DRAW_BUFFER1 = 0x8826;
static const GLenum GL_DRAW_BUFFER2 = 0x8827;
static const GLenum GL_DRAW_BUFFER3 = 0x8828;
static const GLenum GL_DRAW_BUFFER4 = 0x8829;
static const GLenum GL_DRAW_BUFFER5 = 0x882A;
static const GLenum GL_DRAW_BUFFER6 = 0x882B;
static const GLenum GL_DRAW_BUFFER7 = 0x882C;
static const GLenum GL_DRAW_BUFFER8 = 0x882D;
static const GLenum GL_DRAW_BUFFER9 = 0x882E;
static const GLenum GL_DRAW_BUFFER10 = 0x882F;
static const GLenum GL_DRAW_BUFFER11 = 0x8830;
static const GLenum GL_DRAW_BUFFER12 = 0x8831;
static const GLenum GL_DRAW_BUFFER13 = 0x8832;
static const GLenum GL_DRAW_BUFFER14 = 0x8833;
static const GLenum GL_DRAW_BUFFER15 = 0x8834;
static const GLenum GL_BLEND_EQUATION_ALPHA = 0x883D;
static const GLenum GL_MAX_VERTEX_ATTRIBS = 0x8869;
static const GLenum GL_VERTEX_ATTRIB_ARRAY_NORMALIZED = 0x886A;
static const GLenum GL_MAX_TEXTURE_IMAGE_UNITS = 0x8872;
static const GLenum GL_FRAGMENT_SHADER = 0x8B30;
static const GLenum GL_VERTEX_SHADER = 0x8B31;
static const GLenum GL_MAX_FRAGMENT_UNIFORM_COMPONENTS = 0x8B49;
static const GLenum GL_MAX_VERTEX_UNIFORM_COMPONENTS = 0x8B4A;
static const GLenum GL_MAX_VARYING_FLOATS = 0x8B4B;
static const GLenum GL_MAX_VERTEX_TEXTURE_IMAGE_UNITS = 0x8B4C;
static const GLenum GL_MAX_COMBINED_TEXTURE_IMAGE_UNITS = 0x8B4D;
static const GLenum GL_SHADER_TYPE = 0x8B4F;
static const GLenum GL_FLOAT_VEC2 = 0x8B50;
static const GLenum GL_FLOAT_VEC3 = 0x8B51;
static const GLenum GL_FLOAT_VEC4 = 0x8B52;
static const GLenum GL_INT_VEC2 = 0x8B53;
static const GLenum GL_INT_VEC3 = 0x8B54;
static const GLenum GL_INT_VEC4 = 0x8B55;
static const GLenum GL_BOOL = 0x8B56;
static const GLenum GL_BOOL_VEC2 = 0x8B57;
static const GLenum GL_BOOL_VEC3 = 0x8B58;
static const GLenum GL_BOOL_VEC4 = 0x8B59;
static const GLenum GL_FLOAT_MAT2 = 0x8B5A;
static const GLenum GL_FLOAT_MAT3 = 0x8B5B;
static const GLenum GL_FLOAT_MAT4 = 0x8B5C;
static const GLenum GL_SAMPLER_1D = 0x8B5D;
static const GLenum GL_SAMPLER_2D = 0x8B5E;
static const GLenum GL_SAMPLER_3D = 0x8B5F;
static const GLenum GL_SAMPLER_CUBE = 0x8B60;
static const GLenum GL_SAMPLER_1D_SHADOW = 0x8B61;
static const GLenum GL_SAMPLER_2D_SHADOW = 0x8B62;
static const GLenum GL_DELETE_STATUS = 0x8B80;
static const GLenum GL_COMPILE_STATUS = 0x8B81;
static const GLenum GL_LINK_STATUS = 0x8B82;
static const GLenum GL_VALIDATE_STATUS = 0x8B83;
static const GLenum GL_INFO_LOG_LENGTH = 0x8B84;
static const GLenum GL_ATTACHED_SHADERS = 0x8B85;
static const GLenum GL_ACTIVE_UNIFORMS = 0x8B86;
static const GLenum GL_ACTIVE_UNIFORM_MAX_LENGTH = 0x8B87;
static const GLenum GL_SHADER_SOURCE_LENGTH = 0x8B88;
static const GLenum GL_ACTIVE_ATTRIBUTES = 0x8B89;
static const GLenum GL_ACTIVE_ATTRIBUTE_MAX_LENGTH = 0x8B8A;
static const GLenum GL_FRAGMENT_SHADER_DERIVATIVE_HINT = 0x8B8B;
static const GLenum GL_SHADING_LANGUAGE_VERSION = 0x8B8C;
static const GLenum GL_CURRENT_PROGRAM = 0x8B8D;
static const GLenum GL_POINT_SPRITE_COORD_ORIGIN = 0x8CA0;
static const GLenum GL_LOWER_LEFT = 0x8CA1;
static const GLenum GL_UPPER_LEFT = 0x8CA2;
static const GLenum GL_STENCIL_BACK_REF = 0x8CA3;
static const GLenum GL_STENCIL_BACK_VALUE_MASK = 0x8CA4;
static const GLenum GL_STENCIL_BACK_WRITEMASK = 0x8CA5;

static const GLenum GL_PIXEL_PACK_BUFFER = 0x88EB;
static const GLenum GL_PIXEL_UNPACK_BUFFER = 0x88EC;
static const GLenum GL_PIXEL_PACK_BUFFER_BINDING = 0x88ED;
static const GLenum GL_PIXEL_UNPACK_BUFFER_BINDING = 0x88EF;
static const GLenum GL_FLOAT_MAT2x3 = 0x8B65;
static const GLenum GL_FLOAT_MAT2x4 = 0x8B66;
static const GLenum GL_FLOAT_MAT3x2 = 0x8B67;
static const GLenum GL_FLOAT_MAT3x4 = 0x8B68;
static const GLenum GL_FLOAT_MAT4x2 = 0x8B69;
static const GLenum GL_FLOAT_MAT4x3 = 0x8B6A;
static const GLenum GL_SRGB = 0x8C40;
static const GLenum GL_SRGB8 = 0x8C41;
static const GLenum GL_SRGB_ALPHA = 0x8C42;
static const GLenum GL_SRGB8_ALPHA8 = 0x8C43;
static const GLenum GL_COMPRESSED_SRGB = 0x8C48;
static const GLenum GL_COMPRESSED_SRGB_ALPHA = 0x8C49;

static const GLenum GL_COMPARE_REF_TO_TEXTURE = 0x884E;
static const GLenum GL_CLIP_DISTANCE0 = 0x3000;
static const GLenum GL_CLIP_DISTANCE1 = 0x3001;
static const GLenum GL_CLIP_DISTANCE2 = 0x3002;
static const GLenum GL_CLIP_DISTANCE3 = 0x3003;
static const GLenum GL_CLIP_DISTANCE4 = 0x3004;
static const GLenum GL_CLIP_DISTANCE5 = 0x3005;
static const GLenum GL_CLIP_DISTANCE6 = 0x3006;
static const GLenum GL_CLIP_DISTANCE7 = 0x3007;
static const GLenum GL_MAX_CLIP_DISTANCES = 0x0D32;
static const GLenum GL_MAJOR_VERSION = 0x821B;
static const GLenum GL_MINOR_VERSION = 0x821C;
static const GLenum GL_NUM_EXTENSIONS = 0x821D;
static const GLenum GL_CONTEXT_FLAGS = 0x821E;
static const GLenum GL_COMPRESSED_RED = 0x8225;
static const GLenum GL_COMPRESSED_RG = 0x8226;
static const GLenum GL_CONTEXT_FLAG_FORWARD_COMPATIBLE_BIT = 0x0001;
static const GLenum GL_RGBA32F = 0x8814;
static const GLenum GL_RGB32F = 0x8815;
static const GLenum GL_RGBA16F = 0x881A;
static const GLenum GL_RGB16F = 0x881B;
static const GLenum GL_VERTEX_ATTRIB_ARRAY_INTEGER = 0x88FD;
static const GLenum GL_MAX_ARRAY_TEXTURE_LAYERS = 0x88FF;
static const GLenum GL_MIN_PROGRAM_TEXEL_OFFSET = 0x8904;
static const GLenum GL_MAX_PROGRAM_TEXEL_OFFSET = 0x8905;
static const GLenum GL_CLAMP_READ_COLOR = 0x891C;
static const GLenum GL_FIXED_ONLY = 0x891D;
static const GLenum GL_MAX_VARYING_COMPONENTS = 0x8B4B;
static const GLenum GL_TEXTURE_1D_ARRAY = 0x8C18;
static const GLenum GL_PROXY_TEXTURE_1D_ARRAY = 0x8C19;
static const GLenum GL_TEXTURE_2D_ARRAY = 0x8C1A;
static const GLenum GL_PROXY_TEXTURE_2D_ARRAY = 0x8C1B;
static const GLenum GL_TEXTURE_BINDING_1D_ARRAY = 0x8C1C;
static const GLenum GL_TEXTURE_BINDING_2D_ARRAY = 0x8C1D;
static const GLenum GL_R11F_G11F_B10F = 0x8C3A;
static const GLenum GL_UNSIGNED_INT_10F_11F_11F_REV = 0x8C3B;
static const GLenum GL_RGB9_E5 = 0x8C3D;
static const GLenum GL_UNSIGNED_INT_5_9_9_9_REV = 0x8C3E;
static const GLenum GL_TEXTURE_SHARED_SIZE = 0x8C3F;
static const GLenum GL_TRANSFORM_FEEDBACK_VARYING_MAX_LENGTH = 0x8C76;
static const GLenum GL_TRANSFORM_FEEDBACK_BUFFER_MODE = 0x8C7F;
static const GLenum GL_MAX_TRANSFORM_FEEDBACK_SEPARATE_COMPONENTS = 0x8C80;
static const GLenum GL_TRANSFORM_FEEDBACK_VARYINGS = 0x8C83;
static const GLenum GL_TRANSFORM_FEEDBACK_BUFFER_START = 0x8C84;
static const GLenum GL_TRANSFORM_FEEDBACK_BUFFER_SIZE = 0x8C85;
static const GLenum GL_PRIMITIVES_GENERATED = 0x8C87;
static const GLenum GL_TRANSFORM_FEEDBACK_PRIMITIVES_WRITTEN = 0x8C88;
static const GLenum GL_RASTERIZER_DISCARD = 0x8C89;
static const GLenum GL_MAX_TRANSFORM_FEEDBACK_INTERLEAVED_COMPONENTS = 0x8C8A;
static const GLenum GL_MAX_TRANSFORM_FEEDBACK_SEPARATE_ATTRIBS = 0x8C8B;
static const GLenum GL_INTERLEAVED_ATTRIBS = 0x8C8C;
static const GLenum GL_SEPARATE_ATTRIBS = 0x8C8D;
static const GLenum GL_TRANSFORM_FEEDBACK_BUFFER = 0x8C8E;
static const GLenum GL_TRANSFORM_FEEDBACK_BUFFER_BINDING = 0x8C8F;
static const GLenum GL_RGBA32UI = 0x8D70;
static const GLenum GL_RGB32UI = 0x8D71;
static const GLenum GL_RGBA16UI = 0x8D76;
static const GLenum GL_RGB16UI = 0x8D77;
static const GLenum GL_RGBA8UI = 0x8D7C;
static const GLenum GL_RGB8UI = 0x8D7D;
static const GLenum GL_RGBA32I = 0x8D82;
static const GLenum GL_RGB32I = 0x8D83;
static const GLenum GL_RGBA16I = 0x8D88;
static const GLenum GL_RGB16I = 0x8D89;
static const GLenum GL_RGBA8I = 0x8D8E;
static const GLenum GL_RGB8I = 0x8D8F;
static const GLenum GL_RED_INTEGER = 0x8D94;
static const GLenum GL_GREEN_INTEGER = 0x8D95;
static const GLenum GL_BLUE_INTEGER = 0x8D96;
static const GLenum GL_RGB_INTEGER = 0x8D98;
static const GLenum GL_RGBA_INTEGER = 0x8D99;
static const GLenum GL_BGR_INTEGER = 0x8D9A;
static const GLenum GL_BGRA_INTEGER = 0x8D9B;
static const GLenum GL_SAMPLER_1D_ARRAY = 0x8DC0;
static const GLenum GL_SAMPLER_2D_ARRAY = 0x8DC1;
static const GLenum GL_SAMPLER_1D_ARRAY_SHADOW = 0x8DC3;
static const GLenum GL_SAMPLER_2D_ARRAY_SHADOW = 0x8DC4;
static const GLenum GL_SAMPLER_CUBE_SHADOW = 0x8DC5;
static const GLenum GL_UNSIGNED_INT_VEC2 = 0x8DC6;
static const GLenum GL_UNSIGNED_INT_VEC3 = 0x8DC7;
static const GLenum GL_UNSIGNED_INT_VEC4 = 0x8DC8;
static const GLenum GL_INT_SAMPLER_1D = 0x8DC9;
static const GLenum GL_INT_SAMPLER_2D = 0x8DCA;
static const GLenum GL_INT_SAMPLER_3D = 0x8DCB;
static const GLenum GL_INT_SAMPLER_CUBE = 0x8DCC;
static const GLenum GL_INT_SAMPLER_1D_ARRAY = 0x8DCE;
static const GLenum GL_INT_SAMPLER_2D_ARRAY = 0x8DCF;
static const GLenum GL_UNSIGNED_INT_SAMPLER_1D = 0x8DD1;
static const GLenum GL_UNSIGNED_INT_SAMPLER_2D = 0x8DD2;
static const GLenum GL_UNSIGNED_INT_SAMPLER_3D = 0x8DD3;
static const GLenum GL_UNSIGNED_INT_SAMPLER_CUBE = 0x8DD4;
static const GLenum GL_UNSIGNED_INT_SAMPLER_1D_ARRAY = 0x8DD6;
static const GLenum GL_UNSIGNED_INT_SAMPLER_2D_ARRAY = 0x8DD7;
static const GLenum GL_QUERY_WAIT = 0x8E13;
static const GLenum GL_QUERY_NO_WAIT = 0x8E14;
static const GLenum GL_QUERY_BY_REGION_WAIT = 0x8E15;
static const GLenum GL_QUERY_BY_REGION_NO_WAIT = 0x8E16;
static const GLenum GL_BUFFER_ACCESS_FLAGS = 0x911F;
static const GLenum GL_BUFFER_MAP_LENGTH = 0x9120;
static const GLenum GL_BUFFER_MAP_OFFSET = 0x9121;

static const GLenum GL_SAMPLER_2D_RECT = 0x8B63;
static const GLenum GL_SAMPLER_2D_RECT_SHADOW = 0x8B64;
static const GLenum GL_SAMPLER_BUFFER = 0x8DC2;
static const GLenum GL_INT_SAMPLER_2D_RECT = 0x8DCD;
static const GLenum GL_INT_SAMPLER_BUFFER = 0x8DD0;
static const GLenum GL_UNSIGNED_INT_SAMPLER_2D_RECT = 0x8DD5;
static const GLenum GL_UNSIGNED_INT_SAMPLER_BUFFER = 0x8DD8;
static const GLenum GL_TEXTURE_BUFFER = 0x8C2A;
static const GLenum GL_MAX_TEXTURE_BUFFER_SIZE = 0x8C2B;
static const GLenum GL_TEXTURE_BINDING_BUFFER = 0x8C2C;
static const GLenum GL_TEXTURE_BUFFER_DATA_STORE_BINDING = 0x8C2D;
static const GLenum GL_TEXTURE_BUFFER_FORMAT = 0x8C2E;
static const GLenum GL_TEXTURE_RECTANGLE = 0x84F5;
static const GLenum GL_TEXTURE_BINDING_RECTANGLE = 0x84F6;
static const GLenum GL_PROXY_TEXTURE_RECTANGLE = 0x84F7;
static const GLenum GL_MAX_RECTANGLE_TEXTURE_SIZE = 0x84F8;
static const GLenum GL_RED_SNORM = 0x8F90;
static const GLenum GL_RG_SNORM = 0x8F91;
static const GLenum GL_RGB_SNORM = 0x8F92;
static const GLenum GL_RGBA_SNORM = 0x8F93;
static const GLenum GL_R8_SNORM = 0x8F94;
static const GLenum GL_RG8_SNORM = 0x8F95;
static const GLenum GL_RGB8_SNORM = 0x8F96;
static const GLenum GL_RGBA8_SNORM = 0x8F97;
static const GLenum GL_R16_SNORM = 0x8F98;
static const GLenum GL_RG16_SNORM = 0x8F99;
static const GLenum GL_RGB16_SNORM = 0x8F9A;
static const GLenum GL_RGBA16_SNORM = 0x8F9B;
static const GLenum GL_SIGNED_NORMALIZED = 0x8F9C;
static const GLenum GL_PRIMITIVE_RESTART = 0x8F9D;
static const GLenum GL_PRIMITIVE_RESTART_INDEX = 0x8F9E;

static const GLenum GL_CONTEXT_CORE_PROFILE_BIT = 0x00000001;
static const GLenum GL_CONTEXT_COMPATIBILITY_PROFILE_BIT = 0x00000002;
static const GLenum GL_LINES_ADJACENCY = 0x000A;
static const GLenum GL_LINE_STRIP_ADJACENCY = 0x000B;
static const GLenum GL_TRIANGLES_ADJACENCY = 0x000C;
static const GLenum GL_TRIANGLE_STRIP_ADJACENCY = 0x000D;
static const GLenum GL_PROGRAM_POINT_SIZE = 0x8642;
static const GLenum GL_MAX_GEOMETRY_TEXTURE_IMAGE_UNITS = 0x8C29;
static const GLenum GL_FRAMEBUFFER_ATTACHMENT_LAYERED = 0x8DA7;
static const GLenum GL_FRAMEBUFFER_INCOMPLETE_LAYER_TARGETS = 0x8DA8;
static const GLenum GL_GEOMETRY_SHADER = 0x8DD9;
static const GLenum GL_GEOMETRY_VERTICES_OUT = 0x8916;
static const GLenum GL_GEOMETRY_INPUT_TYPE = 0x8917;
static const GLenum GL_GEOMETRY_OUTPUT_TYPE = 0x8918;
static const GLenum GL_MAX_GEOMETRY_UNIFORM_COMPONENTS = 0x8DDF;
static const GLenum GL_MAX_GEOMETRY_OUTPUT_VERTICES = 0x8DE0;
static const GLenum GL_MAX_GEOMETRY_TOTAL_OUTPUT_COMPONENTS = 0x8DE1;
static const GLenum GL_MAX_VERTEX_OUTPUT_COMPONENTS = 0x9122;
static const GLenum GL_MAX_GEOMETRY_INPUT_COMPONENTS = 0x9123;
static const GLenum GL_MAX_GEOMETRY_OUTPUT_COMPONENTS = 0x9124;
static const GLenum GL_MAX_FRAGMENT_INPUT_COMPONENTS = 0x9125;
static const GLenum GL_CONTEXT_PROFILE_MASK = 0x9126;

static const GLenum GL_VERTEX_ATTRIB_ARRAY_DIVISOR = 0x88FE;

static const GLenum GL_SAMPLE_SHADING = 0x8C36;
static const GLenum GL_MIN_SAMPLE_SHADING_VALUE = 0x8C37;
static const GLenum GL_MIN_PROGRAM_TEXTURE_GATHER_OFFSET = 0x8E5E;
static const GLenum GL_MAX_PROGRAM_TEXTURE_GATHER_OFFSET = 0x8E5F;
static const GLenum GL_TEXTURE_CUBE_MAP_ARRAY = 0x9009;
static const GLenum GL_TEXTURE_BINDING_CUBE_MAP_ARRAY = 0x900A;
static const GLenum GL_PROXY_TEXTURE_CUBE_MAP_ARRAY = 0x900B;
static const GLenum GL_SAMPLER_CUBE_MAP_ARRAY = 0x900C;
static const GLenum GL_SAMPLER_CUBE_MAP_ARRAY_SHADOW = 0x900D;
static const GLenum GL_INT_SAMPLER_CUBE_MAP_ARRAY = 0x900E;
static const GLenum GL_UNSIGNED_INT_SAMPLER_CUBE_MAP_ARRAY = 0x900F;

static const GLenum GL_NUM_SHADING_LANGUAGE_VERSIONS = 0x82E9;
static const GLenum GL_VERTEX_ATTRIB_ARRAY_LONG = 0x874E;

static const GLenum GL_DEPTH_COMPONENT32F = 0x8CAC;
static const GLenum GL_DEPTH32F_STENCIL8 = 0x8CAD;
static const GLenum GL_FLOAT_32_UNSIGNED_INT_24_8_REV = 0x8DAD;

static const GLenum GL_INVALID_FRAMEBUFFER_OPERATION = 0x0506;
static const GLenum GL_FRAMEBUFFER_ATTACHMENT_COLOR_ENCODING = 0x8210;
static const GLenum GL_FRAMEBUFFER_ATTACHMENT_COMPONENT_TYPE = 0x8211;
static const GLenum GL_FRAMEBUFFER_ATTACHMENT_RED_SIZE = 0x8212;
static const GLenum GL_FRAMEBUFFER_ATTACHMENT_GREEN_SIZE = 0x8213;
static const GLenum GL_FRAMEBUFFER_ATTACHMENT_BLUE_SIZE = 0x8214;
static const GLenum GL_FRAMEBUFFER_ATTACHMENT_ALPHA_SIZE = 0x8215;
static const GLenum GL_FRAMEBUFFER_ATTACHMENT_DEPTH_SIZE = 0x8216;
static const GLenum GL_FRAMEBUFFER_ATTACHMENT_STENCIL_SIZE = 0x8217;
static const GLenum GL_FRAMEBUFFER_DEFAULT = 0x8218;
static const GLenum GL_FRAMEBUFFER_UNDEFINED = 0x8219;
static const GLenum GL_DEPTH_STENCIL_ATTACHMENT = 0x821A;
static const GLenum GL_MAX_RENDERBUFFER_SIZE = 0x84E8;
static const GLenum GL_DEPTH_STENCIL = 0x84F9;
static const GLenum GL_UNSIGNED_INT_24_8 = 0x84FA;
static const GLenum GL_DEPTH24_STENCIL8 = 0x88F0;
static const GLenum GL_TEXTURE_STENCIL_SIZE = 0x88F1;
static const GLenum GL_TEXTURE_RED_TYPE = 0x8C10;
static const GLenum GL_TEXTURE_GREEN_TYPE = 0x8C11;
static const GLenum GL_TEXTURE_BLUE_TYPE = 0x8C12;
static const GLenum GL_TEXTURE_ALPHA_TYPE = 0x8C13;
static const GLenum GL_TEXTURE_DEPTH_TYPE = 0x8C16;
static const GLenum GL_UNSIGNED_NORMALIZED = 0x8C17;
static const GLenum GL_FRAMEBUFFER_BINDING = 0x8CA6;
static const GLenum GL_DRAW_FRAMEBUFFER_BINDING = GL_FRAMEBUFFER_BINDING;
static const GLenum GL_RENDERBUFFER_BINDING = 0x8CA7;
static const GLenum GL_READ_FRAMEBUFFER = 0x8CA8;
static const GLenum GL_DRAW_FRAMEBUFFER = 0x8CA9;
static const GLenum GL_READ_FRAMEBUFFER_BINDING = 0x8CAA;
static const GLenum GL_RENDERBUFFER_SAMPLES = 0x8CAB;
static const GLenum GL_FRAMEBUFFER_ATTACHMENT_OBJECT_TYPE = 0x8CD0;
static const GLenum GL_FRAMEBUFFER_ATTACHMENT_OBJECT_NAME = 0x8CD1;
static const GLenum GL_FRAMEBUFFER_ATTACHMENT_TEXTURE_LEVEL = 0x8CD2;
static const GLenum GL_FRAMEBUFFER_ATTACHMENT_TEXTURE_CUBE_MAP_FACE = 0x8CD3;
static const GLenum GL_FRAMEBUFFER_ATTACHMENT_TEXTURE_LAYER = 0x8CD4;
static const GLenum GL_FRAMEBUFFER_COMPLETE = 0x8CD5;
static const GLenum GL_FRAMEBUFFER_INCOMPLETE_ATTACHMENT = 0x8CD6;
static const GLenum GL_FRAMEBUFFER_INCOMPLETE_MISSING_ATTACHMENT = 0x8CD7;
static const GLenum GL_FRAMEBUFFER_INCOMPLETE_DRAW_BUFFER = 0x8CDB;
static const GLenum GL_FRAMEBUFFER_INCOMPLETE_READ_BUFFER = 0x8CDC;
static const GLenum GL_FRAMEBUFFER_UNSUPPORTED = 0x8CDD;
static const GLenum GL_MAX_COLOR_ATTACHMENTS = 0x8CDF;
static const GLenum GL_COLOR_ATTACHMENT0 = 0x8CE0;
static const GLenum GL_COLOR_ATTACHMENT1 = 0x8CE1;
static const GLenum GL_COLOR_ATTACHMENT2 = 0x8CE2;
static const GLenum GL_COLOR_ATTACHMENT3 = 0x8CE3;
static const GLenum GL_COLOR_ATTACHMENT4 = 0x8CE4;
static const GLenum GL_COLOR_ATTACHMENT5 = 0x8CE5;
static const GLenum GL_COLOR_ATTACHMENT6 = 0x8CE6;
static const GLenum GL_COLOR_ATTACHMENT7 = 0x8CE7;
static const GLenum GL_COLOR_ATTACHMENT8 = 0x8CE8;
static const GLenum GL_COLOR_ATTACHMENT9 = 0x8CE9;
static const GLenum GL_COLOR_ATTACHMENT10 = 0x8CEA;
static const GLenum GL_COLOR_ATTACHMENT11 = 0x8CEB;
static const GLenum GL_COLOR_ATTACHMENT12 = 0x8CEC;
static const GLenum GL_COLOR_ATTACHMENT13 = 0x8CED;
static const GLenum GL_COLOR_ATTACHMENT14 = 0x8CEE;
static const GLenum GL_COLOR_ATTACHMENT15 = 0x8CEF;
static const GLenum GL_DEPTH_ATTACHMENT = 0x8D00;
static const GLenum GL_STENCIL_ATTACHMENT = 0x8D20;
static const GLenum GL_FRAMEBUFFER = 0x8D40;
static const GLenum GL_RENDERBUFFER = 0x8D41;
static const GLenum GL_RENDERBUFFER_WIDTH = 0x8D42;
static const GLenum GL_RENDERBUFFER_HEIGHT = 0x8D43;
static const GLenum GL_RENDERBUFFER_INTERNAL_FORMAT = 0x8D44;
static const GLenum GL_STENCIL_INDEX1 = 0x8D46;
static const GLenum GL_STENCIL_INDEX4 = 0x8D47;
static const GLenum GL_STENCIL_INDEX8 = 0x8D48;
static const GLenum GL_STENCIL_INDEX16 = 0x8D49;
static const GLenum GL_RENDERBUFFER_RED_SIZE = 0x8D50;
static const GLenum GL_RENDERBUFFER_GREEN_SIZE = 0x8D51;
static const GLenum GL_RENDERBUFFER_BLUE_SIZE = 0x8D52;
static const GLenum GL_RENDERBUFFER_ALPHA_SIZE = 0x8D53;
static const GLenum GL_RENDERBUFFER_DEPTH_SIZE = 0x8D54;
static const GLenum GL_RENDERBUFFER_STENCIL_SIZE = 0x8D55;
static const GLenum GL_FRAMEBUFFER_INCOMPLETE_MULTISAMPLE = 0x8D56;
static const GLenum GL_MAX_SAMPLES = 0x8D57;

static const GLenum GL_FRAMEBUFFER_SRGB = 0x8DB9;

static const GLenum GL_HALF_FLOAT = 0x140B;

static const GLenum GL_MAP_READ_BIT = 0x0001;
static const GLenum GL_MAP_WRITE_BIT = 0x0002;
static const GLenum GL_MAP_INVALIDATE_RANGE_BIT = 0x0004;
static const GLenum GL_MAP_INVALIDATE_BUFFER_BIT = 0x0008;
static const GLenum GL_MAP_FLUSH_EXPLICIT_BIT = 0x0010;
static const GLenum GL_MAP_UNSYNCHRONIZED_BIT = 0x0020;

static const GLenum GL_COMPRESSED_RED_RGTC1 = 0x8DBB;
static const GLenum GL_COMPRESSED_SIGNED_RED_RGTC1 = 0x8DBC;
static const GLenum GL_COMPRESSED_RG_RGTC2 = 0x8DBD;
static const GLenum GL_COMPRESSED_SIGNED_RG_RGTC2 = 0x8DBE;

static const GLenum GL_RG = 0x8227;
static const GLenum GL_RG_INTEGER = 0x8228;
static const GLenum GL_R8 = 0x8229;
static const GLenum GL_R16 = 0x822A;
static const GLenum GL_RG8 = 0x822B;
static const GLenum GL_RG16 = 0x822C;
static const GLenum GL_R16F = 0x822D;
static const GLenum GL_R32F = 0x822E;
static const GLenum GL_RG16F = 0x822F;
static const GLenum GL_RG32F = 0x8230;
static const GLenum GL_R8I = 0x8231;
static const GLenum GL_R8UI = 0x8232;
static const GLenum GL_R16I = 0x8233;
static const GLenum GL_R16UI = 0x8234;
static const GLenum GL_R32I = 0x8235;
static const GLenum GL_R32UI = 0x8236;
static const GLenum GL_RG8I = 0x8237;
static const GLenum GL_RG8UI = 0x8238;
static const GLenum GL_RG16I = 0x8239;
static const GLenum GL_RG16UI = 0x823A;
static const GLenum GL_RG32I = 0x823B;
static const GLenum GL_RG32UI = 0x823C;

static const GLenum GL_VERTEX_ARRAY_BINDING = 0x85B5;

static const GLenum GL_UNIFORM_BUFFER = 0x8A11;
static const GLenum GL_UNIFORM_BUFFER_BINDING = 0x8A28;
static const GLenum GL_UNIFORM_BUFFER_START = 0x8A29;
static const GLenum GL_UNIFORM_BUFFER_SIZE = 0x8A2A;
static const GLenum GL_MAX_VERTEX_UNIFORM_BLOCKS = 0x8A2B;
static const GLenum GL_MAX_GEOMETRY_UNIFORM_BLOCKS = 0x8A2C;
static const GLenum GL_MAX_FRAGMENT_UNIFORM_BLOCKS = 0x8A2D;
static const GLenum GL_MAX_COMBINED_UNIFORM_BLOCKS = 0x8A2E;
static const GLenum GL_MAX_UNIFORM_BUFFER_BINDINGS = 0x8A2F;
static const GLenum GL_MAX_UNIFORM_BLOCK_SIZE = 0x8A30;
static const GLenum GL_MAX_COMBINED_VERTEX_UNIFORM_COMPONENTS = 0x8A31;
static const GLenum GL_MAX_COMBINED_GEOMETRY_UNIFORM_COMPONENTS = 0x8A32;
static const GLenum GL_MAX_COMBINED_FRAGMENT_UNIFORM_COMPONENTS = 0x8A33;
static const GLenum GL_UNIFORM_BUFFER_OFFSET_ALIGNMENT = 0x8A34;
static const GLenum GL_ACTIVE_UNIFORM_BLOCK_MAX_NAME_LENGTH = 0x8A35;
static const GLenum GL_ACTIVE_UNIFORM_BLOCKS = 0x8A36;
static const GLenum GL_UNIFORM_TYPE = 0x8A37;
static const GLenum GL_UNIFORM_SIZE = 0x8A38;
static const GLenum GL_UNIFORM_NAME_LENGTH = 0x8A39;
static const GLenum GL_UNIFORM_BLOCK_INDEX = 0x8A3A;
static const GLenum GL_UNIFORM_OFFSET = 0x8A3B;
static const GLenum GL_UNIFORM_ARRAY_STRIDE = 0x8A3C;
static const GLenum GL_UNIFORM_MATRIX_STRIDE = 0x8A3D;
static const GLenum GL_UNIFORM_IS_ROW_MAJOR = 0x8A3E;
static const GLenum GL_UNIFORM_BLOCK_BINDING = 0x8A3F;
static const GLenum GL_UNIFORM_BLOCK_DATA_SIZE = 0x8A40;
static const GLenum GL_UNIFORM_BLOCK_NAME_LENGTH = 0x8A41;
static const GLenum GL_UNIFORM_BLOCK_ACTIVE_UNIFORMS = 0x8A42;
static const GLenum GL_UNIFORM_BLOCK_ACTIVE_UNIFORM_INDICES = 0x8A43;
static const GLenum GL_UNIFORM_BLOCK_REFERENCED_BY_VERTEX_SHADER = 0x8A44;
static const GLenum GL_UNIFORM_BLOCK_REFERENCED_BY_GEOMETRY_SHADER = 0x8A45;
static const GLenum GL_UNIFORM_BLOCK_REFERENCED_BY_FRAGMENT_SHADER = 0x8A46;
static const GLenum GL_INVALID_INDEX = 0xFFFFFFFFu;

static const GLenum GL_COPY_READ_BUFFER_BINDING = 0x8F36;
static const GLenum GL_COPY_READ_BUFFER = GL_COPY_READ_BUFFER_BINDING;
static const GLenum GL_COPY_WRITE_BUFFER_BINDING = 0x8F37;
static const GLenum GL_COPY_WRITE_BUFFER = GL_COPY_WRITE_BUFFER_BINDING;

static const GLenum GL_DEPTH_CLAMP = 0x864F;

static const GLenum GL_QUADS_FOLLOW_PROVOKING_VERTEX_CONVENTION = 0x8E4C;
static const GLenum GL_FIRST_VERTEX_CONVENTION = 0x8E4D;
static const GLenum GL_LAST_VERTEX_CONVENTION = 0x8E4E;
static const GLenum GL_PROVOKING_VERTEX = 0x8E4F;

static const GLenum GL_TEXTURE_CUBE_MAP_SEAMLESS = 0x884F;

static const GLenum GL_MAX_SERVER_WAIT_TIMEOUT = 0x9111;
static const GLenum GL_OBJECT_TYPE = 0x9112;
static const GLenum GL_SYNC_CONDITION = 0x9113;
static const GLenum GL_SYNC_STATUS = 0x9114;
static const GLenum GL_SYNC_FLAGS = 0x9115;
static const GLenum GL_SYNC_FENCE = 0x9116;
static const GLenum GL_SYNC_GPU_COMMANDS_COMPLETE = 0x9117;
static const GLenum GL_UNSIGNALED = 0x9118;
static const GLenum GL_SIGNALED = 0x9119;
static const GLenum GL_ALREADY_SIGNALED = 0x911A;
static const GLenum GL_TIMEOUT_EXPIRED = 0x911B;
static const GLenum GL_CONDITION_SATISFIED = 0x911C;
static const GLenum GL_WAIT_FAILED = 0x911D;
static const GLenum GL_SYNC_FLUSH_COMMANDS_BIT = 0x00000001;
// TODO luajit doesn't like this 
// static const GLuint64 GL_TIMEOUT_IGNORED = 0xFFFFFFFFFFFFFFFF;

static const GLenum GL_SAMPLE_POSITION = 0x8E50;
static const GLenum GL_SAMPLE_MASK = 0x8E51;
static const GLenum GL_SAMPLE_MASK_VALUE = 0x8E52;
static const GLenum GL_MAX_SAMPLE_MASK_WORDS = 0x8E59;
static const GLenum GL_TEXTURE_2D_MULTISAMPLE = 0x9100;
static const GLenum GL_PROXY_TEXTURE_2D_MULTISAMPLE = 0x9101;
static const GLenum GL_TEXTURE_2D_MULTISAMPLE_ARRAY = 0x9102;
static const GLenum GL_PROXY_TEXTURE_2D_MULTISAMPLE_ARRAY = 0x9103;
static const GLenum GL_TEXTURE_BINDING_2D_MULTISAMPLE = 0x9104;
static const GLenum GL_TEXTURE_BINDING_2D_MULTISAMPLE_ARRAY = 0x9105;
static const GLenum GL_TEXTURE_SAMPLES = 0x9106;
static const GLenum GL_TEXTURE_FIXED_SAMPLE_LOCATIONS = 0x9107;
static const GLenum GL_SAMPLER_2D_MULTISAMPLE = 0x9108;
static const GLenum GL_INT_SAMPLER_2D_MULTISAMPLE = 0x9109;
static const GLenum GL_UNSIGNED_INT_SAMPLER_2D_MULTISAMPLE = 0x910A;
static const GLenum GL_SAMPLER_2D_MULTISAMPLE_ARRAY = 0x910B;
static const GLenum GL_INT_SAMPLER_2D_MULTISAMPLE_ARRAY = 0x910C;
static const GLenum GL_UNSIGNED_INT_SAMPLER_2D_MULTISAMPLE_ARRAY = 0x910D;
static const GLenum GL_MAX_COLOR_TEXTURE_SAMPLES = 0x910E;
static const GLenum GL_MAX_DEPTH_TEXTURE_SAMPLES = 0x910F;
static const GLenum GL_MAX_INTEGER_SAMPLES = 0x9110;

static const GLenum GL_SAMPLE_SHADING_ARB = 0x8C36;
static const GLenum GL_MIN_SAMPLE_SHADING_VALUE_ARB = 0x8C37;

static const GLenum GL_TEXTURE_CUBE_MAP_ARRAY_ARB = 0x9009;
static const GLenum GL_TEXTURE_BINDING_CUBE_MAP_ARRAY_ARB = 0x900A;
static const GLenum GL_PROXY_TEXTURE_CUBE_MAP_ARRAY_ARB = 0x900B;
static const GLenum GL_SAMPLER_CUBE_MAP_ARRAY_ARB = 0x900C;
static const GLenum GL_SAMPLER_CUBE_MAP_ARRAY_SHADOW_ARB = 0x900D;
static const GLenum GL_INT_SAMPLER_CUBE_MAP_ARRAY_ARB = 0x900E;
static const GLenum GL_UNSIGNED_INT_SAMPLER_CUBE_MAP_ARRAY_ARB = 0x900F;

static const GLenum GL_MIN_PROGRAM_TEXTURE_GATHER_OFFSET_ARB = 0x8E5E;
static const GLenum GL_MAX_PROGRAM_TEXTURE_GATHER_OFFSET_ARB = 0x8E5F;

static const GLenum GL_SHADER_INCLUDE_ARB = 0x8DAE;
static const GLenum GL_NAMED_STRING_LENGTH_ARB = 0x8DE9;
static const GLenum GL_NAMED_STRING_TYPE_ARB = 0x8DEA;

static const GLenum GL_COMPRESSED_RGBA_BPTC_UNORM_ARB = 0x8E8C;
static const GLenum GL_COMPRESSED_SRGB_ALPHA_BPTC_UNORM_ARB = 0x8E8D;
static const GLenum GL_COMPRESSED_RGB_BPTC_SIGNED_FLOAT_ARB = 0x8E8E;
static const GLenum GL_COMPRESSED_RGB_BPTC_UNSIGNED_FLOAT_ARB = 0x8E8F;

static const GLenum GL_SRC1_COLOR = 0x88F9;
static const GLenum GL_ONE_MINUS_SRC1_COLOR = 0x88FA;
static const GLenum GL_ONE_MINUS_SRC1_ALPHA = 0x88FB;
static const GLenum GL_MAX_DUAL_SOURCE_DRAW_BUFFERS = 0x88FC;

static const GLenum GL_ANY_SAMPLES_PASSED = 0x8C2F;

static const GLenum GL_SAMPLER_BINDING = 0x8919;

static const GLenum GL_RGB10_A2UI = 0x906F;

static const GLenum GL_TEXTURE_SWIZZLE_R = 0x8E42;
static const GLenum GL_TEXTURE_SWIZZLE_G = 0x8E43;
static const GLenum GL_TEXTURE_SWIZZLE_B = 0x8E44;
static const GLenum GL_TEXTURE_SWIZZLE_A = 0x8E45;
static const GLenum GL_TEXTURE_SWIZZLE_RGBA = 0x8E46;

static const GLenum GL_TIME_ELAPSED = 0x88BF;
static const GLenum GL_TIMESTAMP = 0x8E28;

static const GLenum GL_INT_2_10_10_10_REV = 0x8D9F;

static const GLenum GL_DRAW_INDIRECT_BUFFER = 0x8F3F;
static const GLenum GL_DRAW_INDIRECT_BUFFER_BINDING = 0x8F43;

static const GLenum GL_GEOMETRY_SHADER_INVOCATIONS = 0x887F;
static const GLenum GL_MAX_GEOMETRY_SHADER_INVOCATIONS = 0x8E5A;
static const GLenum GL_MIN_FRAGMENT_INTERPOLATION_OFFSET = 0x8E5B;
static const GLenum GL_MAX_FRAGMENT_INTERPOLATION_OFFSET = 0x8E5C;
static const GLenum GL_FRAGMENT_INTERPOLATION_OFFSET_BITS = 0x8E5D;

static const GLenum GL_DOUBLE_VEC2 = 0x8FFC;
static const GLenum GL_DOUBLE_VEC3 = 0x8FFD;
static const GLenum GL_DOUBLE_VEC4 = 0x8FFE;
static const GLenum GL_DOUBLE_MAT2 = 0x8F46;
static const GLenum GL_DOUBLE_MAT3 = 0x8F47;
static const GLenum GL_DOUBLE_MAT4 = 0x8F48;
static const GLenum GL_DOUBLE_MAT2x3 = 0x8F49;
static const GLenum GL_DOUBLE_MAT2x4 = 0x8F4A;
static const GLenum GL_DOUBLE_MAT3x2 = 0x8F4B;
static const GLenum GL_DOUBLE_MAT3x4 = 0x8F4C;
static const GLenum GL_DOUBLE_MAT4x2 = 0x8F4D;
static const GLenum GL_DOUBLE_MAT4x3 = 0x8F4E;

static const GLenum GL_ACTIVE_SUBROUTINES = 0x8DE5;
static const GLenum GL_ACTIVE_SUBROUTINE_UNIFORMS = 0x8DE6;
static const GLenum GL_ACTIVE_SUBROUTINE_UNIFORM_LOCATIONS = 0x8E47;
static const GLenum GL_ACTIVE_SUBROUTINE_MAX_LENGTH = 0x8E48;
static const GLenum GL_ACTIVE_SUBROUTINE_UNIFORM_MAX_LENGTH = 0x8E49;
static const GLenum GL_MAX_SUBROUTINES = 0x8DE7;
static const GLenum GL_MAX_SUBROUTINE_UNIFORM_LOCATIONS = 0x8DE8;
static const GLenum GL_NUM_COMPATIBLE_SUBROUTINES = 0x8E4A;
static const GLenum GL_COMPATIBLE_SUBROUTINES = 0x8E4B;

static const GLenum GL_PATCHES = 0x000E;
static const GLenum GL_PATCH_VERTICES = 0x8E72;
static const GLenum GL_PATCH_DEFAULT_INNER_LEVEL = 0x8E73;
static const GLenum GL_PATCH_DEFAULT_OUTER_LEVEL = 0x8E74;
static const GLenum GL_TESS_CONTROL_OUTPUT_VERTICES = 0x8E75;
static const GLenum GL_TESS_GEN_MODE = 0x8E76;
static const GLenum GL_TESS_GEN_SPACING = 0x8E77;
static const GLenum GL_TESS_GEN_VERTEX_ORDER = 0x8E78;
static const GLenum GL_TESS_GEN_POINT_MODE = 0x8E79;
static const GLenum GL_ISOLINES = 0x8E7A;
static const GLenum GL_FRACTIONAL_ODD = 0x8E7B;
static const GLenum GL_FRACTIONAL_EVEN = 0x8E7C;
static const GLenum GL_MAX_PATCH_VERTICES = 0x8E7D;
static const GLenum GL_MAX_TESS_GEN_LEVEL = 0x8E7E;
static const GLenum GL_MAX_TESS_CONTROL_UNIFORM_COMPONENTS = 0x8E7F;
static const GLenum GL_MAX_TESS_EVALUATION_UNIFORM_COMPONENTS = 0x8E80;
static const GLenum GL_MAX_TESS_CONTROL_TEXTURE_IMAGE_UNITS = 0x8E81;
static const GLenum GL_MAX_TESS_EVALUATION_TEXTURE_IMAGE_UNITS = 0x8E82;
static const GLenum GL_MAX_TESS_CONTROL_OUTPUT_COMPONENTS = 0x8E83;
static const GLenum GL_MAX_TESS_PATCH_COMPONENTS = 0x8E84;
static const GLenum GL_MAX_TESS_CONTROL_TOTAL_OUTPUT_COMPONENTS = 0x8E85;
static const GLenum GL_MAX_TESS_EVALUATION_OUTPUT_COMPONENTS = 0x8E86;
static const GLenum GL_MAX_TESS_CONTROL_UNIFORM_BLOCKS = 0x8E89;
static const GLenum GL_MAX_TESS_EVALUATION_UNIFORM_BLOCKS = 0x8E8A;
static const GLenum GL_MAX_TESS_CONTROL_INPUT_COMPONENTS = 0x886C;
static const GLenum GL_MAX_TESS_EVALUATION_INPUT_COMPONENTS = 0x886D;
static const GLenum GL_MAX_COMBINED_TESS_CONTROL_UNIFORM_COMPONENTS = 0x8E1E;
static const GLenum GL_MAX_COMBINED_TESS_EVALUATION_UNIFORM_COMPONENTS = 0x8E1F;
static const GLenum GL_UNIFORM_BLOCK_REFERENCED_BY_TESS_CONTROL_SHADER = 0x84F0;
static const GLenum GL_UNIFORM_BLOCK_REFERENCED_BY_TESS_EVALUATION_SHADER = 0x84F1;
static const GLenum GL_TESS_EVALUATION_SHADER = 0x8E87;
static const GLenum GL_TESS_CONTROL_SHADER = 0x8E88;

static const GLenum GL_TRANSFORM_FEEDBACK = 0x8E22;
static const GLenum GL_TRANSFORM_FEEDBACK_PAUSED = 0x8E23;
static const GLenum GL_TRANSFORM_FEEDBACK_BUFFER_PAUSED = GL_TRANSFORM_FEEDBACK_PAUSED;
static const GLenum GL_TRANSFORM_FEEDBACK_ACTIVE = 0x8E24;
static const GLenum GL_TRANSFORM_FEEDBACK_BUFFER_ACTIVE = GL_TRANSFORM_FEEDBACK_ACTIVE;
static const GLenum GL_TRANSFORM_FEEDBACK_BINDING = 0x8E25;

static const GLenum GL_MAX_TRANSFORM_FEEDBACK_BUFFERS = 0x8E70;
static const GLenum GL_MAX_VERTEX_STREAMS = 0x8E71;

static const GLenum GL_FIXED = 0x140C;
static const GLenum GL_IMPLEMENTATION_COLOR_READ_TYPE = 0x8B9A;
static const GLenum GL_IMPLEMENTATION_COLOR_READ_FORMAT = 0x8B9B;
static const GLenum GL_LOW_FLOAT = 0x8DF0;
static const GLenum GL_MEDIUM_FLOAT = 0x8DF1;
static const GLenum GL_HIGH_FLOAT = 0x8DF2;
static const GLenum GL_LOW_INT = 0x8DF3;
static const GLenum GL_MEDIUM_INT = 0x8DF4;
static const GLenum GL_HIGH_INT = 0x8DF5;
static const GLenum GL_SHADER_COMPILER = 0x8DFA;
static const GLenum GL_NUM_SHADER_BINARY_FORMATS = 0x8DF9;
static const GLenum GL_MAX_VERTEX_UNIFORM_VECTORS = 0x8DFB;
static const GLenum GL_MAX_VARYING_VECTORS = 0x8DFC;
static const GLenum GL_MAX_FRAGMENT_UNIFORM_VECTORS = 0x8DFD;
static const GLenum GL_RGB565 = 0x8D62;

static const GLenum GL_PROGRAM_BINARY_RETRIEVABLE_HINT = 0x8257;
static const GLenum GL_PROGRAM_BINARY_LENGTH = 0x8741;
static const GLenum GL_NUM_PROGRAM_BINARY_FORMATS = 0x87FE;
static const GLenum GL_PROGRAM_BINARY_FORMATS = 0x87FF;

static const GLenum GL_VERTEX_SHADER_BIT = 0x00000001;
static const GLenum GL_FRAGMENT_SHADER_BIT = 0x00000002;
static const GLenum GL_GEOMETRY_SHADER_BIT = 0x00000004;
static const GLenum GL_TESS_CONTROL_SHADER_BIT = 0x00000008;
static const GLenum GL_TESS_EVALUATION_SHADER_BIT = 0x00000010;
static const GLenum GL_ALL_SHADER_BITS = 0xFFFFFFFF;
static const GLenum GL_PROGRAM_SEPARABLE = 0x8258;
static const GLenum GL_ACTIVE_PROGRAM = 0x8259;
static const GLenum GL_PROGRAM_PIPELINE_BINDING = 0x825A;

static const GLenum GL_MAX_VIEWPORTS = 0x825B;
static const GLenum GL_VIEWPORT_SUBPIXEL_BITS = 0x825C;
static const GLenum GL_VIEWPORT_BOUNDS_RANGE = 0x825D;
static const GLenum GL_LAYER_PROVOKING_VERTEX = 0x825E;
static const GLenum GL_VIEWPORT_INDEX_PROVOKING_VERTEX = 0x825F;
static const GLenum GL_UNDEFINED_VERTEX = 0x8260;

static const GLenum GL_SYNC_CL_EVENT_ARB = 0x8240;
static const GLenum GL_SYNC_CL_EVENT_COMPLETE_ARB = 0x8241;

static const GLenum GL_DEBUG_OUTPUT_SYNCHRONOUS_ARB = 0x8242;
static const GLenum GL_DEBUG_NEXT_LOGGED_MESSAGE_LENGTH_ARB = 0x8243;
static const GLenum GL_DEBUG_CALLBACK_FUNCTION_ARB = 0x8244;
static const GLenum GL_DEBUG_CALLBACK_USER_PARAM_ARB = 0x8245;
static const GLenum GL_DEBUG_SOURCE_API_ARB = 0x8246;
static const GLenum GL_DEBUG_SOURCE_WINDOW_SYSTEM_ARB = 0x8247;
static const GLenum GL_DEBUG_SOURCE_SHADER_COMPILER_ARB = 0x8248;
static const GLenum GL_DEBUG_SOURCE_THIRD_PARTY_ARB = 0x8249;
static const GLenum GL_DEBUG_SOURCE_APPLICATION_ARB = 0x824A;
static const GLenum GL_DEBUG_SOURCE_OTHER_ARB = 0x824B;
static const GLenum GL_DEBUG_TYPE_ERROR_ARB = 0x824C;
static const GLenum GL_DEBUG_TYPE_DEPRECATED_BEHAVIOR_ARB = 0x824D;
static const GLenum GL_DEBUG_TYPE_UNDEFINED_BEHAVIOR_ARB = 0x824E;
static const GLenum GL_DEBUG_TYPE_PORTABILITY_ARB = 0x824F;
static const GLenum GL_DEBUG_TYPE_PERFORMANCE_ARB = 0x8250;
static const GLenum GL_DEBUG_TYPE_OTHER_ARB = 0x8251;
static const GLenum GL_MAX_DEBUG_MESSAGE_LENGTH_ARB = 0x9143;
static const GLenum GL_MAX_DEBUG_LOGGED_MESSAGES_ARB = 0x9144;
static const GLenum GL_DEBUG_LOGGED_MESSAGES_ARB = 0x9145;
static const GLenum GL_DEBUG_SEVERITY_HIGH_ARB = 0x9146;
static const GLenum GL_DEBUG_SEVERITY_MEDIUM_ARB = 0x9147;
static const GLenum GL_DEBUG_SEVERITY_LOW_ARB = 0x9148;

static const GLenum GL_CONTEXT_FLAG_ROBUST_ACCESS_BIT_ARB = 0x00000004;
static const GLenum GL_LOSE_CONTEXT_ON_RESET_ARB = 0x8252;
static const GLenum GL_GUILTY_CONTEXT_RESET_ARB = 0x8253;
static const GLenum GL_INNOCENT_CONTEXT_RESET_ARB = 0x8254;
static const GLenum GL_UNKNOWN_CONTEXT_RESET_ARB = 0x8255;
static const GLenum GL_RESET_NOTIFICATION_STRATEGY_ARB = 0x8256;
static const GLenum GL_NO_RESET_NOTIFICATION_ARB = 0x8261;

static const GLenum GL_UNPACK_COMPRESSED_BLOCK_WIDTH = 0x9127;
static const GLenum GL_UNPACK_COMPRESSED_BLOCK_HEIGHT = 0x9128;
static const GLenum GL_UNPACK_COMPRESSED_BLOCK_DEPTH = 0x9129;
static const GLenum GL_UNPACK_COMPRESSED_BLOCK_SIZE = 0x912A;
static const GLenum GL_PACK_COMPRESSED_BLOCK_WIDTH = 0x912B;
static const GLenum GL_PACK_COMPRESSED_BLOCK_HEIGHT = 0x912C;
static const GLenum GL_PACK_COMPRESSED_BLOCK_DEPTH = 0x912D;
static const GLenum GL_PACK_COMPRESSED_BLOCK_SIZE = 0x912E;

static const GLenum GL_NUM_SAMPLE_COUNTS = 0x9380;

static const GLenum GL_MIN_MAP_BUFFER_ALIGNMENT = 0x90BC;

static const GLenum GL_ATOMIC_COUNTER_BUFFER = 0x92C0;
static const GLenum GL_ATOMIC_COUNTER_BUFFER_BINDING = 0x92C1;
static const GLenum GL_ATOMIC_COUNTER_BUFFER_START = 0x92C2;
static const GLenum GL_ATOMIC_COUNTER_BUFFER_SIZE = 0x92C3;
static const GLenum GL_ATOMIC_COUNTER_BUFFER_DATA_SIZE = 0x92C4;
static const GLenum GL_ATOMIC_COUNTER_BUFFER_ACTIVE_ATOMIC_COUNTERS = 0x92C5;
static const GLenum GL_ATOMIC_COUNTER_BUFFER_ACTIVE_ATOMIC_COUNTER_INDICES = 0x92C6;
static const GLenum GL_ATOMIC_COUNTER_BUFFER_REFERENCED_BY_VERTEX_SHADER = 0x92C7;
static const GLenum GL_ATOMIC_COUNTER_BUFFER_REFERENCED_BY_TESS_CONTROL_SHADER = 0x92C8;
static const GLenum GL_ATOMIC_COUNTER_BUFFER_REFERENCED_BY_TESS_EVALUATION_SHADER = 0x92C9;
static const GLenum GL_ATOMIC_COUNTER_BUFFER_REFERENCED_BY_GEOMETRY_SHADER = 0x92CA;
static const GLenum GL_ATOMIC_COUNTER_BUFFER_REFERENCED_BY_FRAGMENT_SHADER = 0x92CB;
static const GLenum GL_MAX_VERTEX_ATOMIC_COUNTER_BUFFERS = 0x92CC;
static const GLenum GL_MAX_TESS_CONTROL_ATOMIC_COUNTER_BUFFERS = 0x92CD;
static const GLenum GL_MAX_TESS_EVALUATION_ATOMIC_COUNTER_BUFFERS = 0x92CE;
static const GLenum GL_MAX_GEOMETRY_ATOMIC_COUNTER_BUFFERS = 0x92CF;
static const GLenum GL_MAX_FRAGMENT_ATOMIC_COUNTER_BUFFERS = 0x92D0;
static const GLenum GL_MAX_COMBINED_ATOMIC_COUNTER_BUFFERS = 0x92D1;
static const GLenum GL_MAX_VERTEX_ATOMIC_COUNTERS = 0x92D2;
static const GLenum GL_MAX_TESS_CONTROL_ATOMIC_COUNTERS = 0x92D3;
static const GLenum GL_MAX_TESS_EVALUATION_ATOMIC_COUNTERS = 0x92D4;
static const GLenum GL_MAX_GEOMETRY_ATOMIC_COUNTERS = 0x92D5;
static const GLenum GL_MAX_FRAGMENT_ATOMIC_COUNTERS = 0x92D6;
static const GLenum GL_MAX_COMBINED_ATOMIC_COUNTERS = 0x92D7;
static const GLenum GL_MAX_ATOMIC_COUNTER_BUFFER_SIZE = 0x92D8;
static const GLenum GL_MAX_ATOMIC_COUNTER_BUFFER_BINDINGS = 0x92DC;
static const GLenum GL_ACTIVE_ATOMIC_COUNTER_BUFFERS = 0x92D9;
static const GLenum GL_UNIFORM_ATOMIC_COUNTER_BUFFER_INDEX = 0x92DA;
static const GLenum GL_UNSIGNED_INT_ATOMIC_COUNTER = 0x92DB;

static const GLenum GL_VERTEX_ATTRIB_ARRAY_BARRIER_BIT = 0x00000001;
static const GLenum GL_ELEMENT_ARRAY_BARRIER_BIT = 0x00000002;
static const GLenum GL_UNIFORM_BARRIER_BIT = 0x00000004;
static const GLenum GL_TEXTURE_FETCH_BARRIER_BIT = 0x00000008;
static const GLenum GL_SHADER_IMAGE_ACCESS_BARRIER_BIT = 0x00000020;
static const GLenum GL_COMMAND_BARRIER_BIT = 0x00000040;
static const GLenum GL_PIXEL_BUFFER_BARRIER_BIT = 0x00000080;
static const GLenum GL_TEXTURE_UPDATE_BARRIER_BIT = 0x00000100;
static const GLenum GL_BUFFER_UPDATE_BARRIER_BIT = 0x00000200;
static const GLenum GL_FRAMEBUFFER_BARRIER_BIT = 0x00000400;
static const GLenum GL_TRANSFORM_FEEDBACK_BARRIER_BIT = 0x00000800;
static const GLenum GL_ATOMIC_COUNTER_BARRIER_BIT = 0x00001000;
static const GLenum GL_ALL_BARRIER_BITS = 0xFFFFFFFF;
static const GLenum GL_MAX_IMAGE_UNITS = 0x8F38;
static const GLenum GL_MAX_COMBINED_IMAGE_UNITS_AND_FRAGMENT_OUTPUTS = 0x8F39;
static const GLenum GL_IMAGE_BINDING_NAME = 0x8F3A;
static const GLenum GL_IMAGE_BINDING_LEVEL = 0x8F3B;
static const GLenum GL_IMAGE_BINDING_LAYERED = 0x8F3C;
static const GLenum GL_IMAGE_BINDING_LAYER = 0x8F3D;
static const GLenum GL_IMAGE_BINDING_ACCESS = 0x8F3E;
static const GLenum GL_IMAGE_1D = 0x904C;
static const GLenum GL_IMAGE_2D = 0x904D;
static const GLenum GL_IMAGE_3D = 0x904E;
static const GLenum GL_IMAGE_2D_RECT = 0x904F;
static const GLenum GL_IMAGE_CUBE = 0x9050;
static const GLenum GL_IMAGE_BUFFER = 0x9051;
static const GLenum GL_IMAGE_1D_ARRAY = 0x9052;
static const GLenum GL_IMAGE_2D_ARRAY = 0x9053;
static const GLenum GL_IMAGE_CUBE_MAP_ARRAY = 0x9054;
static const GLenum GL_IMAGE_2D_MULTISAMPLE = 0x9055;
static const GLenum GL_IMAGE_2D_MULTISAMPLE_ARRAY = 0x9056;
static const GLenum GL_INT_IMAGE_1D = 0x9057;
static const GLenum GL_INT_IMAGE_2D = 0x9058;
static const GLenum GL_INT_IMAGE_3D = 0x9059;
static const GLenum GL_INT_IMAGE_2D_RECT = 0x905A;
static const GLenum GL_INT_IMAGE_CUBE = 0x905B;
static const GLenum GL_INT_IMAGE_BUFFER = 0x905C;
static const GLenum GL_INT_IMAGE_1D_ARRAY = 0x905D;
static const GLenum GL_INT_IMAGE_2D_ARRAY = 0x905E;
static const GLenum GL_INT_IMAGE_CUBE_MAP_ARRAY = 0x905F;
static const GLenum GL_INT_IMAGE_2D_MULTISAMPLE = 0x9060;
static const GLenum GL_INT_IMAGE_2D_MULTISAMPLE_ARRAY = 0x9061;
static const GLenum GL_UNSIGNED_INT_IMAGE_1D = 0x9062;
static const GLenum GL_UNSIGNED_INT_IMAGE_2D = 0x9063;
static const GLenum GL_UNSIGNED_INT_IMAGE_3D = 0x9064;
static const GLenum GL_UNSIGNED_INT_IMAGE_2D_RECT = 0x9065;
static const GLenum GL_UNSIGNED_INT_IMAGE_CUBE = 0x9066;
static const GLenum GL_UNSIGNED_INT_IMAGE_BUFFER = 0x9067;
static const GLenum GL_UNSIGNED_INT_IMAGE_1D_ARRAY = 0x9068;
static const GLenum GL_UNSIGNED_INT_IMAGE_2D_ARRAY = 0x9069;
static const GLenum GL_UNSIGNED_INT_IMAGE_CUBE_MAP_ARRAY = 0x906A;
static const GLenum GL_UNSIGNED_INT_IMAGE_2D_MULTISAMPLE = 0x906B;
static const GLenum GL_UNSIGNED_INT_IMAGE_2D_MULTISAMPLE_ARRAY = 0x906C;
static const GLenum GL_MAX_IMAGE_SAMPLES = 0x906D;
static const GLenum GL_IMAGE_BINDING_FORMAT = 0x906E;
static const GLenum GL_IMAGE_FORMAT_COMPATIBILITY_TYPE = 0x90C7;
static const GLenum GL_IMAGE_FORMAT_COMPATIBILITY_BY_SIZE = 0x90C8;
static const GLenum GL_IMAGE_FORMAT_COMPATIBILITY_BY_CLASS = 0x90C9;
static const GLenum GL_MAX_VERTEX_IMAGE_UNIFORMS = 0x90CA;
static const GLenum GL_MAX_TESS_CONTROL_IMAGE_UNIFORMS = 0x90CB;
static const GLenum GL_MAX_TESS_EVALUATION_IMAGE_UNIFORMS = 0x90CC;
static const GLenum GL_MAX_GEOMETRY_IMAGE_UNIFORMS = 0x90CD;
static const GLenum GL_MAX_FRAGMENT_IMAGE_UNIFORMS = 0x90CE;
static const GLenum GL_MAX_COMBINED_IMAGE_UNIFORMS = 0x90CF;

static const GLenum GL_TEXTURE_IMMUTABLE_FORMAT = 0x912F;

static const GLenum GL_COMPRESSED_RGBA_ASTC_4x4_KHR = 0x93B0;
static const GLenum GL_COMPRESSED_RGBA_ASTC_5x4_KHR = 0x93B1;
static const GLenum GL_COMPRESSED_RGBA_ASTC_5x5_KHR = 0x93B2;
static const GLenum GL_COMPRESSED_RGBA_ASTC_6x5_KHR = 0x93B3;
static const GLenum GL_COMPRESSED_RGBA_ASTC_6x6_KHR = 0x93B4;
static const GLenum GL_COMPRESSED_RGBA_ASTC_8x5_KHR = 0x93B5;
static const GLenum GL_COMPRESSED_RGBA_ASTC_8x6_KHR = 0x93B6;
static const GLenum GL_COMPRESSED_RGBA_ASTC_8x8_KHR = 0x93B7;
static const GLenum GL_COMPRESSED_RGBA_ASTC_10x5_KHR = 0x93B8;
static const GLenum GL_COMPRESSED_RGBA_ASTC_10x6_KHR = 0x93B9;
static const GLenum GL_COMPRESSED_RGBA_ASTC_10x8_KHR = 0x93BA;
static const GLenum GL_COMPRESSED_RGBA_ASTC_10x10_KHR = 0x93BB;
static const GLenum GL_COMPRESSED_RGBA_ASTC_12x10_KHR = 0x93BC;
static const GLenum GL_COMPRESSED_RGBA_ASTC_12x12_KHR = 0x93BD;
static const GLenum GL_COMPRESSED_SRGB8_ALPHA8_ASTC_4x4_KHR = 0x93D0;
static const GLenum GL_COMPRESSED_SRGB8_ALPHA8_ASTC_5x4_KHR = 0x93D1;
static const GLenum GL_COMPRESSED_SRGB8_ALPHA8_ASTC_5x5_KHR = 0x93D2;
static const GLenum GL_COMPRESSED_SRGB8_ALPHA8_ASTC_6x5_KHR = 0x93D3;
static const GLenum GL_COMPRESSED_SRGB8_ALPHA8_ASTC_6x6_KHR = 0x93D4;
static const GLenum GL_COMPRESSED_SRGB8_ALPHA8_ASTC_8x5_KHR = 0x93D5;
static const GLenum GL_COMPRESSED_SRGB8_ALPHA8_ASTC_8x6_KHR = 0x93D6;
static const GLenum GL_COMPRESSED_SRGB8_ALPHA8_ASTC_8x8_KHR = 0x93D7;
static const GLenum GL_COMPRESSED_SRGB8_ALPHA8_ASTC_10x5_KHR = 0x93D8;
static const GLenum GL_COMPRESSED_SRGB8_ALPHA8_ASTC_10x6_KHR = 0x93D9;
static const GLenum GL_COMPRESSED_SRGB8_ALPHA8_ASTC_10x8_KHR = 0x93DA;
static const GLenum GL_COMPRESSED_SRGB8_ALPHA8_ASTC_10x10_KHR = 0x93DB;
static const GLenum GL_COMPRESSED_SRGB8_ALPHA8_ASTC_12x10_KHR = 0x93DC;
static const GLenum GL_COMPRESSED_SRGB8_ALPHA8_ASTC_12x12_KHR = 0x93DD;

static const GLenum GL_DEBUG_OUTPUT_SYNCHRONOUS = 0x8242;
static const GLenum GL_DEBUG_NEXT_LOGGED_MESSAGE_LENGTH = 0x8243;
static const GLenum GL_DEBUG_CALLBACK_FUNCTION = 0x8244;
static const GLenum GL_DEBUG_CALLBACK_USER_PARAM = 0x8245;
static const GLenum GL_DEBUG_SOURCE_API = 0x8246;
static const GLenum GL_DEBUG_SOURCE_WINDOW_SYSTEM = 0x8247;
static const GLenum GL_DEBUG_SOURCE_SHADER_COMPILER = 0x8248;
static const GLenum GL_DEBUG_SOURCE_THIRD_PARTY = 0x8249;
static const GLenum GL_DEBUG_SOURCE_APPLICATION = 0x824A;
static const GLenum GL_DEBUG_SOURCE_OTHER = 0x824B;
static const GLenum GL_DEBUG_TYPE_ERROR = 0x824C;
static const GLenum GL_DEBUG_TYPE_DEPRECATED_BEHAVIOR = 0x824D;
static const GLenum GL_DEBUG_TYPE_UNDEFINED_BEHAVIOR = 0x824E;
static const GLenum GL_DEBUG_TYPE_PORTABILITY = 0x824F;
static const GLenum GL_DEBUG_TYPE_PERFORMANCE = 0x8250;
static const GLenum GL_DEBUG_TYPE_OTHER = 0x8251;
static const GLenum GL_DEBUG_TYPE_MARKER = 0x8268;
static const GLenum GL_DEBUG_TYPE_PUSH_GROUP = 0x8269;
static const GLenum GL_DEBUG_TYPE_POP_GROUP = 0x826A;
static const GLenum GL_DEBUG_SEVERITY_NOTIFICATION = 0x826B;
static const GLenum GL_MAX_DEBUG_GROUP_STACK_DEPTH = 0x826C;
static const GLenum GL_DEBUG_GROUP_STACK_DEPTH = 0x826D;
static const GLenum GL_BUFFER = 0x82E0;
static const GLenum GL_SHADER = 0x82E1;
static const GLenum GL_PROGRAM = 0x82E2;
static const GLenum GL_QUERY = 0x82E3;
static const GLenum GL_PROGRAM_PIPELINE = 0x82E4;
static const GLenum GL_SAMPLER = 0x82E6;
static const GLenum GL_DISPLAY_LIST = 0x82E7;
static const GLenum GL_MAX_LABEL_LENGTH = 0x82E8;
static const GLenum GL_MAX_DEBUG_MESSAGE_LENGTH = 0x9143;
static const GLenum GL_MAX_DEBUG_LOGGED_MESSAGES = 0x9144;
static const GLenum GL_DEBUG_LOGGED_MESSAGES = 0x9145;
static const GLenum GL_DEBUG_SEVERITY_HIGH = 0x9146;
static const GLenum GL_DEBUG_SEVERITY_MEDIUM = 0x9147;
static const GLenum GL_DEBUG_SEVERITY_LOW = 0x9148;
static const GLenum GL_DEBUG_OUTPUT = 0x92E0;
static const GLenum GL_CONTEXT_FLAG_DEBUG_BIT = 0x00000002;

static const GLenum GL_COMPUTE_SHADER = 0x91B9;
static const GLenum GL_MAX_COMPUTE_UNIFORM_BLOCKS = 0x91BB;
static const GLenum GL_MAX_COMPUTE_TEXTURE_IMAGE_UNITS = 0x91BC;
static const GLenum GL_MAX_COMPUTE_IMAGE_UNIFORMS = 0x91BD;
static const GLenum GL_MAX_COMPUTE_SHARED_MEMORY_SIZE = 0x8262;
static const GLenum GL_MAX_COMPUTE_UNIFORM_COMPONENTS = 0x8263;
static const GLenum GL_MAX_COMPUTE_ATOMIC_COUNTER_BUFFERS = 0x8264;
static const GLenum GL_MAX_COMPUTE_ATOMIC_COUNTERS = 0x8265;
static const GLenum GL_MAX_COMBINED_COMPUTE_UNIFORM_COMPONENTS = 0x8266;
static const GLenum GL_MAX_COMPUTE_LOCAL_INVOCATIONS = 0x90EB;
static const GLenum GL_MAX_COMPUTE_WORK_GROUP_COUNT = 0x91BE;
static const GLenum GL_MAX_COMPUTE_WORK_GROUP_SIZE = 0x91BF;
static const GLenum GL_COMPUTE_LOCAL_WORK_SIZE = 0x8267;
static const GLenum GL_UNIFORM_BLOCK_REFERENCED_BY_COMPUTE_SHADER = 0x90EC;
static const GLenum GL_ATOMIC_COUNTER_BUFFER_REFERENCED_BY_COMPUTE_SHADER = 0x90ED;
static const GLenum GL_DISPATCH_INDIRECT_BUFFER = 0x90EE;
static const GLenum GL_DISPATCH_INDIRECT_BUFFER_BINDING = 0x90EF;
static const GLenum GL_COMPUTE_SHADER_BIT = 0x00000020;

static const GLenum GL_COMPRESSED_RGB8_ETC2 = 0x9274;
static const GLenum GL_COMPRESSED_SRGB8_ETC2 = 0x9275;
static const GLenum GL_COMPRESSED_RGB8_PUNCHTHROUGH_ALPHA1_ETC2 = 0x9276;
static const GLenum GL_COMPRESSED_SRGB8_PUNCHTHROUGH_ALPHA1_ETC2 = 0x9277;
static const GLenum GL_COMPRESSED_RGBA8_ETC2_EAC = 0x9278;
static const GLenum GL_COMPRESSED_SRGB8_ALPHA8_ETC2_EAC = 0x9279;
static const GLenum GL_COMPRESSED_R11_EAC = 0x9270;
static const GLenum GL_COMPRESSED_SIGNED_R11_EAC = 0x9271;
static const GLenum GL_COMPRESSED_RG11_EAC = 0x9272;
static const GLenum GL_COMPRESSED_SIGNED_RG11_EAC = 0x9273;
static const GLenum GL_PRIMITIVE_RESTART_FIXED_INDEX = 0x8D69;
static const GLenum GL_ANY_SAMPLES_PASSED_CONSERVATIVE = 0x8D6A;
static const GLenum GL_MAX_ELEMENT_INDEX = 0x8D6B;

static const GLenum GL_MAX_UNIFORM_LOCATIONS = 0x826E;

static const GLenum GL_FRAMEBUFFER_DEFAULT_WIDTH = 0x9310;
static const GLenum GL_FRAMEBUFFER_DEFAULT_HEIGHT = 0x9311;
static const GLenum GL_FRAMEBUFFER_DEFAULT_LAYERS = 0x9312;
static const GLenum GL_FRAMEBUFFER_DEFAULT_SAMPLES = 0x9313;
static const GLenum GL_FRAMEBUFFER_DEFAULT_FIXED_SAMPLE_LOCATIONS = 0x9314;
static const GLenum GL_MAX_FRAMEBUFFER_WIDTH = 0x9315;
static const GLenum GL_MAX_FRAMEBUFFER_HEIGHT = 0x9316;
static const GLenum GL_MAX_FRAMEBUFFER_LAYERS = 0x9317;
static const GLenum GL_MAX_FRAMEBUFFER_SAMPLES = 0x9318;

static const GLenum GL_INTERNALFORMAT_SUPPORTED = 0x826F;
static const GLenum GL_INTERNALFORMAT_PREFERRED = 0x8270;
static const GLenum GL_INTERNALFORMAT_RED_SIZE = 0x8271;
static const GLenum GL_INTERNALFORMAT_GREEN_SIZE = 0x8272;
static const GLenum GL_INTERNALFORMAT_BLUE_SIZE = 0x8273;
static const GLenum GL_INTERNALFORMAT_ALPHA_SIZE = 0x8274;
static const GLenum GL_INTERNALFORMAT_DEPTH_SIZE = 0x8275;
static const GLenum GL_INTERNALFORMAT_STENCIL_SIZE = 0x8276;
static const GLenum GL_INTERNALFORMAT_SHARED_SIZE = 0x8277;
static const GLenum GL_INTERNALFORMAT_RED_TYPE = 0x8278;
static const GLenum GL_INTERNALFORMAT_GREEN_TYPE = 0x8279;
static const GLenum GL_INTERNALFORMAT_BLUE_TYPE = 0x827A;
static const GLenum GL_INTERNALFORMAT_ALPHA_TYPE = 0x827B;
static const GLenum GL_INTERNALFORMAT_DEPTH_TYPE = 0x827C;
static const GLenum GL_INTERNALFORMAT_STENCIL_TYPE = 0x827D;
static const GLenum GL_MAX_WIDTH = 0x827E;
static const GLenum GL_MAX_HEIGHT = 0x827F;
static const GLenum GL_MAX_DEPTH = 0x8280;
static const GLenum GL_MAX_LAYERS = 0x8281;
static const GLenum GL_MAX_COMBINED_DIMENSIONS = 0x8282;
static const GLenum GL_COLOR_COMPONENTS = 0x8283;
static const GLenum GL_DEPTH_COMPONENTS = 0x8284;
static const GLenum GL_STENCIL_COMPONENTS = 0x8285;
static const GLenum GL_COLOR_RENDERABLE = 0x8286;
static const GLenum GL_DEPTH_RENDERABLE = 0x8287;
static const GLenum GL_STENCIL_RENDERABLE = 0x8288;
static const GLenum GL_FRAMEBUFFER_RENDERABLE = 0x8289;
static const GLenum GL_FRAMEBUFFER_RENDERABLE_LAYERED = 0x828A;
static const GLenum GL_FRAMEBUFFER_BLEND = 0x828B;
static const GLenum GL_READ_PIXELS = 0x828C;
static const GLenum GL_READ_PIXELS_FORMAT = 0x828D;
static const GLenum GL_READ_PIXELS_TYPE = 0x828E;
static const GLenum GL_TEXTURE_IMAGE_FORMAT = 0x828F;
static const GLenum GL_TEXTURE_IMAGE_TYPE = 0x8290;
static const GLenum GL_GET_TEXTURE_IMAGE_FORMAT = 0x8291;
static const GLenum GL_GET_TEXTURE_IMAGE_TYPE = 0x8292;
static const GLenum GL_MIPMAP = 0x8293;
static const GLenum GL_MANUAL_GENERATE_MIPMAP = 0x8294;
static const GLenum GL_AUTO_GENERATE_MIPMAP = 0x8295;
static const GLenum GL_COLOR_ENCODING = 0x8296;
static const GLenum GL_SRGB_READ = 0x8297;
static const GLenum GL_SRGB_WRITE = 0x8298;
static const GLenum GL_SRGB_DECODE_ARB = 0x8299;
static const GLenum GL_FILTER = 0x829A;
static const GLenum GL_VERTEX_TEXTURE = 0x829B;
static const GLenum GL_TESS_CONTROL_TEXTURE = 0x829C;
static const GLenum GL_TESS_EVALUATION_TEXTURE = 0x829D;
static const GLenum GL_GEOMETRY_TEXTURE = 0x829E;
static const GLenum GL_FRAGMENT_TEXTURE = 0x829F;
static const GLenum GL_COMPUTE_TEXTURE = 0x82A0;
static const GLenum GL_TEXTURE_SHADOW = 0x82A1;
static const GLenum GL_TEXTURE_GATHER = 0x82A2;
static const GLenum GL_TEXTURE_GATHER_SHADOW = 0x82A3;
static const GLenum GL_SHADER_IMAGE_LOAD = 0x82A4;
static const GLenum GL_SHADER_IMAGE_STORE = 0x82A5;
static const GLenum GL_SHADER_IMAGE_ATOMIC = 0x82A6;
static const GLenum GL_IMAGE_TEXEL_SIZE = 0x82A7;
static const GLenum GL_IMAGE_COMPATIBILITY_CLASS = 0x82A8;
static const GLenum GL_IMAGE_PIXEL_FORMAT = 0x82A9;
static const GLenum GL_IMAGE_PIXEL_TYPE = 0x82AA;
static const GLenum GL_SIMULTANEOUS_TEXTURE_AND_DEPTH_TEST = 0x82AC;
static const GLenum GL_SIMULTANEOUS_TEXTURE_AND_STENCIL_TEST = 0x82AD;
static const GLenum GL_SIMULTANEOUS_TEXTURE_AND_DEPTH_WRITE = 0x82AE;
static const GLenum GL_SIMULTANEOUS_TEXTURE_AND_STENCIL_WRITE = 0x82AF;
static const GLenum GL_TEXTURE_COMPRESSED_BLOCK_WIDTH = 0x82B1;
static const GLenum GL_TEXTURE_COMPRESSED_BLOCK_HEIGHT = 0x82B2;
static const GLenum GL_TEXTURE_COMPRESSED_BLOCK_SIZE = 0x82B3;
static const GLenum GL_CLEAR_BUFFER = 0x82B4;
static const GLenum GL_TEXTURE_VIEW = 0x82B5;
static const GLenum GL_VIEW_COMPATIBILITY_CLASS = 0x82B6;
static const GLenum GL_FULL_SUPPORT = 0x82B7;
static const GLenum GL_CAVEAT_SUPPORT = 0x82B8;
static const GLenum GL_IMAGE_CLASS_4_X_32 = 0x82B9;
static const GLenum GL_IMAGE_CLASS_2_X_32 = 0x82BA;
static const GLenum GL_IMAGE_CLASS_1_X_32 = 0x82BB;
static const GLenum GL_IMAGE_CLASS_4_X_16 = 0x82BC;
static const GLenum GL_IMAGE_CLASS_2_X_16 = 0x82BD;
static const GLenum GL_IMAGE_CLASS_1_X_16 = 0x82BE;
static const GLenum GL_IMAGE_CLASS_4_X_8 = 0x82BF;
static const GLenum GL_IMAGE_CLASS_2_X_8 = 0x82C0;
static const GLenum GL_IMAGE_CLASS_1_X_8 = 0x82C1;
static const GLenum GL_IMAGE_CLASS_11_11_10 = 0x82C2;
static const GLenum GL_IMAGE_CLASS_10_10_10_2 = 0x82C3;
static const GLenum GL_VIEW_CLASS_128_BITS = 0x82C4;
static const GLenum GL_VIEW_CLASS_96_BITS = 0x82C5;
static const GLenum GL_VIEW_CLASS_64_BITS = 0x82C6;
static const GLenum GL_VIEW_CLASS_48_BITS = 0x82C7;
static const GLenum GL_VIEW_CLASS_32_BITS = 0x82C8;
static const GLenum GL_VIEW_CLASS_24_BITS = 0x82C9;
static const GLenum GL_VIEW_CLASS_16_BITS = 0x82CA;
static const GLenum GL_VIEW_CLASS_8_BITS = 0x82CB;
static const GLenum GL_VIEW_CLASS_S3TC_DXT1_RGB = 0x82CC;
static const GLenum GL_VIEW_CLASS_S3TC_DXT1_RGBA = 0x82CD;
static const GLenum GL_VIEW_CLASS_S3TC_DXT3_RGBA = 0x82CE;
static const GLenum GL_VIEW_CLASS_S3TC_DXT5_RGBA = 0x82CF;
static const GLenum GL_VIEW_CLASS_RGTC1_RED = 0x82D0;
static const GLenum GL_VIEW_CLASS_RGTC2_RG = 0x82D1;
static const GLenum GL_VIEW_CLASS_BPTC_UNORM = 0x82D2;
static const GLenum GL_VIEW_CLASS_BPTC_FLOAT = 0x82D3;

static const GLenum GL_UNIFORM = 0x92E1;
static const GLenum GL_UNIFORM_BLOCK = 0x92E2;
static const GLenum GL_PROGRAM_INPUT = 0x92E3;
static const GLenum GL_PROGRAM_OUTPUT = 0x92E4;
static const GLenum GL_BUFFER_VARIABLE = 0x92E5;
static const GLenum GL_SHADER_STORAGE_BLOCK = 0x92E6;
static const GLenum GL_VERTEX_SUBROUTINE = 0x92E8;
static const GLenum GL_TESS_CONTROL_SUBROUTINE = 0x92E9;
static const GLenum GL_TESS_EVALUATION_SUBROUTINE = 0x92EA;
static const GLenum GL_GEOMETRY_SUBROUTINE = 0x92EB;
static const GLenum GL_FRAGMENT_SUBROUTINE = 0x92EC;
static const GLenum GL_COMPUTE_SUBROUTINE = 0x92ED;
static const GLenum GL_VERTEX_SUBROUTINE_UNIFORM = 0x92EE;
static const GLenum GL_TESS_CONTROL_SUBROUTINE_UNIFORM = 0x92EF;
static const GLenum GL_TESS_EVALUATION_SUBROUTINE_UNIFORM = 0x92F0;
static const GLenum GL_GEOMETRY_SUBROUTINE_UNIFORM = 0x92F1;
static const GLenum GL_FRAGMENT_SUBROUTINE_UNIFORM = 0x92F2;
static const GLenum GL_COMPUTE_SUBROUTINE_UNIFORM = 0x92F3;
static const GLenum GL_TRANSFORM_FEEDBACK_VARYING = 0x92F4;
static const GLenum GL_ACTIVE_RESOURCES = 0x92F5;
static const GLenum GL_MAX_NAME_LENGTH = 0x92F6;
static const GLenum GL_MAX_NUM_ACTIVE_VARIABLES = 0x92F7;
static const GLenum GL_MAX_NUM_COMPATIBLE_SUBROUTINES = 0x92F8;
static const GLenum GL_NAME_LENGTH = 0x92F9;
static const GLenum GL_TYPE = 0x92FA;
static const GLenum GL_ARRAY_SIZE = 0x92FB;
static const GLenum GL_OFFSET = 0x92FC;
static const GLenum GL_BLOCK_INDEX = 0x92FD;
static const GLenum GL_ARRAY_STRIDE = 0x92FE;
static const GLenum GL_MATRIX_STRIDE = 0x92FF;
static const GLenum GL_IS_ROW_MAJOR = 0x9300;
static const GLenum GL_ATOMIC_COUNTER_BUFFER_INDEX = 0x9301;
static const GLenum GL_BUFFER_BINDING = 0x9302;
static const GLenum GL_BUFFER_DATA_SIZE = 0x9303;
static const GLenum GL_NUM_ACTIVE_VARIABLES = 0x9304;
static const GLenum GL_ACTIVE_VARIABLES = 0x9305;
static const GLenum GL_REFERENCED_BY_VERTEX_SHADER = 0x9306;
static const GLenum GL_REFERENCED_BY_TESS_CONTROL_SHADER = 0x9307;
static const GLenum GL_REFERENCED_BY_TESS_EVALUATION_SHADER = 0x9308;
static const GLenum GL_REFERENCED_BY_GEOMETRY_SHADER = 0x9309;
static const GLenum GL_REFERENCED_BY_FRAGMENT_SHADER = 0x930A;
static const GLenum GL_REFERENCED_BY_COMPUTE_SHADER = 0x930B;
static const GLenum GL_TOP_LEVEL_ARRAY_SIZE = 0x930C;
static const GLenum GL_TOP_LEVEL_ARRAY_STRIDE = 0x930D;
static const GLenum GL_LOCATION = 0x930E;
static const GLenum GL_LOCATION_INDEX = 0x930F;
static const GLenum GL_IS_PER_PATCH = 0x92E7;

static const GLenum GL_SHADER_STORAGE_BUFFER = 0x90D2;
static const GLenum GL_SHADER_STORAGE_BUFFER_BINDING = 0x90D3;
static const GLenum GL_SHADER_STORAGE_BUFFER_START = 0x90D4;
static const GLenum GL_SHADER_STORAGE_BUFFER_SIZE = 0x90D5;
static const GLenum GL_MAX_VERTEX_SHADER_STORAGE_BLOCKS = 0x90D6;
static const GLenum GL_MAX_GEOMETRY_SHADER_STORAGE_BLOCKS = 0x90D7;
static const GLenum GL_MAX_TESS_CONTROL_SHADER_STORAGE_BLOCKS = 0x90D8;
static const GLenum GL_MAX_TESS_EVALUATION_SHADER_STORAGE_BLOCKS = 0x90D9;
static const GLenum GL_MAX_FRAGMENT_SHADER_STORAGE_BLOCKS = 0x90DA;
static const GLenum GL_MAX_COMPUTE_SHADER_STORAGE_BLOCKS = 0x90DB;
static const GLenum GL_MAX_COMBINED_SHADER_STORAGE_BLOCKS = 0x90DC;
static const GLenum GL_MAX_SHADER_STORAGE_BUFFER_BINDINGS = 0x90DD;
static const GLenum GL_MAX_SHADER_STORAGE_BLOCK_SIZE = 0x90DE;
static const GLenum GL_SHADER_STORAGE_BUFFER_OFFSET_ALIGNMENT = 0x90DF;
static const GLenum GL_SHADER_STORAGE_BARRIER_BIT = 0x2000;
static const GLenum GL_MAX_COMBINED_SHADER_OUTPUT_RESOURCES = GL_MAX_COMBINED_IMAGE_UNITS_AND_FRAGMENT_OUTPUTS;

static const GLenum GL_DEPTH_STENCIL_TEXTURE_MODE = 0x90EA;

static const GLenum GL_TEXTURE_BUFFER_OFFSET = 0x919D;
static const GLenum GL_TEXTURE_BUFFER_SIZE = 0x919E;
static const GLenum GL_TEXTURE_BUFFER_OFFSET_ALIGNMENT = 0x919F;

static const GLenum GL_TEXTURE_VIEW_MIN_LEVEL = 0x82DB;
static const GLenum GL_TEXTURE_VIEW_NUM_LEVELS = 0x82DC;
static const GLenum GL_TEXTURE_VIEW_MIN_LAYER = 0x82DD;
static const GLenum GL_TEXTURE_VIEW_NUM_LAYERS = 0x82DE;
static const GLenum GL_TEXTURE_IMMUTABLE_LEVELS = 0x82DF;

static const GLenum GL_VERTEX_ATTRIB_BINDING = 0x82D4;
static const GLenum GL_VERTEX_ATTRIB_RELATIVE_OFFSET = 0x82D5;
static const GLenum GL_VERTEX_BINDING_DIVISOR = 0x82D6;
static const GLenum GL_VERTEX_BINDING_OFFSET = 0x82D7;
static const GLenum GL_VERTEX_BINDING_STRIDE = 0x82D8;
static const GLenum GL_MAX_VERTEX_ATTRIB_RELATIVE_OFFSET = 0x82D9;
static const GLenum GL_MAX_VERTEX_ATTRIB_BINDINGS = 0x82DA;

void glCullFace (GLenum mode);
void glFrontFace (GLenum mode);
void glHint (GLenum target, GLenum mode);
void glLineWidth (GLfloat width);
void glPointSize (GLfloat size);
void glPolygonMode (GLenum face, GLenum mode);
void glScissor (GLint x, GLint y, GLsizei width, GLsizei height);
void glTexParameterf (GLenum target, GLenum pname, GLfloat param);
void glTexParameterfv (GLenum target, GLenum pname, const GLfloat *params);
void glTexParameteri (GLenum target, GLenum pname, GLint param);
void glTexParameteriv (GLenum target, GLenum pname, const GLint *params);
void glTexImage1D (GLenum target, GLint level, GLint internalformat, GLsizei width, GLint border, GLenum format, GLenum type, const GLvoid *pixels);
void glTexImage2D (GLenum target, GLint level, GLint internalformat, GLsizei width, GLsizei height, GLint border, GLenum format, GLenum type, const GLvoid *pixels);
void glDrawBuffer (GLenum mode);
void glClear (GLbitfield mask);
void glClearColor (GLfloat red, GLfloat green, GLfloat blue, GLfloat alpha);
void glClearStencil (GLint s);
void glClearDepth (GLdouble depth);
void glStencilMask (GLuint mask);
void glColorMask (GLboolean red, GLboolean green, GLboolean blue, GLboolean alpha);
void glDepthMask (GLboolean flag);
void glDisable (GLenum cap);
void glEnable (GLenum cap);
void glFinish (void);
void glFlush (void);
void glBlendFunc (GLenum sfactor, GLenum dfactor);
void glLogicOp (GLenum opcode);
void glStencilFunc (GLenum func, GLint ref, GLuint mask);
void glStencilOp (GLenum fail, GLenum zfail, GLenum zpass);
void glDepthFunc (GLenum func);
void glPixelStoref (GLenum pname, GLfloat param);
void glPixelStorei (GLenum pname, GLint param);
void glReadBuffer (GLenum mode);
void glReadPixels (GLint x, GLint y, GLsizei width, GLsizei height, GLenum format, GLenum type, GLvoid *pixels);
void glGetBooleanv (GLenum pname, GLboolean *params);
void glGetDoublev (GLenum pname, GLdouble *params);
GLenum glGetError (void);
void glGetFloatv (GLenum pname, GLfloat *params);
void glGetIntegerv (GLenum pname, GLint *params);
const GLubyte * glGetString (GLenum name);
void glGetTexImage (GLenum target, GLint level, GLenum format, GLenum type, GLvoid *pixels);
void glGetTexParameterfv (GLenum target, GLenum pname, GLfloat *params);
void glGetTexParameteriv (GLenum target, GLenum pname, GLint *params);
void glGetTexLevelParameterfv (GLenum target, GLint level, GLenum pname, GLfloat *params);
void glGetTexLevelParameteriv (GLenum target, GLint level, GLenum pname, GLint *params);
GLboolean glIsEnabled (GLenum cap);
void glDepthRange (GLdouble near, GLdouble far);
void glViewport (GLint x, GLint y, GLsizei width, GLsizei height);

void glDrawArrays (GLenum mode, GLint first, GLsizei count);
void glDrawElements (GLenum mode, GLsizei count, GLenum type, const GLvoid *indices);
void glGetPointerv (GLenum pname, GLvoid* *params);
void glPolygonOffset (GLfloat factor, GLfloat units);
void glCopyTexImage1D (GLenum target, GLint level, GLenum internalformat, GLint x, GLint y, GLsizei width, GLint border);
void glCopyTexImage2D (GLenum target, GLint level, GLenum internalformat, GLint x, GLint y, GLsizei width, GLsizei height, GLint border);
void glCopyTexSubImage1D (GLenum target, GLint level, GLint xoffset, GLint x, GLint y, GLsizei width);
void glCopyTexSubImage2D (GLenum target, GLint level, GLint xoffset, GLint yoffset, GLint x, GLint y, GLsizei width, GLsizei height);
void glTexSubImage1D (GLenum target, GLint level, GLint xoffset, GLsizei width, GLenum format, GLenum type, const GLvoid *pixels);
void glTexSubImage2D (GLenum target, GLint level, GLint xoffset, GLint yoffset, GLsizei width, GLsizei height, GLenum format, GLenum type, const GLvoid *pixels);
void glBindTexture (GLenum target, GLuint texture);
void glDeleteTextures (GLsizei n, const GLuint *textures);
void glGenTextures (GLsizei n, GLuint *textures);
GLboolean glIsTexture (GLuint texture);

void glBlendColor (GLfloat red, GLfloat green, GLfloat blue, GLfloat alpha);
void glBlendEquation (GLenum mode);
void glDrawRangeElements (GLenum mode, GLuint start, GLuint end, GLsizei count, GLenum type, const GLvoid *indices);
void glTexImage3D (GLenum target, GLint level, GLint internalformat, GLsizei width, GLsizei height, GLsizei depth, GLint border, GLenum format, GLenum type, const GLvoid *pixels);
void glTexSubImage3D (GLenum target, GLint level, GLint xoffset, GLint yoffset, GLint zoffset, GLsizei width, GLsizei height, GLsizei depth, GLenum format, GLenum type, const GLvoid *pixels);
void glCopyTexSubImage3D (GLenum target, GLint level, GLint xoffset, GLint yoffset, GLint zoffset, GLint x, GLint y, GLsizei width, GLsizei height);

void glActiveTexture (GLenum texture);
void glSampleCoverage (GLfloat value, GLboolean invert);
void glCompressedTexImage3D (GLenum target, GLint level, GLenum internalformat, GLsizei width, GLsizei height, GLsizei depth, GLint border, GLsizei imageSize, const GLvoid *data);
void glCompressedTexImage2D (GLenum target, GLint level, GLenum internalformat, GLsizei width, GLsizei height, GLint border, GLsizei imageSize, const GLvoid *data);
void glCompressedTexImage1D (GLenum target, GLint level, GLenum internalformat, GLsizei width, GLint border, GLsizei imageSize, const GLvoid *data);
void glCompressedTexSubImage3D (GLenum target, GLint level, GLint xoffset, GLint yoffset, GLint zoffset, GLsizei width, GLsizei height, GLsizei depth, GLenum format, GLsizei imageSize, const GLvoid *data);
void glCompressedTexSubImage2D (GLenum target, GLint level, GLint xoffset, GLint yoffset, GLsizei width, GLsizei height, GLenum format, GLsizei imageSize, const GLvoid *data);
void glCompressedTexSubImage1D (GLenum target, GLint level, GLint xoffset, GLsizei width, GLenum format, GLsizei imageSize, const GLvoid *data);
void glGetCompressedTexImage (GLenum target, GLint level, GLvoid *img);

void glBlendFuncSeparate (GLenum sfactorRGB, GLenum dfactorRGB, GLenum sfactorAlpha, GLenum dfactorAlpha);
void glMultiDrawArrays (GLenum mode, const GLint *first, const GLsizei *count, GLsizei drawcount);
void glMultiDrawElements (GLenum mode, const GLsizei *count, GLenum type, const GLvoid* const *indices, GLsizei drawcount);
void glPointParameterf (GLenum pname, GLfloat param);
void glPointParameterfv (GLenum pname, const GLfloat *params);
void glPointParameteri (GLenum pname, GLint param);
void glPointParameteriv (GLenum pname, const GLint *params);

void glGenQueries (GLsizei n, GLuint *ids);
void glDeleteQueries (GLsizei n, const GLuint *ids);
GLboolean glIsQuery (GLuint id);
void glBeginQuery (GLenum target, GLuint id);
void glEndQuery (GLenum target);
void glGetQueryiv (GLenum target, GLenum pname, GLint *params);
void glGetQueryObjectiv (GLuint id, GLenum pname, GLint *params);
void glGetQueryObjectuiv (GLuint id, GLenum pname, GLuint *params);
void glBindBuffer (GLenum target, GLuint buffer);
void glDeleteBuffers (GLsizei n, const GLuint *buffers);
void glGenBuffers (GLsizei n, GLuint *buffers);
GLboolean glIsBuffer (GLuint buffer);
void glBufferData (GLenum target, GLsizeiptr size, const GLvoid *data, GLenum usage);
void glBufferSubData (GLenum target, GLintptr offset, GLsizeiptr size, const GLvoid *data);
void glGetBufferSubData (GLenum target, GLintptr offset, GLsizeiptr size, GLvoid *data);
GLvoid* glMapBuffer (GLenum target, GLenum access);
GLboolean glUnmapBuffer (GLenum target);
void glGetBufferParameteriv (GLenum target, GLenum pname, GLint *params);
void glGetBufferPointerv (GLenum target, GLenum pname, GLvoid* *params);

void glBlendEquationSeparate (GLenum modeRGB, GLenum modeAlpha);
void glDrawBuffers (GLsizei n, const GLenum *bufs);
void glStencilOpSeparate (GLenum face, GLenum sfail, GLenum dpfail, GLenum dppass);
void glStencilFuncSeparate (GLenum face, GLenum func, GLint ref, GLuint mask);
void glStencilMaskSeparate (GLenum face, GLuint mask);
void glAttachShader (GLuint program, GLuint shader);
void glBindAttribLocation (GLuint program, GLuint index, const GLchar *name);
void glCompileShader (GLuint shader);
GLuint glCreateProgram (void);
GLuint glCreateShader (GLenum type);
void glDeleteProgram (GLuint program);
void glDeleteShader (GLuint shader);
void glDetachShader (GLuint program, GLuint shader);
void glDisableVertexAttribArray (GLuint index);
void glEnableVertexAttribArray (GLuint index);
void glGetActiveAttrib (GLuint program, GLuint index, GLsizei bufSize, GLsizei *length, GLint *size, GLenum *type, GLchar *name);
void glGetActiveUniform (GLuint program, GLuint index, GLsizei bufSize, GLsizei *length, GLint *size, GLenum *type, GLchar *name);
void glGetAttachedShaders (GLuint program, GLsizei maxCount, GLsizei *count, GLuint *obj);
GLint glGetAttribLocation (GLuint program, const GLchar *name);
void glGetProgramiv (GLuint program, GLenum pname, GLint *params);
void glGetProgramInfoLog (GLuint program, GLsizei bufSize, GLsizei *length, GLchar *infoLog);
void glGetShaderiv (GLuint shader, GLenum pname, GLint *params);
void glGetShaderInfoLog (GLuint shader, GLsizei bufSize, GLsizei *length, GLchar *infoLog);
void glGetShaderSource (GLuint shader, GLsizei bufSize, GLsizei *length, GLchar *source);
GLint glGetUniformLocation (GLuint program, const GLchar *name);
void glGetUniformfv (GLuint program, GLint location, GLfloat *params);
void glGetUniformiv (GLuint program, GLint location, GLint *params);
void glGetVertexAttribdv (GLuint index, GLenum pname, GLdouble *params);
void glGetVertexAttribfv (GLuint index, GLenum pname, GLfloat *params);
void glGetVertexAttribiv (GLuint index, GLenum pname, GLint *params);
void glGetVertexAttribPointerv (GLuint index, GLenum pname, GLvoid* *pointer);
GLboolean glIsProgram (GLuint program);
GLboolean glIsShader (GLuint shader);
void glLinkProgram (GLuint program);
void glShaderSource (GLuint shader, GLsizei count, const GLchar* const *string, const GLint *length);
void glUseProgram (GLuint program);
void glUniform1f (GLint location, GLfloat v0);
void glUniform2f (GLint location, GLfloat v0, GLfloat v1);
void glUniform3f (GLint location, GLfloat v0, GLfloat v1, GLfloat v2);
void glUniform4f (GLint location, GLfloat v0, GLfloat v1, GLfloat v2, GLfloat v3);
void glUniform1i (GLint location, GLint v0);
void glUniform2i (GLint location, GLint v0, GLint v1);
void glUniform3i (GLint location, GLint v0, GLint v1, GLint v2);
void glUniform4i (GLint location, GLint v0, GLint v1, GLint v2, GLint v3);
void glUniform1fv (GLint location, GLsizei count, const GLfloat *value);
void glUniform2fv (GLint location, GLsizei count, const GLfloat *value);
void glUniform3fv (GLint location, GLsizei count, const GLfloat *value);
void glUniform4fv (GLint location, GLsizei count, const GLfloat *value);
void glUniform1iv (GLint location, GLsizei count, const GLint *value);
void glUniform2iv (GLint location, GLsizei count, const GLint *value);
void glUniform3iv (GLint location, GLsizei count, const GLint *value);
void glUniform4iv (GLint location, GLsizei count, const GLint *value);
void glUniformMatrix2fv (GLint location, GLsizei count, GLboolean transpose, const GLfloat *value);
void glUniformMatrix3fv (GLint location, GLsizei count, GLboolean transpose, const GLfloat *value);
void glUniformMatrix4fv (GLint location, GLsizei count, GLboolean transpose, const GLfloat *value);
void glValidateProgram (GLuint program);
void glVertexAttrib1d (GLuint index, GLdouble x);
void glVertexAttrib1dv (GLuint index, const GLdouble *v);
void glVertexAttrib1f (GLuint index, GLfloat x);
void glVertexAttrib1fv (GLuint index, const GLfloat *v);
void glVertexAttrib1s (GLuint index, GLshort x);
void glVertexAttrib1sv (GLuint index, const GLshort *v);
void glVertexAttrib2d (GLuint index, GLdouble x, GLdouble y);
void glVertexAttrib2dv (GLuint index, const GLdouble *v);
void glVertexAttrib2f (GLuint index, GLfloat x, GLfloat y);
void glVertexAttrib2fv (GLuint index, const GLfloat *v);
void glVertexAttrib2s (GLuint index, GLshort x, GLshort y);
void glVertexAttrib2sv (GLuint index, const GLshort *v);
void glVertexAttrib3d (GLuint index, GLdouble x, GLdouble y, GLdouble z);
void glVertexAttrib3dv (GLuint index, const GLdouble *v);
void glVertexAttrib3f (GLuint index, GLfloat x, GLfloat y, GLfloat z);
void glVertexAttrib3fv (GLuint index, const GLfloat *v);
void glVertexAttrib3s (GLuint index, GLshort x, GLshort y, GLshort z);
void glVertexAttrib3sv (GLuint index, const GLshort *v);
void glVertexAttrib4Nbv (GLuint index, const GLbyte *v);
void glVertexAttrib4Niv (GLuint index, const GLint *v);
void glVertexAttrib4Nsv (GLuint index, const GLshort *v);
void glVertexAttrib4Nub (GLuint index, GLubyte x, GLubyte y, GLubyte z, GLubyte w);
void glVertexAttrib4Nubv (GLuint index, const GLubyte *v);
void glVertexAttrib4Nuiv (GLuint index, const GLuint *v);
void glVertexAttrib4Nusv (GLuint index, const GLushort *v);
void glVertexAttrib4bv (GLuint index, const GLbyte *v);
void glVertexAttrib4d (GLuint index, GLdouble x, GLdouble y, GLdouble z, GLdouble w);
void glVertexAttrib4dv (GLuint index, const GLdouble *v);
void glVertexAttrib4f (GLuint index, GLfloat x, GLfloat y, GLfloat z, GLfloat w);
void glVertexAttrib4fv (GLuint index, const GLfloat *v);
void glVertexAttrib4iv (GLuint index, const GLint *v);
void glVertexAttrib4s (GLuint index, GLshort x, GLshort y, GLshort z, GLshort w);
void glVertexAttrib4sv (GLuint index, const GLshort *v);
void glVertexAttrib4ubv (GLuint index, const GLubyte *v);
void glVertexAttrib4uiv (GLuint index, const GLuint *v);
void glVertexAttrib4usv (GLuint index, const GLushort *v);
void glVertexAttribPointer (GLuint index, GLint size, GLenum type, GLboolean normalized, GLsizei stride, const GLvoid *pointer);

void glUniformMatrix2x3fv (GLint location, GLsizei count, GLboolean transpose, const GLfloat *value);
void glUniformMatrix3x2fv (GLint location, GLsizei count, GLboolean transpose, const GLfloat *value);
void glUniformMatrix2x4fv (GLint location, GLsizei count, GLboolean transpose, const GLfloat *value);
void glUniformMatrix4x2fv (GLint location, GLsizei count, GLboolean transpose, const GLfloat *value);
void glUniformMatrix3x4fv (GLint location, GLsizei count, GLboolean transpose, const GLfloat *value);
void glUniformMatrix4x3fv (GLint location, GLsizei count, GLboolean transpose, const GLfloat *value);

void glColorMaski (GLuint index, GLboolean r, GLboolean g, GLboolean b, GLboolean a);
void glGetBooleani_v (GLenum target, GLuint index, GLboolean *data);
void glGetIntegeri_v (GLenum target, GLuint index, GLint *data);
void glEnablei (GLenum target, GLuint index);
void glDisablei (GLenum target, GLuint index);
GLboolean glIsEnabledi (GLenum target, GLuint index);
void glBeginTransformFeedback (GLenum primitiveMode);
void glEndTransformFeedback (void);
void glBindBufferRange (GLenum target, GLuint index, GLuint buffer, GLintptr offset, GLsizeiptr size);
void glBindBufferBase (GLenum target, GLuint index, GLuint buffer);
void glTransformFeedbackVaryings (GLuint program, GLsizei count, const GLchar* const *varyings, GLenum bufferMode);
void glGetTransformFeedbackVarying (GLuint program, GLuint index, GLsizei bufSize, GLsizei *length, GLsizei *size, GLenum *type, GLchar *name);
void glClampColor (GLenum target, GLenum clamp);
void glBeginConditionalRender (GLuint id, GLenum mode);
void glEndConditionalRender (void);
void glVertexAttribIPointer (GLuint index, GLint size, GLenum type, GLsizei stride, const GLvoid *pointer);
void glGetVertexAttribIiv (GLuint index, GLenum pname, GLint *params);
void glGetVertexAttribIuiv (GLuint index, GLenum pname, GLuint *params);
void glVertexAttribI1i (GLuint index, GLint x);
void glVertexAttribI2i (GLuint index, GLint x, GLint y);
void glVertexAttribI3i (GLuint index, GLint x, GLint y, GLint z);
void glVertexAttribI4i (GLuint index, GLint x, GLint y, GLint z, GLint w);
void glVertexAttribI1ui (GLuint index, GLuint x);
void glVertexAttribI2ui (GLuint index, GLuint x, GLuint y);
void glVertexAttribI3ui (GLuint index, GLuint x, GLuint y, GLuint z);
void glVertexAttribI4ui (GLuint index, GLuint x, GLuint y, GLuint z, GLuint w);
void glVertexAttribI1iv (GLuint index, const GLint *v);
void glVertexAttribI2iv (GLuint index, const GLint *v);
void glVertexAttribI3iv (GLuint index, const GLint *v);
void glVertexAttribI4iv (GLuint index, const GLint *v);
void glVertexAttribI1uiv (GLuint index, const GLuint *v);
void glVertexAttribI2uiv (GLuint index, const GLuint *v);
void glVertexAttribI3uiv (GLuint index, const GLuint *v);
void glVertexAttribI4uiv (GLuint index, const GLuint *v);
void glVertexAttribI4bv (GLuint index, const GLbyte *v);
void glVertexAttribI4sv (GLuint index, const GLshort *v);
void glVertexAttribI4ubv (GLuint index, const GLubyte *v);
void glVertexAttribI4usv (GLuint index, const GLushort *v);
void glGetUniformuiv (GLuint program, GLint location, GLuint *params);
void glBindFragDataLocation (GLuint program, GLuint color, const GLchar *name);
GLint glGetFragDataLocation (GLuint program, const GLchar *name);
void glUniform1ui (GLint location, GLuint v0);
void glUniform2ui (GLint location, GLuint v0, GLuint v1);
void glUniform3ui (GLint location, GLuint v0, GLuint v1, GLuint v2);
void glUniform4ui (GLint location, GLuint v0, GLuint v1, GLuint v2, GLuint v3);
void glUniform1uiv (GLint location, GLsizei count, const GLuint *value);
void glUniform2uiv (GLint location, GLsizei count, const GLuint *value);
void glUniform3uiv (GLint location, GLsizei count, const GLuint *value);
void glUniform4uiv (GLint location, GLsizei count, const GLuint *value);
void glTexParameterIiv (GLenum target, GLenum pname, const GLint *params);
void glTexParameterIuiv (GLenum target, GLenum pname, const GLuint *params);
void glGetTexParameterIiv (GLenum target, GLenum pname, GLint *params);
void glGetTexParameterIuiv (GLenum target, GLenum pname, GLuint *params);
void glClearBufferiv (GLenum buffer, GLint drawbuffer, const GLint *value);
void glClearBufferuiv (GLenum buffer, GLint drawbuffer, const GLuint *value);
void glClearBufferfv (GLenum buffer, GLint drawbuffer, const GLfloat *value);
void glClearBufferfi (GLenum buffer, GLint drawbuffer, GLfloat depth, GLint stencil);
const GLubyte * glGetStringi (GLenum name, GLuint index);

void glDrawArraysInstanced (GLenum mode, GLint first, GLsizei count, GLsizei instancecount);
void glDrawElementsInstanced (GLenum mode, GLsizei count, GLenum type, const GLvoid *indices, GLsizei instancecount);
void glTexBuffer (GLenum target, GLenum internalformat, GLuint buffer);
void glPrimitiveRestartIndex (GLuint index);

void glGetInteger64i_v (GLenum target, GLuint index, GLint64 *data);
void glGetBufferParameteri64v (GLenum target, GLenum pname, GLint64 *params);
void glFramebufferTexture (GLenum target, GLenum attachment, GLuint texture, GLint level);

void glVertexAttribDivisor (GLuint index, GLuint divisor);

void glMinSampleShading (GLfloat value);
void glBlendEquationi (GLuint buf, GLenum mode);
void glBlendEquationSeparatei (GLuint buf, GLenum modeRGB, GLenum modeAlpha);
void glBlendFunci (GLuint buf, GLenum src, GLenum dst);
void glBlendFuncSeparatei (GLuint buf, GLenum srcRGB, GLenum dstRGB, GLenum srcAlpha, GLenum dstAlpha);

GLboolean glIsRenderbuffer (GLuint renderbuffer);
void glBindRenderbuffer (GLenum target, GLuint renderbuffer);
void glDeleteRenderbuffers (GLsizei n, const GLuint *renderbuffers);
void glGenRenderbuffers (GLsizei n, GLuint *renderbuffers);
void glRenderbufferStorage (GLenum target, GLenum internalformat, GLsizei width, GLsizei height);
void glGetRenderbufferParameteriv (GLenum target, GLenum pname, GLint *params);
GLboolean glIsFramebuffer (GLuint framebuffer);
void glBindFramebuffer (GLenum target, GLuint framebuffer);
void glDeleteFramebuffers (GLsizei n, const GLuint *framebuffers);
void glGenFramebuffers (GLsizei n, GLuint *framebuffers);
GLenum glCheckFramebufferStatus (GLenum target);
void glFramebufferTexture1D (GLenum target, GLenum attachment, GLenum textarget, GLuint texture, GLint level);
void glFramebufferTexture2D (GLenum target, GLenum attachment, GLenum textarget, GLuint texture, GLint level);
void glFramebufferTexture3D (GLenum target, GLenum attachment, GLenum textarget, GLuint texture, GLint level, GLint zoffset);
void glFramebufferRenderbuffer (GLenum target, GLenum attachment, GLenum renderbuffertarget, GLuint renderbuffer);
void glGetFramebufferAttachmentParameteriv (GLenum target, GLenum attachment, GLenum pname, GLint *params);
void glGenerateMipmap (GLenum target);
void glBlitFramebuffer (GLint srcX0, GLint srcY0, GLint srcX1, GLint srcY1, GLint dstX0, GLint dstY0, GLint dstX1, GLint dstY1, GLbitfield mask, GLenum filter);
void glRenderbufferStorageMultisample (GLenum target, GLsizei samples, GLenum internalformat, GLsizei width, GLsizei height);
void glFramebufferTextureLayer (GLenum target, GLenum attachment, GLuint texture, GLint level, GLint layer);

GLvoid* glMapBufferRange (GLenum target, GLintptr offset, GLsizeiptr length, GLbitfield access);
void glFlushMappedBufferRange (GLenum target, GLintptr offset, GLsizeiptr length);

void glBindVertexArray (GLuint array);
void glDeleteVertexArrays (GLsizei n, const GLuint *arrays);
void glGenVertexArrays (GLsizei n, GLuint *arrays);
GLboolean glIsVertexArray (GLuint array);

void glGetUniformIndices (GLuint program, GLsizei uniformCount, const GLchar* const *uniformNames, GLuint *uniformIndices);
void glGetActiveUniformsiv (GLuint program, GLsizei uniformCount, const GLuint *uniformIndices, GLenum pname, GLint *params);
void glGetActiveUniformName (GLuint program, GLuint uniformIndex, GLsizei bufSize, GLsizei *length, GLchar *uniformName);
GLuint glGetUniformBlockIndex (GLuint program, const GLchar *uniformBlockName);
void glGetActiveUniformBlockiv (GLuint program, GLuint uniformBlockIndex, GLenum pname, GLint *params);
void glGetActiveUniformBlockName (GLuint program, GLuint uniformBlockIndex, GLsizei bufSize, GLsizei *length, GLchar *uniformBlockName);
void glUniformBlockBinding (GLuint program, GLuint uniformBlockIndex, GLuint uniformBlockBinding);

void glCopyBufferSubData (GLenum readTarget, GLenum writeTarget, GLintptr readOffset, GLintptr writeOffset, GLsizeiptr size);

void glDrawElementsBaseVertex (GLenum mode, GLsizei count, GLenum type, const GLvoid *indices, GLint basevertex);
void glDrawRangeElementsBaseVertex (GLenum mode, GLuint start, GLuint end, GLsizei count, GLenum type, const GLvoid *indices, GLint basevertex);
void glDrawElementsInstancedBaseVertex (GLenum mode, GLsizei count, GLenum type, const GLvoid *indices, GLsizei instancecount, GLint basevertex);
void glMultiDrawElementsBaseVertex (GLenum mode, const GLsizei *count, GLenum type, const GLvoid* const *indices, GLsizei drawcount, const GLint *basevertex);

void glProvokingVertex (GLenum mode);

GLsync glFenceSync (GLenum condition, GLbitfield flags);
GLboolean glIsSync (GLsync sync);
void glDeleteSync (GLsync sync);
GLenum glClientWaitSync (GLsync sync, GLbitfield flags, GLuint64 timeout);
void glWaitSync (GLsync sync, GLbitfield flags, GLuint64 timeout);
void glGetInteger64v (GLenum pname, GLint64 *params);
void glGetSynciv (GLsync sync, GLenum pname, GLsizei bufSize, GLsizei *length, GLint *values);

void glTexImage2DMultisample (GLenum target, GLsizei samples, GLint internalformat, GLsizei width, GLsizei height, GLboolean fixedsamplelocations);
void glTexImage3DMultisample (GLenum target, GLsizei samples, GLint internalformat, GLsizei width, GLsizei height, GLsizei depth, GLboolean fixedsamplelocations);
void glGetMultisamplefv (GLenum pname, GLuint index, GLfloat *val);
void glSampleMaski (GLuint index, GLbitfield mask);

void glBlendEquationiARB (GLuint buf, GLenum mode);
void glBlendEquationSeparateiARB (GLuint buf, GLenum modeRGB, GLenum modeAlpha);
void glBlendFunciARB (GLuint buf, GLenum src, GLenum dst);
void glBlendFuncSeparateiARB (GLuint buf, GLenum srcRGB, GLenum dstRGB, GLenum srcAlpha, GLenum dstAlpha);

void glMinSampleShadingARB (GLfloat value);

void glNamedStringARB (GLenum type, GLint namelen, const GLchar *name, GLint stringlen, const GLchar *string);
void glDeleteNamedStringARB (GLint namelen, const GLchar *name);
void glCompileShaderIncludeARB (GLuint shader, GLsizei count, const GLchar* *path, const GLint *length);
GLboolean glIsNamedStringARB (GLint namelen, const GLchar *name);
void glGetNamedStringARB (GLint namelen, const GLchar *name, GLsizei bufSize, GLint *stringlen, GLchar *string);
void glGetNamedStringivARB (GLint namelen, const GLchar *name, GLenum pname, GLint *params);

void glBindFragDataLocationIndexed (GLuint program, GLuint colorNumber, GLuint index, const GLchar *name);
GLint glGetFragDataIndex (GLuint program, const GLchar *name);

void glGenSamplers (GLsizei count, GLuint *samplers);
void glDeleteSamplers (GLsizei count, const GLuint *samplers);
GLboolean glIsSampler (GLuint sampler);
void glBindSampler (GLuint unit, GLuint sampler);
void glSamplerParameteri (GLuint sampler, GLenum pname, GLint param);
void glSamplerParameteriv (GLuint sampler, GLenum pname, const GLint *param);
void glSamplerParameterf (GLuint sampler, GLenum pname, GLfloat param);
void glSamplerParameterfv (GLuint sampler, GLenum pname, const GLfloat *param);
void glSamplerParameterIiv (GLuint sampler, GLenum pname, const GLint *param);
void glSamplerParameterIuiv (GLuint sampler, GLenum pname, const GLuint *param);
void glGetSamplerParameteriv (GLuint sampler, GLenum pname, GLint *params);
void glGetSamplerParameterIiv (GLuint sampler, GLenum pname, GLint *params);
void glGetSamplerParameterfv (GLuint sampler, GLenum pname, GLfloat *params);
void glGetSamplerParameterIuiv (GLuint sampler, GLenum pname, GLuint *params);

void glQueryCounter (GLuint id, GLenum target);
void glGetQueryObjecti64v (GLuint id, GLenum pname, GLint64 *params);
void glGetQueryObjectui64v (GLuint id, GLenum pname, GLuint64 *params);

void glVertexP2ui (GLenum type, GLuint value);
void glVertexP2uiv (GLenum type, const GLuint *value);
void glVertexP3ui (GLenum type, GLuint value);
void glVertexP3uiv (GLenum type, const GLuint *value);
void glVertexP4ui (GLenum type, GLuint value);
void glVertexP4uiv (GLenum type, const GLuint *value);
void glTexCoordP1ui (GLenum type, GLuint coords);
void glTexCoordP1uiv (GLenum type, const GLuint *coords);
void glTexCoordP2ui (GLenum type, GLuint coords);
void glTexCoordP2uiv (GLenum type, const GLuint *coords);
void glTexCoordP3ui (GLenum type, GLuint coords);
void glTexCoordP3uiv (GLenum type, const GLuint *coords);
void glTexCoordP4ui (GLenum type, GLuint coords);
void glTexCoordP4uiv (GLenum type, const GLuint *coords);
void glMultiTexCoordP1ui (GLenum texture, GLenum type, GLuint coords);
void glMultiTexCoordP1uiv (GLenum texture, GLenum type, const GLuint *coords);
void glMultiTexCoordP2ui (GLenum texture, GLenum type, GLuint coords);
void glMultiTexCoordP2uiv (GLenum texture, GLenum type, const GLuint *coords);
void glMultiTexCoordP3ui (GLenum texture, GLenum type, GLuint coords);
void glMultiTexCoordP3uiv (GLenum texture, GLenum type, const GLuint *coords);
void glMultiTexCoordP4ui (GLenum texture, GLenum type, GLuint coords);
void glMultiTexCoordP4uiv (GLenum texture, GLenum type, const GLuint *coords);
void glNormalP3ui (GLenum type, GLuint coords);
void glNormalP3uiv (GLenum type, const GLuint *coords);
void glColorP3ui (GLenum type, GLuint color);
void glColorP3uiv (GLenum type, const GLuint *color);
void glColorP4ui (GLenum type, GLuint color);
void glColorP4uiv (GLenum type, const GLuint *color);
void glSecondaryColorP3ui (GLenum type, GLuint color);
void glSecondaryColorP3uiv (GLenum type, const GLuint *color);
void glVertexAttribP1ui (GLuint index, GLenum type, GLboolean normalized, GLuint value);
void glVertexAttribP1uiv (GLuint index, GLenum type, GLboolean normalized, const GLuint *value);
void glVertexAttribP2ui (GLuint index, GLenum type, GLboolean normalized, GLuint value);
void glVertexAttribP2uiv (GLuint index, GLenum type, GLboolean normalized, const GLuint *value);
void glVertexAttribP3ui (GLuint index, GLenum type, GLboolean normalized, GLuint value);
void glVertexAttribP3uiv (GLuint index, GLenum type, GLboolean normalized, const GLuint *value);
void glVertexAttribP4ui (GLuint index, GLenum type, GLboolean normalized, GLuint value);
void glVertexAttribP4uiv (GLuint index, GLenum type, GLboolean normalized, const GLuint *value);

void glDrawArraysIndirect (GLenum mode, const GLvoid *indirect);
void glDrawElementsIndirect (GLenum mode, GLenum type, const GLvoid *indirect);

void glUniform1d (GLint location, GLdouble x);
void glUniform2d (GLint location, GLdouble x, GLdouble y);
void glUniform3d (GLint location, GLdouble x, GLdouble y, GLdouble z);
void glUniform4d (GLint location, GLdouble x, GLdouble y, GLdouble z, GLdouble w);
void glUniform1dv (GLint location, GLsizei count, const GLdouble *value);
void glUniform2dv (GLint location, GLsizei count, const GLdouble *value);
void glUniform3dv (GLint location, GLsizei count, const GLdouble *value);
void glUniform4dv (GLint location, GLsizei count, const GLdouble *value);
void glUniformMatrix2dv (GLint location, GLsizei count, GLboolean transpose, const GLdouble *value);
void glUniformMatrix3dv (GLint location, GLsizei count, GLboolean transpose, const GLdouble *value);
void glUniformMatrix4dv (GLint location, GLsizei count, GLboolean transpose, const GLdouble *value);
void glUniformMatrix2x3dv (GLint location, GLsizei count, GLboolean transpose, const GLdouble *value);
void glUniformMatrix2x4dv (GLint location, GLsizei count, GLboolean transpose, const GLdouble *value);
void glUniformMatrix3x2dv (GLint location, GLsizei count, GLboolean transpose, const GLdouble *value);
void glUniformMatrix3x4dv (GLint location, GLsizei count, GLboolean transpose, const GLdouble *value);
void glUniformMatrix4x2dv (GLint location, GLsizei count, GLboolean transpose, const GLdouble *value);
void glUniformMatrix4x3dv (GLint location, GLsizei count, GLboolean transpose, const GLdouble *value);
void glGetUniformdv (GLuint program, GLint location, GLdouble *params);

GLint glGetSubroutineUniformLocation (GLuint program, GLenum shadertype, const GLchar *name);
GLuint glGetSubroutineIndex (GLuint program, GLenum shadertype, const GLchar *name);
void glGetActiveSubroutineUniformiv (GLuint program, GLenum shadertype, GLuint index, GLenum pname, GLint *values);
void glGetActiveSubroutineUniformName (GLuint program, GLenum shadertype, GLuint index, GLsizei bufsize, GLsizei *length, GLchar *name);
void glGetActiveSubroutineName (GLuint program, GLenum shadertype, GLuint index, GLsizei bufsize, GLsizei *length, GLchar *name);
void glUniformSubroutinesuiv (GLenum shadertype, GLsizei count, const GLuint *indices);
void glGetUniformSubroutineuiv (GLenum shadertype, GLint location, GLuint *params);
void glGetProgramStageiv (GLuint program, GLenum shadertype, GLenum pname, GLint *values);

void glPatchParameteri (GLenum pname, GLint value);
void glPatchParameterfv (GLenum pname, const GLfloat *values);

void glBindTransformFeedback (GLenum target, GLuint id);
void glDeleteTransformFeedbacks (GLsizei n, const GLuint *ids);
void glGenTransformFeedbacks (GLsizei n, GLuint *ids);
GLboolean glIsTransformFeedback (GLuint id);
void glPauseTransformFeedback (void);
void glResumeTransformFeedback (void);
void glDrawTransformFeedback (GLenum mode, GLuint id);

void glDrawTransformFeedbackStream (GLenum mode, GLuint id, GLuint stream);
void glBeginQueryIndexed (GLenum target, GLuint index, GLuint id);
void glEndQueryIndexed (GLenum target, GLuint index);
void glGetQueryIndexediv (GLenum target, GLuint index, GLenum pname, GLint *params);

void glReleaseShaderCompiler (void);
void glShaderBinary (GLsizei count, const GLuint *shaders, GLenum binaryformat, const GLvoid *binary, GLsizei length);
void glGetShaderPrecisionFormat (GLenum shadertype, GLenum precisiontype, GLint *range, GLint *precision);
void glDepthRangef (GLfloat n, GLfloat f);
void glClearDepthf (GLfloat d);

void glGetProgramBinary (GLuint program, GLsizei bufSize, GLsizei *length, GLenum *binaryFormat, GLvoid *binary);
void glProgramBinary (GLuint program, GLenum binaryFormat, const GLvoid *binary, GLsizei length);
void glProgramParameteri (GLuint program, GLenum pname, GLint value);

void glUseProgramStages (GLuint pipeline, GLbitfield stages, GLuint program);
void glActiveShaderProgram (GLuint pipeline, GLuint program);
GLuint glCreateShaderProgramv (GLenum type, GLsizei count, const GLchar* const *strings);
void glBindProgramPipeline (GLuint pipeline);
void glDeleteProgramPipelines (GLsizei n, const GLuint *pipelines);
void glGenProgramPipelines (GLsizei n, GLuint *pipelines);
GLboolean glIsProgramPipeline (GLuint pipeline);
void glGetProgramPipelineiv (GLuint pipeline, GLenum pname, GLint *params);
void glProgramUniform1i (GLuint program, GLint location, GLint v0);
void glProgramUniform1iv (GLuint program, GLint location, GLsizei count, const GLint *value);
void glProgramUniform1f (GLuint program, GLint location, GLfloat v0);
void glProgramUniform1fv (GLuint program, GLint location, GLsizei count, const GLfloat *value);
void glProgramUniform1d (GLuint program, GLint location, GLdouble v0);
void glProgramUniform1dv (GLuint program, GLint location, GLsizei count, const GLdouble *value);
void glProgramUniform1ui (GLuint program, GLint location, GLuint v0);
void glProgramUniform1uiv (GLuint program, GLint location, GLsizei count, const GLuint *value);
void glProgramUniform2i (GLuint program, GLint location, GLint v0, GLint v1);
void glProgramUniform2iv (GLuint program, GLint location, GLsizei count, const GLint *value);
void glProgramUniform2f (GLuint program, GLint location, GLfloat v0, GLfloat v1);
void glProgramUniform2fv (GLuint program, GLint location, GLsizei count, const GLfloat *value);
void glProgramUniform2d (GLuint program, GLint location, GLdouble v0, GLdouble v1);
void glProgramUniform2dv (GLuint program, GLint location, GLsizei count, const GLdouble *value);
void glProgramUniform2ui (GLuint program, GLint location, GLuint v0, GLuint v1);
void glProgramUniform2uiv (GLuint program, GLint location, GLsizei count, const GLuint *value);
void glProgramUniform3i (GLuint program, GLint location, GLint v0, GLint v1, GLint v2);
void glProgramUniform3iv (GLuint program, GLint location, GLsizei count, const GLint *value);
void glProgramUniform3f (GLuint program, GLint location, GLfloat v0, GLfloat v1, GLfloat v2);
void glProgramUniform3fv (GLuint program, GLint location, GLsizei count, const GLfloat *value);
void glProgramUniform3d (GLuint program, GLint location, GLdouble v0, GLdouble v1, GLdouble v2);
void glProgramUniform3dv (GLuint program, GLint location, GLsizei count, const GLdouble *value);
void glProgramUniform3ui (GLuint program, GLint location, GLuint v0, GLuint v1, GLuint v2);
void glProgramUniform3uiv (GLuint program, GLint location, GLsizei count, const GLuint *value);
void glProgramUniform4i (GLuint program, GLint location, GLint v0, GLint v1, GLint v2, GLint v3);
void glProgramUniform4iv (GLuint program, GLint location, GLsizei count, const GLint *value);
void glProgramUniform4f (GLuint program, GLint location, GLfloat v0, GLfloat v1, GLfloat v2, GLfloat v3);
void glProgramUniform4fv (GLuint program, GLint location, GLsizei count, const GLfloat *value);
void glProgramUniform4d (GLuint program, GLint location, GLdouble v0, GLdouble v1, GLdouble v2, GLdouble v3);
void glProgramUniform4dv (GLuint program, GLint location, GLsizei count, const GLdouble *value);
void glProgramUniform4ui (GLuint program, GLint location, GLuint v0, GLuint v1, GLuint v2, GLuint v3);
void glProgramUniform4uiv (GLuint program, GLint location, GLsizei count, const GLuint *value);
void glProgramUniformMatrix2fv (GLuint program, GLint location, GLsizei count, GLboolean transpose, const GLfloat *value);
void glProgramUniformMatrix3fv (GLuint program, GLint location, GLsizei count, GLboolean transpose, const GLfloat *value);
void glProgramUniformMatrix4fv (GLuint program, GLint location, GLsizei count, GLboolean transpose, const GLfloat *value);
void glProgramUniformMatrix2dv (GLuint program, GLint location, GLsizei count, GLboolean transpose, const GLdouble *value);
void glProgramUniformMatrix3dv (GLuint program, GLint location, GLsizei count, GLboolean transpose, const GLdouble *value);
void glProgramUniformMatrix4dv (GLuint program, GLint location, GLsizei count, GLboolean transpose, const GLdouble *value);
void glProgramUniformMatrix2x3fv (GLuint program, GLint location, GLsizei count, GLboolean transpose, const GLfloat *value);
void glProgramUniformMatrix3x2fv (GLuint program, GLint location, GLsizei count, GLboolean transpose, const GLfloat *value);
void glProgramUniformMatrix2x4fv (GLuint program, GLint location, GLsizei count, GLboolean transpose, const GLfloat *value);
void glProgramUniformMatrix4x2fv (GLuint program, GLint location, GLsizei count, GLboolean transpose, const GLfloat *value);
void glProgramUniformMatrix3x4fv (GLuint program, GLint location, GLsizei count, GLboolean transpose, const GLfloat *value);
void glProgramUniformMatrix4x3fv (GLuint program, GLint location, GLsizei count, GLboolean transpose, const GLfloat *value);
void glProgramUniformMatrix2x3dv (GLuint program, GLint location, GLsizei count, GLboolean transpose, const GLdouble *value);
void glProgramUniformMatrix3x2dv (GLuint program, GLint location, GLsizei count, GLboolean transpose, const GLdouble *value);
void glProgramUniformMatrix2x4dv (GLuint program, GLint location, GLsizei count, GLboolean transpose, const GLdouble *value);
void glProgramUniformMatrix4x2dv (GLuint program, GLint location, GLsizei count, GLboolean transpose, const GLdouble *value);
void glProgramUniformMatrix3x4dv (GLuint program, GLint location, GLsizei count, GLboolean transpose, const GLdouble *value);
void glProgramUniformMatrix4x3dv (GLuint program, GLint location, GLsizei count, GLboolean transpose, const GLdouble *value);
void glValidateProgramPipeline (GLuint pipeline);
void glGetProgramPipelineInfoLog (GLuint pipeline, GLsizei bufSize, GLsizei *length, GLchar *infoLog);

void glVertexAttribL1d (GLuint index, GLdouble x);
void glVertexAttribL2d (GLuint index, GLdouble x, GLdouble y);
void glVertexAttribL3d (GLuint index, GLdouble x, GLdouble y, GLdouble z);
void glVertexAttribL4d (GLuint index, GLdouble x, GLdouble y, GLdouble z, GLdouble w);
void glVertexAttribL1dv (GLuint index, const GLdouble *v);
void glVertexAttribL2dv (GLuint index, const GLdouble *v);
void glVertexAttribL3dv (GLuint index, const GLdouble *v);
void glVertexAttribL4dv (GLuint index, const GLdouble *v);
void glVertexAttribLPointer (GLuint index, GLint size, GLenum type, GLsizei stride, const GLvoid *pointer);
void glGetVertexAttribLdv (GLuint index, GLenum pname, GLdouble *params);

void glViewportArrayv (GLuint first, GLsizei count, const GLfloat *v);
void glViewportIndexedf (GLuint index, GLfloat x, GLfloat y, GLfloat w, GLfloat h);
void glViewportIndexedfv (GLuint index, const GLfloat *v);
void glScissorArrayv (GLuint first, GLsizei count, const GLint *v);
void glScissorIndexed (GLuint index, GLint left, GLint bottom, GLsizei width, GLsizei height);
void glScissorIndexedv (GLuint index, const GLint *v);
void glDepthRangeArrayv (GLuint first, GLsizei count, const GLdouble *v);
void glDepthRangeIndexed (GLuint index, GLdouble n, GLdouble f);
void glGetFloati_v (GLenum target, GLuint index, GLfloat *data);
void glGetDoublei_v (GLenum target, GLuint index, GLdouble *data);

GLsync glCreateSyncFromCLeventARB (struct _cl_context * context, struct _cl_event * event, GLbitfield flags);

void glDebugMessageControlARB (GLenum source, GLenum type, GLenum severity, GLsizei count, const GLuint *ids, GLboolean enabled);
void glDebugMessageInsertARB (GLenum source, GLenum type, GLuint id, GLenum severity, GLsizei length, const GLchar *buf);
// TODO GLDEBUGPROCARB undefined
// void glDebugMessageCallbackARB (GLDEBUGPROCARB callback, const GLvoid *userParam);
GLuint glGetDebugMessageLogARB (GLuint count, GLsizei bufsize, GLenum *sources, GLenum *types, GLuint *ids, GLenum *severities, GLsizei *lengths, GLchar *messageLog);

GLenum glGetGraphicsResetStatusARB (void);
void glGetnMapdvARB (GLenum target, GLenum query, GLsizei bufSize, GLdouble *v);
void glGetnMapfvARB (GLenum target, GLenum query, GLsizei bufSize, GLfloat *v);
void glGetnMapivARB (GLenum target, GLenum query, GLsizei bufSize, GLint *v);
void glGetnPixelMapfvARB (GLenum map, GLsizei bufSize, GLfloat *values);
void glGetnPixelMapuivARB (GLenum map, GLsizei bufSize, GLuint *values);
void glGetnPixelMapusvARB (GLenum map, GLsizei bufSize, GLushort *values);
void glGetnPolygonStippleARB (GLsizei bufSize, GLubyte *pattern);
void glGetnColorTableARB (GLenum target, GLenum format, GLenum type, GLsizei bufSize, GLvoid *table);
void glGetnConvolutionFilterARB (GLenum target, GLenum format, GLenum type, GLsizei bufSize, GLvoid *image);
void glGetnSeparableFilterARB (GLenum target, GLenum format, GLenum type, GLsizei rowBufSize, GLvoid *row, GLsizei columnBufSize, GLvoid *column, GLvoid *span);
void glGetnHistogramARB (GLenum target, GLboolean reset, GLenum format, GLenum type, GLsizei bufSize, GLvoid *values);
void glGetnMinmaxARB (GLenum target, GLboolean reset, GLenum format, GLenum type, GLsizei bufSize, GLvoid *values);
void glGetnTexImageARB (GLenum target, GLint level, GLenum format, GLenum type, GLsizei bufSize, GLvoid *img);
void glReadnPixelsARB (GLint x, GLint y, GLsizei width, GLsizei height, GLenum format, GLenum type, GLsizei bufSize, GLvoid *data);
void glGetnCompressedTexImageARB (GLenum target, GLint lod, GLsizei bufSize, GLvoid *img);
void glGetnUniformfvARB (GLuint program, GLint location, GLsizei bufSize, GLfloat *params);
void glGetnUniformivARB (GLuint program, GLint location, GLsizei bufSize, GLint *params);
void glGetnUniformuivARB (GLuint program, GLint location, GLsizei bufSize, GLuint *params);
void glGetnUniformdvARB (GLuint program, GLint location, GLsizei bufSize, GLdouble *params);

void glDrawArraysInstancedBaseInstance (GLenum mode, GLint first, GLsizei count, GLsizei instancecount, GLuint baseinstance);
void glDrawElementsInstancedBaseInstance (GLenum mode, GLsizei count, GLenum type, const void *indices, GLsizei instancecount, GLuint baseinstance);
void glDrawElementsInstancedBaseVertexBaseInstance (GLenum mode, GLsizei count, GLenum type, const void *indices, GLsizei instancecount, GLint basevertex, GLuint baseinstance);

void glDrawTransformFeedbackInstanced (GLenum mode, GLuint id, GLsizei instancecount);
void glDrawTransformFeedbackStreamInstanced (GLenum mode, GLuint id, GLuint stream, GLsizei instancecount);

void glGetInternalformativ (GLenum target, GLenum internalformat, GLenum pname, GLsizei bufSize, GLint *params);

void glGetActiveAtomicCounterBufferiv (GLuint program, GLuint bufferIndex, GLenum pname, GLint *params);

void glBindImageTexture (GLuint unit, GLuint texture, GLint level, GLboolean layered, GLint layer, GLenum access, GLenum format);
void glMemoryBarrier (GLbitfield barriers);

void glTexStorage1D (GLenum target, GLsizei levels, GLenum internalformat, GLsizei width);
void glTexStorage2D (GLenum target, GLsizei levels, GLenum internalformat, GLsizei width, GLsizei height);
void glTexStorage3D (GLenum target, GLsizei levels, GLenum internalformat, GLsizei width, GLsizei height, GLsizei depth);
void glTextureStorage1DEXT (GLuint texture, GLenum target, GLsizei levels, GLenum internalformat, GLsizei width);
void glTextureStorage2DEXT (GLuint texture, GLenum target, GLsizei levels, GLenum internalformat, GLsizei width, GLsizei height);
void glTextureStorage3DEXT (GLuint texture, GLenum target, GLsizei levels, GLenum internalformat, GLsizei width, GLsizei height, GLsizei depth);

void glDebugMessageControl (GLenum source, GLenum type, GLenum severity, GLsizei count, const GLuint *ids, GLboolean enabled);
void glDebugMessageInsert (GLenum source, GLenum type, GLuint id, GLenum severity, GLsizei length, const GLchar *buf);
// TODO GLDEBUGPROC undefined
// void glDebugMessageCallback (GLDEBUGPROC callback, const void *userParam);
GLuint glGetDebugMessageLog (GLuint count, GLsizei bufsize, GLenum *sources, GLenum *types, GLuint *ids, GLenum *severities, GLsizei *lengths, GLchar *messageLog);
void glPushDebugGroup (GLenum source, GLuint id, GLsizei length, const GLchar *message);
void glPopDebugGroup (void);
void glObjectLabel (GLenum identifier, GLuint name, GLsizei length, const GLchar *label);
void glGetObjectLabel (GLenum identifier, GLuint name, GLsizei bufSize, GLsizei *length, GLchar *label);
void glObjectPtrLabel (const void *ptr, GLsizei length, const GLchar *label);
void glGetObjectPtrLabel (const void *ptr, GLsizei bufSize, GLsizei *length, GLchar *label);

void glClearBufferData (GLenum target, GLenum internalformat, GLenum format, GLenum type, const void *data);
void glClearBufferSubData (GLenum target, GLenum internalformat, GLintptr offset, GLsizeiptr size, GLenum format, GLenum type, const void *data);
void glClearNamedBufferDataEXT (GLuint buffer, GLenum internalformat, GLenum format, GLenum type, const void *data);
void glClearNamedBufferSubDataEXT (GLuint buffer, GLenum internalformat, GLenum format, GLenum type, GLsizeiptr offset, GLsizeiptr size, const void *data);

void glDispatchCompute (GLuint num_groups_x, GLuint num_groups_y, GLuint num_groups_z);
void glDispatchComputeIndirect (GLintptr indirect);

void glCopyImageSubData (GLuint srcName, GLenum srcTarget, GLint srcLevel, GLint srcX, GLint srcY, GLint srcZ, GLuint dstName, GLenum dstTarget, GLint dstLevel, GLint dstX, GLint dstY, GLint dstZ, GLsizei srcWidth, GLsizei srcHeight, GLsizei srcDepth);

void glFramebufferParameteri (GLenum target, GLenum pname, GLint param);
void glGetFramebufferParameteriv (GLenum target, GLenum pname, GLint *params);
void glNamedFramebufferParameteriEXT (GLuint framebuffer, GLenum pname, GLint param);
void glGetNamedFramebufferParameterivEXT (GLuint framebuffer, GLenum pname, GLint *params);

void glGetInternalformati64v (GLenum target, GLenum internalformat, GLenum pname, GLsizei bufSize, GLint64 *params);

void glInvalidateTexSubImage (GLuint texture, GLint level, GLint xoffset, GLint yoffset, GLint zoffset, GLsizei width, GLsizei height, GLsizei depth);
void glInvalidateTexImage (GLuint texture, GLint level);
void glInvalidateBufferSubData (GLuint buffer, GLintptr offset, GLsizeiptr length);
void glInvalidateBufferData (GLuint buffer);
void glInvalidateFramebuffer (GLenum target, GLsizei numAttachments, const GLenum *attachments);
void glInvalidateSubFramebuffer (GLenum target, GLsizei numAttachments, const GLenum *attachments, GLint x, GLint y, GLsizei width, GLsizei height);

void glMultiDrawArraysIndirect (GLenum mode, const void *indirect, GLsizei drawcount, GLsizei stride);
void glMultiDrawElementsIndirect (GLenum mode, GLenum type, const void *indirect, GLsizei drawcount, GLsizei stride);

void glGetProgramInterfaceiv (GLuint program, GLenum programInterface, GLenum pname, GLint *params);
GLuint glGetProgramResourceIndex (GLuint program, GLenum programInterface, const GLchar *name);
void glGetProgramResourceName (GLuint program, GLenum programInterface, GLuint index, GLsizei bufSize, GLsizei *length, GLchar *name);
void glGetProgramResourceiv (GLuint program, GLenum programInterface, GLuint index, GLsizei propCount, const GLenum *props, GLsizei bufSize, GLsizei *length, GLint *params);
GLint glGetProgramResourceLocation (GLuint program, GLenum programInterface, const GLchar *name);
GLint glGetProgramResourceLocationIndex (GLuint program, GLenum programInterface, const GLchar *name);

void glShaderStorageBlockBinding (GLuint program, GLuint storageBlockIndex, GLuint storageBlockBinding);

void glTexBufferRange (GLenum target, GLenum internalformat, GLuint buffer, GLintptr offset, GLsizeiptr size);
void glTextureBufferRangeEXT (GLuint texture, GLenum target, GLenum internalformat, GLuint buffer, GLintptr offset, GLsizeiptr size);

void glTexStorage2DMultisample (GLenum target, GLsizei samples, GLenum internalformat, GLsizei width, GLsizei height, GLboolean fixedsamplelocations);
void glTexStorage3DMultisample (GLenum target, GLsizei samples, GLenum internalformat, GLsizei width, GLsizei height, GLsizei depth, GLboolean fixedsamplelocations);
void glTextureStorage2DMultisampleEXT (GLuint texture, GLenum target, GLsizei samples, GLenum internalformat, GLsizei width, GLsizei height, GLboolean fixedsamplelocations);
void glTextureStorage3DMultisampleEXT (GLuint texture, GLenum target, GLsizei samples, GLenum internalformat, GLsizei width, GLsizei height, GLsizei depth, GLboolean fixedsamplelocations);

void glTextureView (GLuint texture, GLenum target, GLuint origtexture, GLenum internalformat, GLuint minlevel, GLuint numlevels, GLuint minlayer, GLuint numlayers);

void glBindVertexBuffer (GLuint bindingindex, GLuint buffer, GLintptr offset, GLsizei stride);
void glVertexAttribFormat (GLuint attribindex, GLint size, GLenum type, GLboolean normalized, GLuint relativeoffset);
void glVertexAttribIFormat (GLuint attribindex, GLint size, GLenum type, GLuint relativeoffset);
void glVertexAttribLFormat (GLuint attribindex, GLint size, GLenum type, GLuint relativeoffset);
void glVertexAttribBinding (GLuint attribindex, GLuint bindingindex);
void glVertexBindingDivisor (GLuint bindingindex, GLuint divisor);
void glVertexArrayBindVertexBufferEXT (GLuint vaobj, GLuint bindingindex, GLuint buffer, GLintptr offset, GLsizei stride);
void glVertexArrayVertexAttribFormatEXT (GLuint vaobj, GLuint attribindex, GLint size, GLenum type, GLboolean normalized, GLuint relativeoffset);
void glVertexArrayVertexAttribIFormatEXT (GLuint vaobj, GLuint attribindex, GLint size, GLenum type, GLuint relativeoffset);
void glVertexArrayVertexAttribLFormatEXT (GLuint vaobj, GLuint attribindex, GLint size, GLenum type, GLuint relativeoffset);
void glVertexArrayVertexAttribBindingEXT (GLuint vaobj, GLuint attribindex, GLuint bindingindex);
void glVertexArrayVertexBindingDivisorEXT (GLuint vaobj, GLuint bindingindex, GLuint divisor);
]]

return lib
