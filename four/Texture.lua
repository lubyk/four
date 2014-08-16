--[[--
  h1. four.Texture
--]]--

-- Module definition
local lub  = require 'lub'
local four = require 'four'
local lib  = lub.class 'four.Texture'

-- h2. Texture type

lib.TYPE_1D = 1
lib.TYPE_2D = 2
lib.TYPE_3D = 3
lib.TYPE_BUFFER = 4
-- TODO lib.TYPE_CUBE_MAP = 4 

-- h2. Texture filtering

lib.MIN_NEAREST = 1
lib.MIN_LINEAR = 2
lib.MIN_NEAREST_MIPMAP_NEAREST = 3
lib.MIN_LINEAR_MIPMAP_NEAREST = 4
lib.MIN_NEAREST_MIPMAP_LINEAR = 5
lib.MIN_LINEAR_MIPMAP_LINEAR = 6

lib.MAG_NEAREST = 7
lib.MAG_LINEAR = 8

-- h2. Texture wrapping

lib.WRAP_CLAMP_TO_EDGE = 1
lib.WRAP_REPEAT = 2

-- h2. Texture internal format
-- A selection from http://www.opengl.org/wiki/Image_Formats#Required_formats
-- More could be added.
-- Suffixes
-- * UN, unsigned normalized
-- * F, floating point

lib.R_8UN = 1
lib.R_32F = 2

lib.RG_8UN = 3
lib.RG_32F = 4

lib.RGB_8UN = 5
lib.RGB_32F = 6

lib.RGBA_8UN = 7
lib.RGBA_32F = 8

lib.SRGB_8UN = 9
lib.SRGBA_8UN = 10

lib.DEPTH_24UN = 11
lib.DEPTH_STENCIL_24UN_8UN = 12
lib.DEPTH_32F = 13
lib.DEPTH_STENCIL_32F_8UN = 14

lib.BGRA_8UN = 15

--[[--
  @Texture(def)@ is a new texture object. @def@ keys:
  * @type@, the texture type (defaults to @TYPE_2D@). 
  * @size@, the dimensions of the texture as a V3 vector (width, height, depth).
    *Note* a 1D texture of width @w@ has a size @V3(w, 1, 1)@. 
    *Note* Irrelevant for @TYPE_BUFFER@.
  * @internal_format@, the internal format (defaults to @RGBA8UI@).
    Together with @size@ (if applicable) implicetly defines the scalar 
    length of data. Should be number of components * size.x * size.y * size.d.
    *Warning* for @TYPE_BUFFER@, 3 components formats need 
    @GL_ARB_texture_buffer_object_rgb32@, but seems to work on OSX.
  * @wrap_s@, wrapping behaviour along @s@ dimension 
    (defaults to @WRAP_REPEAT@). 
  * @wrap_t@, wrapping behaviour along @t@ dimension (if applicable, 
    defaults to @WRAP_REPEAT@). 
  * @wrap_r@, wrapping behaviour along @r@ dimension (if applicable, 
    defaults to @WRAP_REPEAT@).
  * @min_filter@, minification filter (defaults to @MIN_NEAREST_MIPMAP_LINEAR@).
  * @mag_filter@, magnificiation filter (defaults to @MAG_NEAREST@). 
  * @generate_mipmaps@, @true@ if mipmaps should be generated 
    (defaults to @false@). 
  * @data@, a Buffer object with the image data (pixel by pixel in row order, 
    then layer order, the first pixel of the buffer is the image's lower left 
    frontmost pixel. Can be nil if you don't want to specify image data
    (e.g. for render to texture) but not for @TYPE_BUFFER@. 
    TODO if array cube map, images of a cube map in given order.
  * @updated@, if @true@, @data@ will be read again by the renderer. The
    renderer sets the flag to @false@ once he read the data.
--]]--
function lib.new(def)
  local self = 
    { type = lib.TYPE_2D,
      size = four.V3.zero (),
      internal_format = lib.RGBA8UI,
      wrap_s = lib.WRAP_REPEAT,
      wrap_t = lib.WRAP_REPEAT,
      wrap_r = lib.WRAP_REPEAT,
      min_filter = lib.MIN_NEAREST_MIPMAP_LINEAR,
      mag_filter = lib.MAG_NEAREST,
      generate_mipmaps = false,
      data = nil,
      updated = true }               
    setmetatable(self, lib)
    if def then self:set(def) end
    return self
end

function lib:set(def) 
  if def.type ~= nil then self.type = def.type end
  if def.size ~= nil then self.size = def.size end
  if def.internal_format ~= nil then 
    self.internal_format = def.internal_format 
  end
  if def.wrap_s ~= nil then self.wrap_s = def.wrap_s end  
  if def.wrap_t ~= nil then self.wrap_t = def.wrap_t end
  if def.wrap_r ~= nil then self.wrap_r = def.wrap_r end
  if def.min_filter ~= nil then self.min_filter = def.min_filter end
  if def.mag_filter ~= nil then self.mag_filter = def.mag_filter end
  if def.generate_mipmaps ~= nil then 
    self.generate_mipmaps = def.generate_mipmaps 
  end
  if def.data ~= nil then self.data = def.data end
  if def.updated ~= nil then self.updated = def.updated end
end

return lib
