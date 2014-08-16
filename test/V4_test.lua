--[[------------------------------------------------------

  # four.V4 test

--]]------------------------------------------------------
local lub    = require 'lub'
local lut    = require 'lut'

local four   = require  'four'
local should = lut.Test 'four.V4'
local V4     = four.V4


function should.haveType()
  assertEqual('four.V4', V4(0,0,0,0).type)
end

should:test()
