--[[--
  four.V4 test
--]]--

require 'lubyk'
local should = test.Suite("V4")
local V4 = four.V4

function should.type()
  assertEqual('four.V4', V4(0,0,0,0).type)
end
