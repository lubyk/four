--[[--
  # four.Quat
  Quaternions

  Unit quaternions represent rotations in 3D space. They allow to smoothly
  interpolate between orientations. A quaternion is a 4D vectors whose
  componetns x, y, z, w represent the quatrnion xi + yj + zk + w.
--]]--

-- Module definition  

local lib = { type = 'four.Quat' }
lib.__index = lib
four.Quat = lib
setmetatable(lib, 
{ 
  __call = function(lib, x, y, z, w) return  lib.Quat(x, y, z, w) end 
})

local V4 = four.V4
local V3 = four.V3
local M4 = four.M4

-- ## Constructors

local meta = {} -- for operators

function lib.Quat(x, y, z, w) 
  local o = { x, y, z, w }  
  setmetatable(o, meta)
  return o
end

local Quat = lib.Quat

-- ## Converters

function lib.ofV4(v) return V4(v[1], v[2], v[3], v[4]) end
lib.tuple = V4.tuple
lib.to_string = V4.to_string

-- ## Constants 

lib.zero = V4.zero
lib.id = V4.ow
lib.quat_eps = 1e-9

-- ## Functions

-- quaternion multiplication q * r
function lib.mul(q, r) 
  return Quat(q[2] * r[3] - q[3] * r[2] + q[1] * r[4] + q[4] * r[1],
              q[3] * r[1] - q[1] * r[3] + q[2] * r[4] + q[4] * r[2],
              q[1] * r[2] - q[2] * r[1] + q[3] * r[4] + q[4] * r[3],
              q[4] * r[4] - q[1] * r[1] - q[2] * r[2] - q[3] * r[3])
end

-- quaternion conjugate q*
function lib.conj(q) return Quat(-q[1], -q[2], -q[3], q[4]) end

lib.unit = V4.unit

-- quaternion inverse q^-1
function lib.inv(q)
  local m = V4.norm2(q)
  return V4.smul(1 / m, conj(q))
end

-- spherical linear interpolation between `q` and `r` at `t`. Non 
-- commutative, torque minimal and constant velocity
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

-- spherical cubic interpolation between `q` and `r` at `t`.  `cq` and `cr`
-- indicate the tangent orientations at `q` and `r`
function lib.squad(c, cq, cr, r, t)
  local u = slerp(q, r, t)
  local v = slerp(cq, cr, t)
  return slerp(u, v, 2 * t * (1 - t))
end

-- normalized linear interpolation between `q` and `r` at `t`. Commutative
-- torque minimal and inconstant velocity.
function lib.nlerp(q, r, t)
  return V4.unit(V4.add (q, V4.smul(t, V4.sub(r, q))))
end

-- ## 3D space transformation

-- Unit quaternion for the rotation, see four.M4.rotMap
function lib.rotMap(u, v)
  local e = V3.dot(u, v)
  local c = V3.cross(u, v)
  local r = math.sqrt (2 * (1 + e))
  return Quat(c[1] / r, c[2] / r, c[3] / r, r / 2)
end

-- Unit quaternion for the rotation, see four.m4.rotAxis
function lib.rotAxis(u, theta)
  local a = theta * 0.5
  local s = math.sin(a)
  return Quat(s * u[1], s * u[2], s * u[3], math.cos(a))
end

-- Unit quaternion for the rotation, see four.m4.rotZYX
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

-- Unit quaternion for the rotation in the 3x3 top left matrix in `m`
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

-- `x`, `y` and `z` axis angles of the *unit* quaternion `q`
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

-- tuples the rotation axis and angle of the *unit* quaternion `q`
function lib.toAxis(q) 
  local a_2 = math.acos(q[4])
  if a_2 < quat_eps then return V3(1, 0, 0), 0 else
    local d = 1 / math.sin(a_2)
    return V3(q[1] * d, q[2] * d, q[3] * d), (a_2 * 2) 
  end
end

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

function lib.apply3D(q, v)                 -- NOTE, code duplicate with apply4D
  local wx = q[4] * q[1] local wy = q[4] * q[2] local wz = q[4] * q[3]
  local xx = q[1] * q[1] local xy = q[1] * q[2] local xz = q[1] * q[3]
  local yy = q[2] * q[2] local yz = q[2] * q[3] local zz = q[3] * q[3]
  local x = v[1] local y = v[2] local z = v[3]
  return V3(x + 2 * ((- yy - zz) * x + (xy - wz) * y + (wy + xz) * z),
            y + 2 * ((wz + xy) * x + (- xx - zz) * y + (yz - wx) * z),
            z + 2 * ((xz - wy) * x + (wx + yz) * y + (- xx - yy) * z))
end

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

-- ## Operators

meta.__unm = V4.neg
meta.__add = V4.add
meta.__sub = V4.sub
meta.__mul = lib.mul
meta.__tostring = lib.tostring


