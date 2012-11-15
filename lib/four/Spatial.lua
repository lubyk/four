--[[--
  # four.spatial

  A spatial object orients an object in 3D space. 
  TODO introduce push/pull deps ?
  TODO if not, maybe now rename this into Transform, 
--]]--

-- Module definition

local lib = { type = 'four.Spatial' }
lib.__index = lib
four.Spatial = lib
setmetatable(lib, { __call = function(lib, o) return lib.new(o) end })

local Quat = four.Quat
local V3 = four.V3
local V4 = four.V4
local M4 = four.M4

-- ## Constructor

function lib:set(def) for k, v in pairs(def) do self["_" .. k] = v end end
function lib.new(def)
  local self =
    { _pos = four.V3.zero (),
      _rot = four.Quat.id (),
      _scale = four.V3(1, 1, 1),
      _transform = four.M4.id,
      _dirty_decomp = false,
      _dirty_transform = false }
    setmetatable(self, lib)
    if def then self:set(def) end
    return self
end

function lib:syncTransform()
  self._transform = four.M4.rigidqScale(self._pos, self._rot, self._scale)
end

function lib:syncDecomp()
  self._pos = four.M4.getMove(self._transform)
  self._rot = four.Quat.ofM4(self._transform)
  -- TODO scaling component
end

function lib:pos() 
  if self._dirty_decomp then self:syncDecomp() end
  return self._pos
end

function lib:setPos(p) 
  if self._dirty_decomp then self:syncDecomp() end
  self._dirty_transform = true
  self._pos = p
end

function lib:rot()
  if self._dirty_decomp then self:syncDecomp() end
  return self._rot
end

function lib:setRot(q)
  if self._dirty_decomp then self:syncDecomp() end
  self._dirty_transform = true
  self._rot = q
end

function lib:scale()
  if self.dirty_decomp then self:syncDecomp() end
  return self.scale
end

function lib:setScale(s)
  if self.dirty_decomp then self:syncDecomp() end
  self._dirty_transform = true
  self._scale = s
end

function lib:transform()
  if self.dirty_transform then self:syncTransform() end
  return self._transform
end

function lib:setTransform(m)
  self._dirty_decomp = true
  self._transform = m
end


