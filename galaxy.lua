local Object = require "object"
local Vector2 = require "vector"
local Hyperlane = require "hyperlane"
local Star = require "star"
local shash = require "shash"
local delaunay = require "triangulate"

local Galaxy = Object:extend()


local function coord_to_key(x, y)
    return x + y * 1e7
end

math.randomseed(os.time())
function Galaxy:generate(size) 
    local o = self()
    o.stars = {}
    o.bgstars = {}
    o.edges = {}
    o.agents = {}

    local arms = 1 + math.floor(math.random() * 5)
    local armSeparationDistance =  2 * math.pi / arms
    local armOffsetMax = 1
    local rotationFactor = 5
    local randomOffsetXY = math.random() / 50

    local spatialhash = shash.new(5000)

    for i = 1, size do 
        local distance = math.random()
        distance = math.pow(distance, 2)

        angle = math.random() * 2 * math.pi
        armOffset = math.random() * armOffsetMax
        armOffset = armOffset - armOffsetMax / 2
        armOffset = armOffset * (1 / distance)

        squaredArmOffset = math.pow(armOffset, 2)
        if armOffset < 0 then 
            squaredArmOffset = squaredArmOffset * -1
        end
        armOffset = squaredArmOffset

        rotation = distance * rotationFactor
        angle = math.floor(angle / armSeparationDistance) * armSeparationDistance + armOffset + rotation

        starX = math.cos(angle) * distance
        starY = math.sin(angle) * distance

        randomOffsetX = math.random() * randomOffsetXY
        randomOffsetY = math.random() * randomOffsetXY

        starX = (starX + randomOffsetX) * 50000
        starY = (starY + randomOffsetY) * 50000
        
        spatialhash:add(Vector2(starX, starY), starX, starY, 1, 1)
        table.insert(o.bgstars, Vector2(starX, starY))
    end

    local points = {}
    local starhash = {}
    for _, cell in pairs(spatialhash.cells) do
        if cell[1] then
            local star = Star(cell[1][5], #cell)

            -- we hash star positions to stop a star being put in the same place as another and simply ignore collisions
            starhash[coord_to_key(cell[1][5].x, cell[1][5].y)] = star
        end
    end

    --[[for i = 1,100 do 
        local velocity = {}
        for _, star in ipairs(o.stars) do
            for _, ostar in ipairs(o.stars) do
                if not velocity[ostar] then velocity[ostar] = Vector2(0, 0) end

                velocity[ostar] = (star.position - ostar.position):normalize() * 10000 * math.min(10, 1/ostar.position:distance(star.position))
            end
        end

        for _, star in ipairs(o.stars) do
            star.position = star.position + velocity[star]
        end
    end]]--

    for _, star in pairs(starhash) do
        if star.position:magnitude() < 50000 then
            table.insert(points, delaunay.Point(star.position.x, star.position.y))
            table.insert(o.stars, star)
        end
    end
    
    local triangles = delaunay.triangulate(points)
    
    local edgehash = {}
    for _, triangle in ipairs(triangles) do 
        edgehash[triangle.e1:__tostring()] = triangle.e1
        edgehash[triangle.e2:__tostring()] = triangle.e2
        edgehash[triangle.e3:__tostring()] = triangle.e3
    end

    for k,v in pairs(edgehash) do
        local star1 = starhash[coord_to_key(v.p1.x, v.p1.y)]
        local star2 = starhash[coord_to_key(v.p2.x, v.p2.y)]

        if star1 and star2 then
            if not star1.neighbours[star2] then
                local hasneighbour1 = false
                local hasneighbour2 = false

                for k,v in pairs(star1.neighbours) do
                    hasneighbour1 = true
                end
                for k,v in pairs(star2.neighbours) do
                    hasneighbour2 = true
                end

                hasneighbour = hasneighbour1 and hasneighbour2
                if v:length() < 10000 and (not hasneighbour or math.random() > v:length()/8000) then
                    local hyperlane = Hyperlane(star1, star2)

                    star1.neighbours[star2] = star2
                    star1.hyperlanes[star2] = hyperlane

                    star2.neighbours[star1] = star1
                    star2.hyperlanes[star1] = hyperlane

                    table.insert(o.edges, hyperlane)
                end
            end
        end
    end


    return o
end

function Galaxy:calculateNeighbours() 
    local points = {}

end
-- real quick and dirty
local SpatialHash = Object:extend()

function SpatialHash:__new(points, bucket_count, l, t, w, h)
    self.l = l
    self.t = t
    self.w = w
    self.h = h

    local buckets = {}
    for x = 1, bucket_count + 1 do 
        
    end
end
return Galaxy