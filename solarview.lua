local Object = require "object"
local Planet = require "planet"
local FlightController = require "flightcontroller"
local moonshine = require "moonshine"
local g3d = require "g3d"
local newMatrix = require(g3d.path .. "/matrices")
local Vector2 = require "vector"
local mat4 = require "math/mat4"

local sphere = g3d.newModel("assets/sphere.obj", nil, {0, 0, 0}, nil, {10, 10, 10})
local ring = g3d.newModel("assets/gate.obj")
local ship = g3d.newModel("assets/Space_Truck.obj", "assets/space_truck.png")
ship:makeNormals()

local bgtextures = {
    love.graphics.newImage("assets/starfield.png"),
    love.graphics.newImage("assets/starfield2.png"),
    love.graphics.newImage("assets/starfield3.png"),
    love.graphics.newImage("assets/starfield4.png")
}

local timer = 0

local shipshader = love.graphics.newShader(g3d.shaderpath, [[
    varying vec4 VertexPos;
    varying vec4 vertexNormal;
    uniform float sunRadius;
    uniform Image environment;

    mat4 rotationMatrix(vec3 axis, float angle)
    {
        axis = normalize(axis);
        float s = sin(angle);
        float c = cos(angle);
        float oc = 1.0 - c;

        return mat4(oc * axis.x * axis.x + c,           oc * axis.x * axis.y - axis.z * s,  oc * axis.z * axis.x + axis.y * s,  0.0,
                    oc * axis.x * axis.y + axis.z * s,  oc * axis.y * axis.y + c,           oc * axis.y * axis.z - axis.x * s,  0.0,
                    oc * axis.z * axis.x - axis.y * s,  oc * axis.y * axis.z + axis.x * s,  oc * axis.z * axis.z + c,           0.0,
                    0.0,                                0.0,                                0.0,                                1.0);
    }

    vec4 effect(vec4 color, Image tex, vec2 texcoord, vec2 pixcoord) {
        vec3 reference = vec3(0., 0., 1.);
        mat4 offset1 = rotationMatrix(vec3(0., 1., 0.), 1.3);
        mat4 offset2 = rotationMatrix(vec3(0., 1., 0.), -1.3);

        vec4 clippedNormal = vec4(0., vertexNormal.yzw);

        vec4 texcolor = Texel(environment, vec2(0., dot(reference, abs(clippedNormal.xyz))));
        texcolor += Texel(environment, vec2(0., dot(reference, abs(offset1 * clippedNormal).xyz)));
        texcolor += Texel(environment, vec2(0., dot(reference, abs(offset2 * clippedNormal).xyz)));

        vec3 sunDir = -normalize(vec3(0., 0., 0.) - VertexPos.xyz);
        vec3 sunClosest = sunDir * sunRadius;
        vec3 lightDir = normalize(sunClosest - VertexPos.xyz);
        vec3 diffuse = max(dot(normalize(vertexNormal.xyz), lightDir), 0.0) * vec3(1., 1., 1.);

        // get rid of transparent pixels
        if (texcolor.a == 0.0) {
            discard;
        }

        return vec4((diffuse + texcolor.xyz/3) * Texel(tex, texcoord).xyz, 1.);
    }
]])


local skyboxshader = love.graphics.newShader(g3d.shaderpath, [[
    varying vec4 vertexPosition;
    varying vec4 vertexNormal;
    vec4 effect(vec4 color, Image tex, vec2 texcoord, vec2 pixcoord) {
        vec3 reference = vec3(0., 0., 1.);

        vec4 texcolor = Texel(tex, vec2(0., dot(reference, abs(vertexNormal.xyz))));

        // get rid of transparent pixels
        if (texcolor.a == 0.0) {
            discard;
        }

        return texcolor * color;
    }
]])

local billboardshader = love.graphics.newShader [[
    uniform mat4 projectionMatrix;
    uniform mat4 modelMatrix;
    uniform mat4 viewMatrix;
    varying vec4 vertexColor;
    uniform bool isCanvasEnabled;  // detect when this model is being rendered to a canvas

    #ifdef VERTEX
        attribute vec4 InstancePosition;

        vec4 position(mat4 transform_projection, vec4 vertex_position)
        {

            vertexColor = VertexColor;

            mat4 modelmat = modelMatrix;
            modelmat[3][0] = InstancePosition.x;
            modelmat[3][1] = InstancePosition.y;
            modelmat[3][2] = InstancePosition.z;

            mat4 modelView = viewMatrix * modelmat;
            modelView[0][0] = 1.0;
            modelView[0][1] = 0.0;
            modelView[0][2] = 0.0;
            modelView[1][0] = 0.0;
            modelView[1][1] = 1.0;
            modelView[1][2] = 0.0;
            modelView[2][0] = 0.0;
            modelView[2][1] = 0.0;
            modelView[2][2] = 1.0;

            vec4 screenpos = projectionMatrix * modelView * vertex_position;
            // for some reason models are flipped vertically when rendering to a canvas
            // so we need to detect when this is being rendered to a canvas, and flip it back
            if (isCanvasEnabled) {
                screenpos.y *= -1.0;
            }
            return screenpos;
        }
    #endif
    #ifdef PIXEL
        vec4 effect(vec4 color, Image tex, vec2 texcoord, vec2 pixcoord)
        {
            vec4 texcolor = Texel(tex, vec2(texcoord.x, 1-texcoord.y));
            if (texcolor.a == 0.0) { discard; }
            return vec4(texcolor)*color*vertexColor;
        }
    #endif
]]

SolarView = Object:extend()


