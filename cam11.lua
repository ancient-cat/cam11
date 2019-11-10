-- Camera library using the new Transform features in love2d 11.0+
--
-- Copyright © 2019 Pedro Gimeno Fortea
--
-- You can do whatever you want with this software, under the sole condition
-- that this notice and any copyright notices are preserved. It is offered
-- with no warrany, not even implied.

-- Cache some functions into locals
local newTransform = love.math.newTransform
local replaceTransform, applyTransform, push, pop, getWidth, getHeight
local getScissor, intersectScissor, setScissor
local xfSetXf, xfXfPt, xfInvXfPt
do
  local lg = love.graphics
  replaceTransform = lg.replaceTransform
  applyTransform = lg.applyTransform
  push = lg.push
  pop = lg.pop
  getWidth = lg.getWidth
  getHeight = lg.getHeight
  getScissor = lg.getScissor
  intersectScissor = lg.intersectScissor
  setScissor = lg.setScissor
  local Xf = debug.getregistry().Transform
  xfSetXf = Xf.setTransformation
  xfXfPt = Xf.transformPoint
  xfInvXfPt = Xf.inverseTransformPoint
end

local Camera = {}
local CameraClassMT = {__call = function (c, ...) return c.new(...) end}
local CameraInstanceMT = {__index = Camera}

local function lazySetXf(self)
  if self.dirty then
    self.dirty = false
    local vp = self.vp
    return xfSetXf(self.xf, 
                   vp[1] + (vp[3] or getWidth()) * vp[5],
                   vp[2] + (vp[4] or getHeight()) * vp[6],
                   self.angle, self.zoom, self.zoom, self.x, self.y)
  end
end

local function setupDisplayAndXf(self)
  lazySetXf(self)
  push()
  local vp, scissor = self.vp, self.scissor
  local x, y, w, h = getScissor()
  scissor[1] = x
  scissor[2] = y
  scissor[3] = w
  scissor[4] = h
  intersectScissor(vp[1], vp[2], vp[3] or getWidth(), vp[4] or getHeight())
end

function Camera:setDirty(dirty)
  self.dirty = dirty ~= false and true or false
end

function Camera:apply()
  setupDisplayAndXf(self)
  return applyTransform(self.xf)
end

function Camera:set()
  setupDisplayAndXf(self)
  return replaceTransform(self.xf)
end

function Camera:unset()
  local scissor = self.scissor
  setScissor(scissor[1], scissor[2], scissor[3], scissor[4])
  return pop()
end

function Camera:setPos(x, y)
  self.dirty = self.x ~= x or self.y ~= y or self.dirty
  self.x = x
  self.y = y
end

function Camera:setZoom(zoom)
  self.dirty = self.zoom ~= zoom or self.dirty
  self.zoom = zoom
end

function Camera:setAngle(angle)
  self.dirty = self.angle ~= angle or self.dirty
  self.angle = angle
end

function Camera:setViewport(x, y, w, h, cx, cy)
  x, y = x or 0, y or 0
  w, h = w or false, h or false
  cx, cy = cx or 0.5, cy or 0.5
  if x ~= self.vp[1] or y ~= self.vp[2] or w ~= self.vp[3] or h ~= self.vp[4]
     or cx ~= self.vp[5] or cy ~= self.vp[6]
  then
    self.dirty = true
  end
  local vp = self.vp
  vp[1] = x
  vp[2] = y
  vp[3] = w
  vp[4] = h
  vp[5] = cx
  vp[6] = cy
end

function Camera:toScreen(x, y)
  lazySetXf(self)
  return xfXfPt(self.xf, x, y)
end

function Camera:toWorld(x, y)
  lazySetXf(self)
  return xfInvXfPt(self.xf, x, y)
end

function Camera:getTransform()
  lazySetXf(self)
  return self.xf
end

function Camera:getPos()
  return self.x, self.y
end

function Camera:getX()
  return self.x
end

function Camera:getY()
  return self.y
end

function Camera:getZoom()
  return self.zoom
end

function Camera:getAngle()
  return self.angle
end

function Camera:getViewport()
  local vp = self.vp
  return vp[1], vp[2], vp[3], vp[4], vp[5], vp[6]
end

function Camera:getVPTopLeft()
  local vp = self.vp
  return vp[1], vp[2]
end

function Camera:getVPBottomRight()
  local vp = self.vp
  return vp[1] + (vp[3] or getWidth()), vp[2] + (vp[4] or getHeight())
end

function Camera:getFocusPoint()
  local vp = self.vp
  return vp[1] + (vp[3] or getWidth()) * vp[5],
         vp[2] + (vp[4] or getHeight()) * vp[6]
end

function Camera.new(x, y, zoom, angle, vpx, vpy, vpw, vph, cx, cy)
  vpx, vpy = vpx or 0, vpy or 0
  vpw, vph = vpw or false, vph or false
  cx, cy = cx or 0.5, cy or 0.5
  local self = {
    x = x or 0;
    y = y or 0;
    zoom = zoom or 1;
    angle = angle or 0;
    vp = {vpx, vpy, vpw, vph, cx, cy};
    xf = newTransform();
    dirty = true;
    scissor = {0,0,0,0};
  }
  return setmetatable(self, CameraInstanceMT)
end

return setmetatable(Camera, CameraClassMT)
