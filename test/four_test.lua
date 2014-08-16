--[[------------------------------------------------------

  # four test

--]]------------------------------------------------------
local lub    = require 'lub'
local lut    = require 'lut'

local four   = require  'four'
local should = lut.Test 'four'

function should.haveType()
  assertEqual('four', four.type)
end

should:test()
