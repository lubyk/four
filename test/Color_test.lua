--[[--
  four.Color test
--]]--

require 'lubyk'
local should = test.Suite("Color")
local Color = four.Color
local V4 = four.V4

function should.beV4()
  assertEqual(V4.type, Color(1,1,1,1).type)
end
