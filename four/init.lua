--[[--------------------
  # four <a href="https://travis-ci.org/lubyk/four"><img src="https://travis-ci.org/lubyk/four.png" alt="Build Status"></a> 

  Lightweight OpenGL rendering engine for providing a basic abstraction layer
  for compositional GLSL shader programming and rendering.

  <html><a href="https://github.com/lubyk/four"><img style="position: absolute; top: 0; right: 0; border: 0;" src="https://s3.amazonaws.com/github/ribbons/forkme_right_green_007200.png" alt="Fork me on GitHub"></a></html>
  
  *MIT license* &copy Daniel C. Bünzli, Gaspard Bucher 2014.

  ## Installation
  
  With [luarocks](http://luarocks.org):

    $ luarocks install four

  For a gentle introduction to the library, please have a look at the
  [tutorials](tutorial.four.html).

--]]--------------------
local lub  = require 'lub'
local lib  = lub.Autoload 'four'

-- Current version respecting [semantic versioning](http://semver.org).
lib.VERSION = '1.0.0'

lib.DEPENDS = { -- doc
  -- Compatible with LuaJIT (uses ffi for OpenGL bindings).
  "lua >= 5.1, < 5.3",
  -- Uses [Lubyk base library](http://doc.lubyk.org/lub.html)
  'lub >= 1.0.3, < 2',
  -- Uses [Lubyk networking and realtime](http://doc.lubyk.org/lens.html)
  'lens >= 1.0.0, < 2',
  -- Uses [Lubyk simple UI](http://doc.lubyk.org/lui.html)
  'lui >= 1.0.0, < 2',
}

-- nodoc
lib.DESCRIPTION = {
  summary = "",
  detailed = [[
  ]],
  homepage = "http://doc.lubyk.org/four.html",
  author   = "Daniel C. Bünzli, Gaspard Bucher",
  license  = "MIT",
}

-- nodoc
lib.BUILD = {
  github    = 'lubyk',
  pure_lua  = true,
}

-- Enable crash on error debugging.
--
-- WARN: This has a *HUGE* performance cost and should only be called during
-- development.
function lib.debug()
  require('four.RendererGL32').debug()
end

return lib
