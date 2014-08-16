--[[------------------------------------------------------

  # four.V2 test

--]]------------------------------------------------------
local lub    = require 'lub'
local lut    = require 'lut'

local four   = require  'four'
local should = lut.Test 'four.V2'
local V2     = four.V2


function should.haveType()
  assertEqual('four.V2', V2(0,0).type)
end

should:test()
