local Object = require "object"

local Vector2 = Object:extend()

function Vector2:__new(x, y)
  self.x = x or 0
  self.y = y or 0
end

function Vector2:copy()
  return Vector2(self.x, self.y)
end

function Vector2.magnitude(a)
  return math.sqrt(a.x^2 + a.y^2)
end

function Vector2.normalize(a)
  local m = a:magnitude()
  if m == 0 then return a end
  return a / m
end

function lerp(a,b,t) return a * (1-t) + b * t end
function Vector2.lerp(a, b, t)
  return Vector2(lerp(a.x, b.x, t), lerp(a.y, b.y, t))
end

function Vector2.distance(a, b)
  return math.sqrt((a.x-b.x)^2 + (a.y-b.y)^2)
end

function Vector2.__add(a, b)
  return Vector2(a.x + b.x, a.y + b.y)
end

function Vector2.__sub(a, b)
  return Vector2(a.x - b.x, a.y - b.y)
end

function Vector2.__eq(a, b)
  return a.x == b.x and a.y == b.y
end

function Vector2.__mul(a, b)
  return Vector2(a.x * b, a.y * b)
end

function Vector2.__div(a, b)
  return Vector2(a.x / b, a.y / b)
end

function Vector2:__tostring()
  return "x: " .. self.x .. " y: " .. self.y
end

Vector2.UP = Vector2(0, -1)
Vector2.RIGHT = Vector2(1, 0)
Vector2.DOWN = Vector2(0, 1)
Vector2.LEFT = Vector2(-1, 0)
Vector2.UP_RIGHT = Vector2(1, -1)
Vector2.UP_LEFT = Vector2(-1, -1)
Vector2.DOWN_RIGHT = Vector2(1, 1)
Vector2.DOWN_LEFT = Vector2(-1, 1)


return Vector2
