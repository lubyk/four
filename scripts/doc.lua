--
-- Generate documentation for this project into 'html' folder
--
local lut = require 'lut'
lut.Doc.make {
  sources = {
    'four',
    {'doc', prepend = 'example/four'},
  },
  copy = { 'doc', prepend = 'example/four', filter = '%.lua' },
  target = 'html',
  format = 'html',
  header = [[<h1><a href='http://lubyk.org'>Lubyk</a> documentation</h1> ]],
  index  = [=[
--[[--
  # Lubyk documentation

  ## List of available modules
--]]--
]=]
}
