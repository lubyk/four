--[[--
  # four.FrameBuffer

  Render to texture target for renderer.

--]]--

-- Module definition
local lub  = require 'lub'
local four = require 'four'
local lib  = lub.class 'four.FrameBuffer'

function lib.new(def)
  local self = {
  }
  setmetatable(self, lib)
  if def then
    self:set(def)
  end
  return self
end

function lib:set(def) 
  if def.texture ~= nil then self.texture = def.texture end
end

return lib

