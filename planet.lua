local Object = require "object"
local g3d = require "g3d"

local sphere = g3d.newModel("assets/planet.obj", nil, {0, 0, 0}, nil, {1,1,1})

local Planet = Object:extend()

Planet.shader = love.graphics.newShader(g3d.shaderpath, [[
    varying vec4 VertexPos;
    varying vec4 vertexNormal;
    uniform float sunRadius;

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

        vec4 texcolor = Texel(tex, vec2(0., dot(reference, abs(clippedNormal.xyz))));
        texcolor += Texel(tex, vec2(0., dot(reference, abs(offset1 * clippedNormal).xyz)));
        texcolor += Texel(tex, vec2(0., dot(reference, abs(offset2 * clippedNormal).xyz)));

        vec3 sunDir = -normalize(vec3(0., 0., 0.) - VertexPos.xyz);
        vec3 sunClosest = sunDir * sunRadius;
        vec3 lightDir = normalize(sunClosest - VertexPos.xyz);
        vec3 diffuse = max(dot(normalize(vertexNormal.xyz), lightDir), 0.0) * vec3(1., 1., 1.);

        // get rid of transparent pixels
        if (texcolor.a == 0.0) {
            discard;
        }
        
        return vec4((diffuse + texcolor.xyz/3) * color.xyz, 1.);
    }
]])

function Planet:__new(index)
    self.orbit = 5 + index*20
    self.speed = math.max(0.2, 0.5 + math.random() * 0.5)/1000

    local rand = math.random() - 0.5 
    self.direction = rand * math.abs(1/rand)
    self.size = 20 + math.random() * 50
    self.color = {math.random()*0.7, math.random()*0.7, math.random()*0.7}
end

function Planet:draw(time, bgtex)
    love.graphics.setColor(unpack(self.color))
    Planet.shader:send("sunRadius", 10)
    sphere.mesh:setTexture(bgtex)
    sphere:setScale(self.size, self.size, self.size)
    sphere:setRotation(math.rad(90), 0, 0)
    sphere:setTranslation(math.cos(self.direction*time*2*math.pi*self.speed)*self.orbit, math.sin(self.direction*time*2*math.pi*self.speed)*self.orbit, 0)
    sphere:draw(self.shader)
end

return Planet