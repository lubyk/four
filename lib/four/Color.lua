--[[--
  four.Color
  Color 
--]]--

-- TODO hsv support

-- Module definition  

local lib = { type = 'four.Color' }
lib.__index = lib
four.Color = lib
setmetatable(lib, 
{ 
  __call = function(lib, r, g, b, a) return  lib.Color(r, g, b, a) end 
})

local V4 = four.Color

-- ## Constructor

function lib.Color(r, g, b, a) return four.V4(r, g, b, a) end
local Color = lib.Color

-- ## Converters

function lib.ofV4(v) return V4(v[1], v[2], v[3], v[4]) end
lib.tuple = V4.tuple
lib.to_string = V4.to_string

-- ## Constants
 
function lib.void () return Color(0, 0, 0, 0) end
function lib.black () return Color(0, 0, 0, 1) end
function lib.white () return Color(1, 1, 1, 1) end
function lib.gray(g, a) return Color(g, g, g, a or 1) end
function lib.red(a) return Color(1, 0, 0, a or 1) end
function lib.green(a) return Color(0, 1, 0, a or 1) end
function lib.blue(a) return Color(0, 0, 1, a or 1) end



