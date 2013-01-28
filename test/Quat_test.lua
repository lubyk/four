--[[--
  four.Quat test
--]]--

require 'lubyk'
local should = test.Suite("Quat")
local Quat = four.Quat

function should.type()
  assertEqual('four.Quat', Quat.id().type)
end

