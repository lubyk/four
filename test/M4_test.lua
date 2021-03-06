--[[------------------------------------------------------

  # four.M4 test

--]]------------------------------------------------------
local lub    = require 'lub'
local lut    = require 'lut'

local four   = require  'four'
local should = lut.Test 'four.M4'
local M4     = four.M4

function should.haveType()
  assertEqual('four.M4', M4.id().type)
end

should:test()