local function CreateCircle(segments, diameter)
	segments = segments or 40
	local vertices = {}

	-- The first vertex is at the origin (0, 0) and will be the center of the circle.
	table.insert(vertices, {0, 0})

	-- Create the vertices at the edge of the circle.
	for i=0, segments do
		local angle = (i / segments) * math.pi * 2

		-- Unit-circle.
		local x = math.cos(angle) * diameter
		local y = math.sin(angle) * diameter

		table.insert(vertices, {x, y})
	end

	-- The "fan" draw mode is perfect for our circle.
	return love.graphics.newMesh(vertices, "fan", "static")
end

function SolarView:__new(star)
    self.star = star
    self.flightController = FlightController()
    self.moonshine = moonshine(moonshine.effects.glow)
    self.starmesh = CreateCircle(3, 100)
    self.background = g3d.newModel("assets/sphere.obj", nil, {0,0,0}, nil, {90000,90000,90000})
    self.background.mesh:setTexture(bgtextures[math.floor(#bgtextures * math.random()) + 1])

    local instance_positions = {}
    for i = 1, 1000 do
        local x, y, z = math.random() - 0.5, math.random() - 0.5, math.random() - 0.5
        local mag = math.sqrt(x^2 + y^2 + z^2)
        local x, y, z = x / mag, y / mag, z / mag
        local value = 50000 - math.random() * 20000
        table.insert(instance_positions, {x * value , y * value, z * value})
    end

    local instancemesh = love.graphics.newMesh({{"InstancePosition", "float", 3}}, instance_positions, nil, "static")
    self.starmesh:attachAttribute("InstancePosition", instancemesh, "perinstance")
end

function SolarView:mousemoved(x,y, dx,dy)
    self.flightController:mousemoved(dx, dy)
end

function SolarView:update(dt)
    timer = timer + dt
    self.background:setTranslation(g3d.camera.position[1], g3d.camera.position[2], g3d.camera.position[3])
    self.flightController:update(dt)
    if love.keyboard.isDown("escape") then love.event.push("quit") end
end

function SolarView:draw(time)
    --self.moonshine(function()
        g3d.camera.viewMatrix = self.flightController:getViewMatrix()
        love.graphics.setShader()
        love.graphics.setColor(1, 1, 1)
        love.graphics.setDepthMode("always", true)
        self.background:draw(skyboxshader)

        love.graphics.setColor(1, 1, 1, 0.5)
        love.graphics.setShader(billboardshader)
        billboardshader:send("modelMatrix", newMatrix())
        billboardshader:send("viewMatrix", g3d.camera.viewMatrix)
        billboardshader:send("projectionMatrix", g3d.camera.projectionMatrix)
        if billboardshader:hasUniform "isCanvasEnabled" then
            billboardshader:send("isCanvasEnabled", love.graphics.getCanvas() ~= nil)
        end
        love.graphics.drawInstanced(self.starmesh, 1000, 0, 0)
        love.graphics.setShader()
        love.graphics.setDepthMode("lequal", true)


        for i, planet in ipairs(self.star.planets) do
            planet:draw(time, self.background.mesh:getTexture())
        end

        for star, hyperlane in pairs(self.star.hyperlanes) do
            local dirto = (star.position - self.star.position):normalize()
            local orbitaloffset = love.math.noise(star.position.x, star.position.y) - 0.5

            local angle = math.atan2(dirto.x, dirto.y) + math.rad(90)
            local x, y = math.cos(angle), math.sin(angle)
            ring:setRotation(angle, math.rad(90), 0)
            local ringdist =  math.max(40 + #self.star.planets *20, 100)
            ring:setTranslation(dirto.x * ringdist, dirto.y * ringdist, 0)
            ring:setScale(3, 3, 3)
            ring.mesh:setTexture(self.background.mesh:getTexture())
            love.graphics.setColor(0.7, 0.7, 0.7)
            ring:draw(Planet.shader)
        end

        love.graphics.setColor(1, 1, 1)
        sphere:draw()
        love.graphics.setColor(1, 1, 1)
        love.graphics.print(love.timer.getFPS( ))


        love.graphics.setColor(1, 1, 1)
        shipshader:send("environment", self.background.mesh:getTexture())
        ship.matrix = self.flightController:getFirstPersonViewMatrix():invert() * mat4:fromScale(0.1)
        ship:draw(shipshader)

        local count = 0
        for i, cargo in pairs(self.star.agents) do
            if cargo.laststar == self.star then
                --print(self.star, cargo.container, self.star.neighbours[cargo.heading[2]], self.star.hyperlanes[cargo.heading[2]])
            end
            if not cargo.laststar then return end
            if not cargo.heading[2] then return end

            local fromlane = self.star.hyperlanes[cargo.laststar]

            local dirto = (cargo.laststar.position - self.star.position):normalize()
            local x, y = math.cos(angle), math.sin(angle)
            local ringdist =  math.max(40 + #self.star.planets *20, 100)
            local frompos = Vector2(dirto.x * ringdist, dirto.y * ringdist)

            local dirto = (cargo.heading[2].position - self.star.position):normalize()
            local x, y = math.cos(angle), math.sin(angle)
            local ringdist =  math.max(40 + #self.star.planets *20, 100)
            local topos = Vector2(dirto.x * ringdist, dirto.y * ringdist)

            local lerped = frompos:lerp(topos, cargo.travelt/2000)

            love.graphics.setColor(1, 1, 1)
            shipshader:send("environment", self.background.mesh:getTexture())
            ship:setTranslation(-self.flightController.x, -self.flightController.y, 0)
            ship:setRotation(math.rad(90), 0, 0)
            ship:setScale(1)
            --ship:draw(shipshader)
        end
    --end)
end

function SolarView:wheelmoved()
end

return SolarView
