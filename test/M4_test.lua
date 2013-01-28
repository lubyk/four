--[[--
  four.M4 test
--]]--

require 'lubyk'
local should = test.Suite("M4")
local M4 = four.M4

function should.type()
  assertEqual('four.M4', M4.id().type)
end

