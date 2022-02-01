local Object = require "object"
local moonshine = require "moonshine"
local gamera = require "gamera"

GalaxyView = Object:extend()

local function CreateCircle(segments)
	segments = segments or 40
	local vertices = {}
	
	-- The first vertex is at the origin (0, 0) and will be the center of the circle.
	table.insert(vertices, {0, 0})
	
	-- Create the vertices at the edge of the circle.
	for i=0, segments do
		local angle = (i / segments) * math.pi * 2

		-- Unit-circle.
		local x = math.cos(angle) * 100
		local y = math.sin(angle) * 100

		table.insert(vertices, {x, y})
	end
	
	-- The "fan" draw mode is perfect for our circle.
	return love.graphics.newMesh(vertices, "fan", "static")
end

function GalaxyView:__new(galaxy)
    self.galaxy = galaxy
    self.bgmesh =CreateCircle(20)

    local instance_positions = {}
    for _, bgstar in pairs(galaxy.bgstars) do
        table.insert(instance_positions, {bgstar.x, bgstar.y})
    end

    local instancemesh = love.graphics.newMesh({{"InstancePosition", "float", 2}}, instance_positions, nil, "static")
    self.bgmesh:attachAttribute("InstancePosition", instancemesh, "perinstance")

    self.effect = moonshine(moonshine.effects.glow)
                    .chain(moonshine.effects.vignette)

    self.cam = gamera.new(-500000, -500000, 1000000, 1000000)
    self.cam:setScale(0.01)
end

local shader = require "galaxyshader"
function GalaxyView:draw(time)
    self.effect(function()
        local posx, posy = self.cam:getPosition()
        love.graphics.push()
        self.cam:draw(function()
            shader:send("time", time)
            love.graphics.setShader(shader)
            love.graphics.setColor(0.4, 0.4, 0.8)
            love.graphics.drawInstanced(self.bgmesh, #self.galaxy.bgstars, 0, 0)
            love.graphics.setShader()
        end)
        
        self.cam:draw(function()
            for _, hyperlane in ipairs(self.galaxy.edges) do 
                love.graphics.setColor(1, 1, 1, math.min(0.2, 3*self.cam:getScale()))
                local a, b = hyperlane.a.position, hyperlane.b.position
                love.graphics.line(a.x, a.y, b.x, b.y)

            end
            for i = 1, 501 do 
                if self.galaxy.stars[i] then
                    local r, g, b, a = love.graphics.getColor()
                    local cval = love.math.noise(self.galaxy.stars[i].position.x, self.galaxy.stars[i].position.y, time) * 0.2 + 0.8

                    love.graphics.setColor(cval*self.galaxy.stars[i].color[1], cval*self.galaxy.stars[i].color[2], cval*self.galaxy.stars[i].color[3])
                    love.graphics.circle("fill", self.galaxy.stars[i].position.x, self.galaxy.stars[i].position.y, math.min(50 / self.cam:getScale(), 100 + math.min(400, self.galaxy.stars[i].size)))
                    love.graphics.setColor(r, g, b, a)
                end
            end
        end)

        self.cam:draw(function()
            local r, g, b, a = love.graphics.getColor()
            for _, agent in pairs(self.galaxy.agents) do

                if agent.container and agent.container.length and agent.heading and #agent.heading > 1 then
                    -- we've got a hyperlane
                    local hyperlane = agent.container
                    local lerped = agent.heading[1].position:lerp(agent.heading[2].position, agent.travelt / hyperlane.length)
                    love.graphics.setColor(1, 1, 1, 1)
                    love.graphics.circle("fill", lerped.x, lerped.y, 30)
                    love.graphics.setColor(r, g, b, a)
                elseif agent.container and agent.container.position then
                    love.graphics.setColor(1, 1, 1, 1)
                    --love.graphics.circle("fill", agent.container.position.x, agent.container.position.y, 10)
                    love.graphics.setColor(r, g, b, a)
                end
            end

        end)
    end)

    love.graphics.setColor(1, 1, 1)
    love.graphics.print(love.timer.getFPS( ))
    love.graphics.pop()
end

function GalaxyView:update()
end

function GalaxyView:mousemoved( x, y, dx, dy, istouch )
    if love.mouse.isDown(1) then
        local oldx, oldy = self.cam:getPosition()
        local scale = self.cam:getScale()
        self.cam:setPosition(oldx - dx / scale, oldy - dy / scale)
    end
end

function GalaxyView:wheelmoved(x, y)
    if y > 0 then
        self.cam:setScale(self.cam:getScale() * 2)
    elseif y < 0 then
        self.cam:setScale(self.cam:getScale() / 2)
    end
end

return GalaxyView