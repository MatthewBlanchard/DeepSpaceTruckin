local Object = require "object"

Agent = Object()

function Agent:__new(container, heading)
    self:setContainer(container)
    self.heading = heading
    self.speed = 1000
    self.travelt = 0
end

function Agent:setHeading(heading)
    self.heading = heading
    self.travelt = 0
end

function Agent:update(dt, galaxy)
    self.travelt = self.travelt + self.speed * dt

    if not self.heading or #self.heading <= 1 then
        local path = self:randomPath(galaxy)
        self:setHeading(path)
    end

    if self.container.length ~= nil then
        -- we've got a hyperlane
        if self.travelt > self.container.length then
            self.travelt = 0
            self:setContainer(self.heading[2])
            table.remove(self.heading, 1)
        end
    else
        -- we've got a starsystem
        if self.travelt > 2000 then
            self.travelt = 0
            self.laststar = self.container
            if self.container.hyperlanes[self.heading[2]] then
                self:setContainer(self.container.hyperlanes[self.heading[2]])
            end
        end
    end
end

function Agent:setContainer(container)
    if self.container then
        self.container.agents[self] = nil
    end

    self.container = container
    self.container.agents[self] = self
end

function Agent:randomPath(galaxy)
    if self.container.neighbours then
        local hasneighbour = false
        for _, neighbour in pairs(self.container.neighbours) do
            hasneighbour = true
        end

        if not hasneighbour then return end

        local path
        while not path do
            local start = self.container
            local finish = galaxy.stars[math.floor(math.random()*#galaxy.stars) + 1]
            path = astar.path ( start, finish, galaxy.stars, ignore, valid_node_func )
        end
        
        return path
    end
end
return Agent