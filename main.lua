local Galaxy = require "galaxy"
local GalaxyView = require "galaxyview"
local SolarView = require "solarview"
local Agent = require "agent"
require "astar"



local effect
local galaxy
local view
local time = 10000 + math.random()*1000
local lastdt = 0

function love.load()
    galaxy = Galaxy:generate(30000)
    for i = 1, 10000 do
        local star = galaxy.stars[math.floor(math.random()*#galaxy.stars) + 1]

        if star then
            local agent = Agent(star)
        
            local path = agent:randomPath(galaxy)
            if path then
                agent:setHeading(path)
                table.insert(galaxy.agents, agent)
            end
        end
    end

    galaxyview = GalaxyView(galaxy)
    solar = SolarView(galaxy.stars[1])

    view = galaxyview
    print(view)
end

function love.draw()
    view:draw(time)
end

function love.update(dt)
    lastdt = dt
    dt = dt
    time = time + dt * 5

    if not view.update then return end
    galaxyview:update(dt)

    if view == solar then
        view:update(dt)
    end
    for i,v in ipairs(galaxy.agents) do
        --v:update(dt, galaxy)
    end
end

function love.mousemoved( x, y, dx, dy, istouch )
    if not view.mousemoved then return end
    view:mousemoved( x, y, dx, dy, istouch )
end

function love.wheelmoved(x, y)
    view:wheelmoved(x, y)
end

function love.keypressed(key)
    if key == "backspace" then
        local star
        while not star do
            star = galaxy.stars[math.floor(#galaxy.stars * math.random())]
        end
        solar = SolarView(star)
        view = solar
    end

    if key == "tab" then
        love.mouse.setRelativeMode(false)
        if view == solar then
            view = galaxyview
        else
            view = solar
        end
    end

    view:keypressed(key)
end