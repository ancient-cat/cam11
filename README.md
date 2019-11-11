# cam11 camera library

## Introduction

This is a simple, low-level camera library that makes use of the
[Transform](https://love2d.org/wiki/Transform) object introduced in LÖVE
(love2d) version 11.0.

It is intended as either a simple camera for games that don't need more, or as
a basis for a more sophisticated camera handling library.

It does not provide any clamping, usually needed for games where the map should
completely cover the viewport even when reaching a border.

It was designed with speed in mind. While camera setup is usually something
that does not require speed, as it's typically performed only once per frame,
operations like transforming points to screen or world coordinates can
potentially be used many times.

This library uses a lazy approach, meaning it does not perform any unnecessary
updates of the transformation. For this to work as expected, it's important
not to access the fields directly unless you understand the consequences, and
use the accessor methods instead.

## Definitions

There seems to be some confusion when defining coordinate systems. Here we will
use *screen coordinates* to mean coordinates relative to the top left of the
screen, the same ones that LÖVE uses by default, and *world coordinates* to
mean coordinates relative to the world that is to be drawn.

## Usage example

This is an **incomplete** example which invokes some made up functions you
could be using in your program, and that aren't defined in this snippet:

```
local cam

function love.load()
  cam = require 'cam11'()
  cam:setZoom(2)
end

function love.update(dt)
  player:update(dt)
  cam:setPos(player:getPos())
end

function love.mousepressed(x, y, b)
  local xw, yw = cam:toWorld(x, y)
  map:mousepressed(xw, yw, b)
end

function love.draw()
  cam:set()
  map:draw()
  player:draw()
  cam:unset()
end
```

## Reference

`local Camera = require 'cam11'`: Returns the Camera class.

`local cam = Camera.new([x], [y], [zoom], [angle], [viewport_x], [viewport_y], [viewport_w], [viewport_h], [focus_x], [focus_y])`:
Create a new camera instance object at the given position, zoom and angle,
using the given viewport. Remember that it's a class method, therefore the dot
syntax must be used, instead of the colon syntax.

`x` and `y` are the position the camera must point to, in world coordinates.
Both default to 0.

`zoom` is the magnification factor. For example, a value of 3 means to magnify
the drawing 3X. The default is 1.

`angle` is the rotation angle, in radians, relative to the focus point.
Following LÖVE's axis conventions, positive values mean clockwise rotation. The
default is 0.

`viewport_x` and `viewport_y` are the coordinates of the top left angle of the
viewport where the camera will be rendered, in screen coordinates. The default
is 0 for both.

`viewport_w` and `viewport_h` are the viewport's width and height. A value of
`false` (the default) or `nil` means to use the current screen width or height
for the corresponding parameter. Note that when using the current width or
height, the current transformation must be invalidated when the screen size
changes, by calling `cam:setDirty()` (described below), such that when it's
needed, it's regenerated with the new width and height. This invalidation can
be done in the `love.resize` and `love.displayrotated` (for 11.3+) events.

The `focus_x` and `focus_y` parameters are the fraction of the viewport's width and height, respectively, that the camera should point to. Both default to 0.5, meaning the centre of the viewport.

`local cam = Camera(...)`: Alternative C++-like syntax for `Camera.new(...)`.

The following are methods of the instance, described using `cam` as the name of the instance:

`cam:setDirty([dirty])`: A value of `true` (default) invalidates the
transformation, meaning it will be regenerated the next time it's needed.
A value of `false` means the transformation will not be regenerated the next
time it's needed, which can potentially lead to invalid results based on an
obsolete transformation. Don't set it to `false` unless you understand the
consequences.

`cam:attach([clip])`: Replaces the LÖVE transformation with the current camera
parameters, remembering the old transformation in order to restore it later.
`cam:attach()` must have one corresponding `cam:detach()`. Always call
`cam:detach()` before calling `cam:attach()` again.

The optional `clip` parameter specifies whether to use the LÖVE scissor to clip
to the viewport. A value of `false` indicates not to clip; otherwise it clips.
The clipping intersects the current scissor, rather to replace it, to be
GUI-friendly. The scissor is restored when calling `cam:detach()`.

`cam:detach()`: Restores the LÖVE transformation that was active since the
latest `cam:attach()`. You must call `cam:attach()` before calling this
function.

`cam:setPos(x, y)`: Changes the current *x* and *y* coordinates that the camera
must point to.

`cam:setZoom(zoom)`: Changes the current zoom of the camera.

`cam:setAngle(angle)`: Changes the current angle of the camera.

`cam:setViewport([x], [y], [w], [h], [fx], [fy])`: Changes the current
viewport's left and top coordinates, width, height, fraction of focus point
horizontal and vertical, respectively. See `Camera.new()` for details.

`cam:toScreen(x, y)`: Transforms world coordinates to screen coordinates, returning the result.

`cam:toWorld(x, y)`: Transforms screen coordinates to world coordinates, returning the result.

`cam:getTransform()`: Returns the current internal `Transform` object.

`cam:getPos()`: Returns the current *x* and *y* coordinates the camera is set to point at, in world coordinates.

`cam:getX()`: Like above, but it returns only the *x* coordinate.

`cam:getY()`: Like above, but it returns only the *y* coordinate.

`cam:getZoom()`: Returns the current zoom value.

`cam:getAngle()`: Returns the angle that the camera is set to, in radians.

`cam:getViewport()`: Returns the x, y, width, height, focus X fraction, focus Y
fraction of the current viewport.

`cam:getVPTopLeft()`: Returns the top left coordinate, in screen coordinates,
of the current viewport. Equivalent to *x* and *y* of `cam:getViewport()`.

`cam:getVPBottomRight()`: Returns the bottom right coordinate, in screen
coordinates, of the current viewport.

`cam:getVPFocusPoint()`: Returns the focus point of the camera, in screen
coordinates.

Note that in order to obtain the current viewport rectangle in world
coordinates, you can use `cam:toWorld(cam:getVPTopLeft())` (for the left and
top) and `cam:toWorld(cam:getVPBottomRight())` (for the right and bottom).
If you use rotation and want a bounding rectangle aligned to your world's axes,
use `math.min()` and `math.max()` on every *x* and *y* coordinate returned. For
example:

```
-- Return left, top, right bottom of the bounding rectangle of the rotated
-- viewport, in world coordinates
local function getBoundingVPRect(cam)
  local left, top = cam:toWorld(cam:getVPTopLeft())
  local right, bottom = cam:toWorld(cam:getVPBottomRight())
  return math.min(left, right), math.min(top, bottom),
         math.max(left, right), math.max(top, bottom)
end
```

## License

This library is distributed under the following license terms:

Copyright © 2019 Pedro Gimeno Fortea

You can do whatever you want with this software, under the sole condition
that this notice and any copyright notices are preserved. It is offered
with no warrany, not even implied.
