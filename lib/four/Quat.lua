--[[--
  h1. four.Quat
  Quaternions

  Unit quaternions represent orientations/rotations in 3D space. They
  allow to smoothly interpolate between orientations. A quaternion is
  a 4D vector whose components @x, y, z, w@ represent the quaternion
  @xi + yj + zk + w@.
--]]--

local lib = { type = 'four.Quat' }
lib.__index = lib
four.Quat = lib
setmetatable(lib, { __call = function(lib, ...) return lib.Quat(...) end })

local V3 = four.V3
local V4 = four.V4
local M4 = four.M4

-- h2. Constructor

local meta = {} -- for operators, see at the end of file

--[[--
  @Quat(x, y, z, w)@ is a quaternion with the corresponding components.

  @Quat(o)@ is a quaternion converted from the object @o@. Supported
  types for @o@: @bt.Quaternion@.
--]]--
function lib.Quat(x, y, z, w) 
  local q = {} 
  if y then q = { x, y, z, w }    
  else
    if x.type == "bt.Quaternion" then 
      q = { x:getX(), x:getY(), x:getZ(), x:getW() }
    else
      assert(false, string.format("Cannot convert %s to %s", x.type, lib.type))
    end
  end
  setmetatable(q, meta)
  return q
end

local Quat = lib.Quat


-- h2. Converters

-- @ofV4(v)@ is a quaternion with @v@'s components. 
function lib.ofV4(v) return V4(v[1], v[2], v[3], v[4]) end

-- @tuple(q)@ is @x, y, z, w@, the components of @q@.
lib.tuple = V4.tuple

-- @tostring(q)@ is a textual representation of @q@.
lib.tostring = V4.tostring

--[[--
  @ofM4(m)@ is the unit quaternion for the rotation in the 3x3 top left matrix 
  of @m@.
--]]--
function lib.ofM4(m)
  local function v(x, y, z, w) return lib.unit(Quat(x, y, z, w)) end
  local tr = 1 + m[1] + m[6] + m[11]
  if (tr > 0.0) then
    local s = math.sqrt(tr) * 2
    return v((m[7] - m[10]) / s,
             (m[9] - m[3]) / s,
             (m[2] - m[5]) / s,
             0.25 * s)
  elseif (m[1] > m[6] and m[1] > m[11]) then
    local s = math.sqrt(1 + m[1] - m[6] - m[11]) * 2
    return v(0.25 * s,
             (m[2] + m[5]) / s,
             (m[9] + m[3]) / s,
             (m[7] - m[10]) / s)
  elseif (m[6] > m[11]) then
    local s = math.sqrt(1 + m[6] - m[1] - m[11]) * 2
    return v ((m[2] + m[5]) / s,
              0.25 * s,
              (m[7] + m[10]) / s,
              (m[9] - m[3]) / s)
  else
    local s = math.sqrt(1 + m[11] - m[1] - m[6]) * 2
    return v((m[9] + m[3]) / s,
             (m[7] + m[10]) / s,
             0.25 * s,
             (m[2] - m[5]) / s)
  end
end

--[[--
  @toM4(q)@ is the @M4@ matrix corresponding to the rotation of the *unit* 
  quaternion @q@.
--]]--
function lib.toM4(q)
  local x2 = q[1] + q[1] local y2 = q[2] + q[2] local z2 = q[3] + q[3]
  local xx2 = x2 * q[1] local xy2 = x2 * q[2] local xz2 = x2 * q[3]
  local xw2 = x2 * q[4] local yy2 = y2 * q[2] local yz2 = y2 * q[3]
  local yw2 = y2 * q[4] local zz2 = z2 * q[3] local zw2 = z2 * q[4]
  return M4(1 - yy2 - zz2,     xy2 - zw2,     xz2 + yw2,  0,
                xy2 + zw2, 1 - xx2 - zz2,     yz2 - xw2,  0,
                xz2 - yw2,     yz2 + xw2, 1 - xx2 - yy2,  0,
                0,                     0,             0,  1)
end


-- h2. Constants 

lib.quat_eps = 1e-9

-- @zero()@ is the zero quaternion.
lib.zero = V4.zero

-- @id()@ is the identity quaternion.
lib.id = V4.ow


-- h2. Functions

-- @mul(q, r)@ is the quaternion multiplication @q * r@
function lib.mul(r, q) -- TODO why ? WHY WHY ? 
  return Quat(q[2] * r[3] - q[3] * r[2] + q[1] * r[4] + q[4] * r[1],
              q[3] * r[1] - q[1] * r[3] + q[2] * r[4] + q[4] * r[2],
              q[1] * r[2] - q[2] * r[1] + q[3] * r[4] + q[4] * r[3],
              q[4] * r[4] - q[1] * r[1] - q[2] * r[2] - q[3] * r[3])
end

-- @conj(q)@ is the quaternion conjugate @q*@
function lib.conj(q) return Quat(-q[1], -q[2], -q[3], q[4]) end

-- @unit(q)@ is the @unit@ quaternion @q/|q|@.
lib.unit = V4.unit

-- @inv(q)@ is the quaternion inverse @q^-1@
function lib.inv(q)
  local m = V4.norm2(q)
  return V4.smul(1 / m, conj(q))
end

--[[--
  @slerp(q, r, t)@ is the spherical spherical linear interpolation between 
  @q@ and @r@ at @t@. Non commutative, torque minimal and constant velocity.
--]]--
function lib.slerp(q, r, t)
  local cosv = V4.dot(q, r)
  local a = math.acos(cosv) 
  if a < quat_eps then return q else
    local sinv = math.sin(a)
    local c1 = math.sin((1 - t) * a) / sinv
    local c2 = math.sin(t * a) / sinv 
    return V4.add(V4.smul(c1, q), V4.smul(c2, r))
  end
