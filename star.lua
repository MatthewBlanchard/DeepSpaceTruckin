local Container = require "container"
local Planet = require "planet"
local AsteroidField = require "asteroidfield"

local Star = Container:extend()

function Star:__new(position, size, neighbours, hyperlanes)
    Container.__new(self)
    self.position = position
    self.size = size
    self.neighbours = neighbours or {}
    self.hyperlanes = hyperlanes or {}
    
    local temp = math.random()
    self.color = {1, 0.8 + 0.3 * temp, 0.7 + 0.3 * temp}
    self.planets = {}

    for i = 1, math.max(1, math.floor(8*math.random())) do
        if math.random() < 0.2 then
            table.insert(self.planets, AsteroidField(i))
        else
            table.insert(self.planets, Planet(i))
        end
    end
end

return Star