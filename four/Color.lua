--[[--
  four.Color
  @V4@ vectors as RGBA colors. 

  Provides a few convenience functions to specify colors in @V4@ vectors.

  *Note* Color values are @V4@ vectors, you can use all the functions of @V4@ 
  on them.
--]]--
local lub  = require 'lub'
local four = require 'four'
local lib  = lub.class 'four.Color'

local V4 = four.V4

-- h2. Constructors and accessors

--[[--
  @Color(r, g, b [,a])@ is a color with the corresponding components.
  @a@ is @1@ if unspecified.
  
  @Color(o)@ is a color converted from the object @o@. Supported types
  for @o@: none.
--]]--
function lib.new(r, g, b, a) 
  if g then return V4(r, g, b, a or 1)
  else
    assert(false, string.format("Cannot convert %s to %s", r.type, V4.type))
  end
end

local Color = lib.new

--[[-- 
  @HSV(h, s, v [,a])@ is an RGBA color with hue @h@, staturation
  @s@, and value @v@. @a@ is @1@ if unspecified.

  *Important* HSV components are all in the @0@ to @1@ range.
--]]--
function lib.HSV(h, s, v, a)
  local r, g, b
  if s == 0 then return Color(v, v, v, a) end
  local sector = (h * 360) / 60
  local i = math.floor(sector)
  local f = sector - i
  local p = v * (1 - s)
  local q = v * (1 - s * f)
  local t = v * (1 - s * (1 - f))
  if i == 0 then return Color(v, t, p, a)
  elseif i == 1 then return Color(q, v, p, a)
  elseif i == 2 then return Color(p, v, t, a)
  elseif i == 3 then return Color(p, q, v, a)
  elseif i == 4 then return Color(t, p, v, a)
  else return Color(v, p, q, a) end
end

-- @r(c)@ is the @r@ component of @c@.
function lib.r(c) return c[1] end

-- @g(c)@ is the @g@ component of @c@.
function lib.g(c) return c[2] end

-- @b(c)@ is the @b@ component of @c@.
function lib.b(c) return c[3] end

-- @a(c)@ is the @a@ component of @c@.
function lib.a(c) return c[4] end

-- @h(c)@ is the hue component of @c@.
function lib.h(c) 
  local h, s, v, a = lib.tupleHSV(c)
  return h
end

-- @s(c)@ is the staturation component of @c@.
function lib.s(c)
  local h, s, v, a = lib.tupleHSV(c)
  return s
end

-- @v(c)@ is the value component of @c@.
function lib.v(c) 
  local h, s, v, a = lib.tupleHSV(c)
  return v
end


-- h2. Converters

-- @toHSV(c) is V4(h, s, v, a), the HSV components of @c@. 
function lib.toHSV(c)
  local r, g, b, a = lib.tuple(c)
  local min = math.min (r, g, b) 
  local max = math.max (r, g, b)
  if max == 0 then return V4(0, 0, 0, a) end
  local delta = max - min
  local v = max
  local s = delta / max
  local h
  if r == max then h = (g - b) / delta 
  elseif g == max then h = 2 + (b - r) / delta
  else h = 4 + (r - g) / delta
  end
  h = h * 60
  if h < 0 then h = h + 360 end
  return V4(h / 360, s, v, a)
end

-- @tuple(c)@ is @r, g, b, a@, the components of @c@.
lib.tuple = V4.tuple

-- @tupleHSV(c)@ is @h, s, v, a@ the components of @c@.
function lib.tupleHSV(c) return V3.tuple(lib.toHSV(c)) end

-- @tostring(c)@ is a textual representation of @c@.
lib.tostring = V4.tostring

-- @tostringHSV(c)@ is a textual representation of @c@.
function lib.tostringHSV(c) return V4.tostring(lib.toHSV(c)) end


-- h2. Constants

-- @void()@ is @Color(0, 0, 0, 0)@.
function lib.void () return Color(0, 0, 0, 0) end

-- @black()@ is @Color(0, 0, 0, 1)@.
function lib.black () return Color(0, 0, 0, 1) end

-- @white()@ is @Color(1, 1, 1, 1)@.
function lib.white () return Color(1, 1, 1, 1) end

-- @gray(g [,a])@ is @Color(g, g, g, a)@. @a@ is @1@ if unspecified.
function lib.gray(g, a) return Color(g, g, g, a) end

-- @red([,a])@ is @Color(1, 0, 0, a)@. @a@ is @1@ if unspecified.
function lib.red(a) return Color(1, 0, 0, a) end

-- @green([,a])@ is @Color(0, 1, 0, a)@. @a@ is @1@ if unspecified.
function lib.green(a) return Color(0, 1, 0, a) end

-- @blue([,a])@ is @Color(0, 0, 1, a)@. @a@ is @1@ if unspecified.
function lib.blue(a) return Color(0, 0, 1, a) end

return lib