end  

--[[--
  @squad(c, cq, cr, r, t)@ is the spherical cubic interpolation between @q@ 
  and @r@ at @t@. @cq@ and @cr@ respectively indicate the tangent 
  orientations at @q@ and @r@.
--]]--
function lib.squad(c, cq, cr, r, t)
  local u = slerp(q, r, t)
  local v = slerp(cq, cr, t)
  return slerp(u, v, 2 * t * (1 - t))
end

--[[--
  @nlerp(q, r, t)@ is the normalized linear interpolation between @q@ and @r@ 
  at @t@. Commutative torque minimal and inconstant velocity.
--]]--
function lib.nlerp(q, r, t)
  return V4.unit(V4.add (q, V4.smul(t, V4.sub(r, q))))
end

--[[--
  h2. 3D space transformation and orientations
  See also the conversions from/to @M4@.
--]]--

--[[--
  @rotMap(u, v)@ is the unit quaternion for the rotation that maps the
  *unit* vector @u@ on the *unit* vector @v@. 
--]]--
function lib.rotMap(u, v)
  local e = V3.dot(u, v)
  local c = V3.cross(u, v)
  local r = math.sqrt (2 * (1 + e))
  return Quat(c[1] / r, c[2] / r, c[3] / r, r / 2)
end

--[[--
  @rotAxis(u, theta)@ is the unit quaternion for the rotation that rotates
  3D space by @theta@ around the *unit* vector @u@.
--]]--
function lib.rotAxis(u, theta)
  local a = theta * 0.5
  local s = math.sin(a)
  return Quat(s * u[1], s * u[2], s * u[3], math.cos(a))
end

--[[--
  @rotZYX(V3(x, y, z))@ is the unit quaternion for the rotation that rotates
  space first by @x@ around the x-axis, then by @y@ around the y-axis and
  finally by @z@ around the z-axis.
--]]--
function  lib.rotZYX(r)
  local hz = r[3] * 0.5
  local hy = r[2] * 0.5
  local hx = r[1] * 0.5
  local cz = math.cos(hz) local sz = math.sin(hz)
  local cy = math.cos(hy) local sy = math.sin(hy)
  local cx = math.cos(hx) local sx = math.sin(hx)
  local cycz = cy * cz local sysz = sy * sz
  local cysz = cy * sz local sycz = sy * cz
  return Quat(cycz * sx - sysz * cx,
              cysz * sx + sycz * cx,
              cysz * cx - sycz * sx,
              cycz * cx + sysz * sx)
end

--[[--
  @toZYX(q)@ is a @V3@ with the @x@, @y@ and @z@ axis angles of the *unit* 
  quaternion @q@.
--]]--
function lib.toZYX(q)
    local xx = q[1] * q[1] local yy = q[2] * q[2] local zz = q[3] * q[3]
    local ww = q[4] * q[4] 
    local wx = q[4] * q[1] local wy = q[4] * q[2] local wz = q[4] * q[3]
    local zx = q[3] * q[1] local zy = q[3] * q[2]
    local xy = q[1] * q[2]
    return V3(math.atan2(2 * (zy + wx), ww - xx - yy + zz),
              math.asin(-2 * (zx - wy)),
              math.atan2(2 * (xy + wz), ww + xx - yy - zz))
end

--[[--
  @toAxis(q)@ is @axis, angle@ the rotation axis and angle of the 
  *unit* quaternion @q@. 
--]]--
function lib.toAxis(q) 
  local a_2 = math.acos(q[4])
  if a_2 < quat_eps then return V3(1, 0, 0), 0 else
    local d = 1 / math.sin(a_2)
    return V3(q[1] * d, q[2] * d, q[3] * d), (a_2 * 2) 
  end
end

--[[--
  @apply3D(q, pt)@ applies the rotation of the *unit* quaternion @q@
  to the point @pt@.
--]]--
function lib.apply3D(q, v)                 -- NOTE, code duplicate with apply4D
  local wx = q[4] * q[1] local wy = q[4] * q[2] local wz = q[4] * q[3]
  local xx = q[1] * q[1] local xy = q[1] * q[2] local xz = q[1] * q[3]
  local yy = q[2] * q[2] local yz = q[2] * q[3] local zz = q[3] * q[3]
  local x = v[1] local y = v[2] local z = v[3]
  return V3(x + 2 * ((- yy - zz) * x + (xy - wz) * y + (wy + xz) * z),
            y + 2 * ((wz + xy) * x + (- xx - zz) * y + (yz - wx) * z),
            z + 2 * ((xz - wy) * x + (wx + yz) * y + (- xx - yy) * z))
end

--[[--
  @apply4D(q, pt)@ applies the rotation of the *unit* quaternion @q@ 
  to the homogeneous point @pt@.
--]]--
function lib.apply4D(q, v)                 -- NOTE, code duplicate with apply3D
    local wx = q[4] * q[1] local wy = q[4] * q[2] local wz = q[4] * q[3]
    local xx = q[1] * q[1] local xy = q[1] * q[2] local xz = q[1] * q[3]
    local yy = q[2] * q[2] local yz = q[2] * q[3] local zz = q[3] * q[3]
    local x = v[1] local y = v[2] local z = v[3]
    return V4(x + 2 * ((- yy - zz) * x + (xy - wz) * y + (wy + xz) * z),
              y + 2 * ((wz + xy) * x + (- xx - zz) * y + (yz - wx) * z),
              z + 2 * ((xz - wy) * x + (wx + yz) * y + (- xx - yy) * z),
              v[4])
end


-- h2. Operators

meta.__unm = V4.neg
meta.__add = V4.add
meta.__sub = V4.sub
meta.__mul = lib.mul
meta.__tostring = lib.tostring
