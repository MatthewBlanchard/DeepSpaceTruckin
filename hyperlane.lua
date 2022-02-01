local Container = require "container"

local Hyperlane = Container:extend()

function Hyperlane:__new(stara, starb)
    Container.__new(self)
    self.a = stara
    self.b = starb
    self.length = stara.position:distance(starb.position)
end

function Hyperlane:getCost()
    return self.length
end

return Hyperlane