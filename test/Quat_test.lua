--[[------------------------------------------------------

  # four.Quat test

--]]------------------------------------------------------
local lub    = require 'lub'
local lut    = require 'lut'

local four   = require  'four'
local should = lut.Test 'four.Quat'
local Quat   = four.Quat


function should.haveType()
  assertEqual('four.Quat', Quat.id().type)
end

