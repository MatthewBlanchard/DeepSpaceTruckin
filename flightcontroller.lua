local Object = require "object"
local vec3 = require "math/vec3"
local mat4 = require "math/mat4"
local g3d = require "g3d"

local FlightController = Object:extend()

function FlightController:__new()
    -- orientation and position
    self.position = vec3(-100, 0, 0)
    self.forward = vec3(1, 0, 0)
    self.right = vec3(0, 1, 0)
    self.up = vec3(0, 0, 1)
    
    -- physics and flight characteristics
    self.velocity = vec3(0, 0, 0)
    self.mass = 1
    self.force = 5
    self.throttle = 0

    -- control tuning
    self.rollTime = 0
    self.maxRollTime = 0.3

    self.throttle = 0
    self.curve = function(throttle)
        return self.force * self.throttle * self.throttle * self.throttle
    end

    -- mouselook deltas TODO: remove
    self.dx = 0
    self.dy = 0
end

function FlightController:update(dt)
    self:mouselook(dt)
    self:updateThrottle(dt)

    -- set camera fov
    local basefov = math.pi/4
    local speedMaxFov = math.pi/24
    g3d.camera:setFOV(basefov + speedMaxFov * self.throttle * self.throttle * self.throttle * self.throttle)

    if self.curve(throttle) ~= 0 then
        local acceleration = self.curve(throttle) / self.mass
        if self.velocity:length() > 0 then
            self.velocity = self.velocity - self.velocity * math.min(0.7, math.max(0.5, self.velocity:normalize():dot(self.forward))) * dt
        end
        self.velocity = self.velocity + self.forward * acceleration * dt;
    end
    self.position = self.position + self.velocity * dt;

    self.dx, self.dy = 0, 0
end

function FlightController:physics()
end

function FlightController:updateThrottle(dt)
    if love.keyboard.isDown "w" then self.throttle = self.throttle + 0.5 * dt end
    if love.keyboard.isDown "s" then self.throttle = self.throttle - 0.5 * dt end
    
    if self.throttle ~= 0 then
       self.throttle = math.max(math.min(self.throttle, 1), 0)
    end
end

function FlightController:mouselook(dt)
    local dx, dy = self.dx, self.dy
    love.mouse.setRelativeMode(true)

    local sensitivity = 1/100
    local roll = dx*sensitivity
    local pitch = dy*sensitivity

    local yawMat = mat4.fromAxisAngle(self.up, math.rad(-dx*sensitivity))
    local pitchMat = mat4.fromAxisAngle(self.right, math.rad(dy*sensitivity))

    -- technically not mouse but whatever 
    local dz = 0
    local rollDown = false

    if love.keyboard.isDown "a" then dz = 200 * dt rollDown = true end
    if love.keyboard.isDown "d" then dz = -200 * dt rollDown = true end

    if not rollDown then self.rollTime = 0 end
    self.rollTime = self.rollTime + dt
    local t = math.min(self.rollTime, self.maxRollTime) / self.maxRollTime
    local rollMat = mat4.fromAxisAngle(self.forward, math.rad(dz * t * t * t))

    self.forward = (yawMat * rollMat * pitchMat * self.forward):normalize()
    self.right = (yawMat * rollMat * pitchMat * self.right):normalize()
    self.up = (yawMat * rollMat * pitchMat * self.up):normalize()
end

function FlightController:mousemoved(dx, dy)
    self.dx, self.dy = dx, dy
end

function FlightController:getViewMatrix()
    local thirdperson = mat4()
    local thirdpersonOffset = -self.velocity:normalize():lerp(self.forward, 0.75) * 3
    
    return mat4.fromForwardUpRight(self.position, self.forward, self.up, self.right) * mat4:fromTranslation(self.position) * mat4:fromTranslation(thirdpersonOffset)
end

function FlightController:getFirstPersonViewMatrix()
    return mat4.fromForwardUpRight(self.position, self.forward, self.up, self.right) * mat4:fromTranslation(self.position)
end

function FlightController:getRotation()
    return mat4.fromForwardUpRight(self.position, self.forward, self.up, self.right)
end
return FlightController