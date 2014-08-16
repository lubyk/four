--[[------------------------------------------------------

  # four.Color test

--]]------------------------------------------------------
local lub    = require 'lub'
local lut    = require 'lut'

local four   = require  'four'
local should = lut.Test 'four.Color'
local Color  = four.Color

function should.haveType()
  assertEqual('four.Color', Color(1,1,1,1).type)
end

should:test()
