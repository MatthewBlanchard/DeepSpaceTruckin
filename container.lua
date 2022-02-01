local Object = require "object"

local Container = Object:extend()

function Container:__new()
    self.agents = {}
end

return Container