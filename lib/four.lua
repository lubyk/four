--[[------------------------------------------------------
  # Four rendering library

  For a gentle introduction to the library, please
  have a look at the [tutorials](tutorial.four.html).

--]]------------------------------------------------------
local lub = require 'lub'
local lib = lub.Autoload 'four'

-- Current version respecting [semantic versioning](http://semver.org).
lib.VERSION = '1.0.0'

lib.DEPENDS = { -- doc
  -- Compatible with LuaJIT
  "luajit >= 5.1, < 5.3",
  -- Uses [Lubyk base library](http://doc.lubyk.org/lub.html)
  'lub >= 1.0.3, < 1.1',
  -- Uses [Lubyk networking and realtime](http://doc.lubyk.org/lens.html)
  'lens >= 1.0.0, < 1.1',
  -- Uses [Lubyk simple UI](http://doc.lubyk.org/lui.html)
  'lui >= 1.0.0, < 1.1',
}

return lib
