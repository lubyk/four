--[[--
  four.V2 test
--]]--

require 'lubyk'
local should = test.Suite("V2")
local V2 = four.V2

function should.type()
  assertEqual('four.V2', V2(0,0).type)
end
