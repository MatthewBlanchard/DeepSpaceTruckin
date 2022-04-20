local Object = require "object"
local Vector2 = require "vector"
local g3d = require "g3d"
local newMatrix = require(g3d.path .. "/matrices")


local AsteroidField = Object:extend()

local asteroidShader = love.graphics.newShader([[
    uniform mat4 projectionMatrix; // handled by the camera
    uniform mat4 viewMatrix;       // handled by the camera
    uniform mat4 modelMatrix;      // models send their own model matrices when drawn
    uniform bool isCanvasEnabled;  // detect when this model is being rendered to a canvas
    
    // the vertex normal attribute must be defined, as it is custom unlike the other attributes
    attribute vec3 VertexNormal;
    
    // define some varying vectors that are useful for writing custom fragment shaders
    varying vec4 worldPosition;
    varying vec4 VertexPos;
    varying vec4 viewPosition;
    varying vec4 screenPosition;
    varying vec3 vertexNormal;
    varying vec4 vertexColor;
    attribute vec4 InstanceMat1;
    attribute vec4 InstanceMat2;
    attribute vec4 InstanceMat3;
    attribute vec4 InstanceMat4;
    
    mat4 inverse(mat4 m) {
      float
          a00 = m[0][0], a01 = m[0][1], a02 = m[0][2], a03 = m[0][3],
          a10 = m[1][0], a11 = m[1][1], a12 = m[1][2], a13 = m[1][3],
          a20 = m[2][0], a21 = m[2][1], a22 = m[2][2], a23 = m[2][3],
          a30 = m[3][0], a31 = m[3][1], a32 = m[3][2], a33 = m[3][3],
    
          b00 = a00 * a11 - a01 * a10,
          b01 = a00 * a12 - a02 * a10,
          b02 = a00 * a13 - a03 * a10,
          b03 = a01 * a12 - a02 * a11,
          b04 = a01 * a13 - a03 * a11,
          b05 = a02 * a13 - a03 * a12,
          b06 = a20 * a31 - a21 * a30,
          b07 = a20 * a32 - a22 * a30,
          b08 = a20 * a33 - a23 * a30,
          b09 = a21 * a32 - a22 * a31,
          b10 = a21 * a33 - a23 * a31,
          b11 = a22 * a33 - a23 * a32,
    
          det = b00 * b11 - b01 * b10 + b02 * b09 + b03 * b08 - b04 * b07 + b05 * b06;
    
      return mat4(
          a11 * b11 - a12 * b10 + a13 * b09,
          a02 * b10 - a01 * b11 - a03 * b09,
          a31 * b05 - a32 * b04 + a33 * b03,
          a22 * b04 - a21 * b05 - a23 * b03,
          a12 * b08 - a10 * b11 - a13 * b07,
          a00 * b11 - a02 * b08 + a03 * b07,
          a32 * b02 - a30 * b05 - a33 * b01,
          a20 * b05 - a22 * b02 + a23 * b01,
          a10 * b10 - a11 * b08 + a13 * b06,
          a01 * b08 - a00 * b10 - a03 * b06,
          a30 * b04 - a31 * b02 + a33 * b00,
          a21 * b02 - a20 * b04 - a23 * b00,
          a11 * b07 - a10 * b09 - a12 * b06,
          a00 * b09 - a01 * b07 + a02 * b06,
          a31 * b01 - a30 * b03 - a32 * b00,
          a20 * b03 - a21 * b01 + a22 * b00) / det;
    }
    
    vec4 position(mat4 transformProjection, vec4 vertexPosition) {
        // calculate the positions of the transformed coordinates on the screen
        // save each step of the process, as these are often useful when writing custom fragment shaders
        mat4 InstanceMatrix = transpose(mat4(InstanceMat1, InstanceMat2, InstanceMat3, InstanceMat4));

        worldPosition =  modelMatrix * InstanceMatrix * vertexPosition;
        viewPosition = viewMatrix * worldPosition;
        screenPosition = projectionMatrix * viewPosition;
        
        mat4 tiM = transpose( inverse( modelMatrix * InstanceMatrix ) );
        // save some data from this vertex for use in fragment shaders
        vertexNormal = normalize(( tiM * vec4(VertexNormal, 1)).xyz);
        vertexColor = VertexColor;
        VertexPos = worldPosition;
    
        // for some reason models are flipped vertically when rendering to a canvas
        // so we need to detect when this is being rendered to a canvas, and flip it back
        if (isCanvasEnabled) {
            screenPosition.y *= -1.0;
        }
    
        return screenPosition;
    }
]], [[
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


function AsteroidField:__new(index)
    self.orbit = index*20
    self.speed = math.max(0.2, 0.5 + math.random() * 0.5)/1000

    local rand = math.random() - 0.5 
    self.direction = rand * math.abs(1/rand)
    self.color = {math.random()*0.7, math.random()*0.7, math.random()*0.7}

    self.asteroid = g3d.newModel("assets/asteroid.obj")
    self.asteroid:setScale(3, 3, 3)
    local instance_positions = {}
    for i = 1, 1000 do
        local randomAngle = math.random()*2*math.pi
        local randomScale = 2 + math.random() * 16
        local offset = (10 * (math.random() - 0.5))
        local vec = Vector2(math.random() - 0.5 + 0.0001, math.random() - 0.5 + 0.0001):normalize() * (self.orbit + offset)

        local instanceMat = newMatrix()
        instanceMat:setTransformationMatrix({vec.x, vec.y, (math.random() - 0.5) * 2}, {randomAngle, randomAngle, randomAngle}, {randomScale, randomScale, randomScale})
        table.insert(instance_positions, instanceMat)
    end

    local instancemesh = love.graphics.newMesh({
        {"InstanceMat1", "float", 4}, {"InstanceMat2", "float", 4},
        {"InstanceMat3", "float", 4}, {"InstanceMat4", "float", 4}
    }, instance_positions, nil, "static")

    self.asteroid.mesh:attachAttribute("InstanceMat1", instancemesh, "perinstance")
    self.asteroid.mesh:attachAttribute("InstanceMat2", instancemesh, "perinstance")
    self.asteroid.mesh:attachAttribute("InstanceMat3", instancemesh, "perinstance")
    self.asteroid.mesh:attachAttribute("InstanceMat4", instancemesh, "perinstance")

end

function AsteroidField:draw(time, bgtex)
    love.graphics.setColor(unpack(self.color))
    asteroidShader:send("sunRadius", 3)

    love.graphics.setShader(asteroidShader)
    
    local current_rotation = newMatrix()
    current_rotation:setTransformationMatrix({0, 0, 0}, {0, 0, time * 2 * math.pi * self.speed}, {1, 1, 1})
    asteroidShader:send("modelMatrix",current_rotation)
    asteroidShader:send("viewMatrix", g3d.camera.viewMatrix)
    asteroidShader:send("projectionMatrix", g3d.camera.projectionMatrix)
    if asteroidShader:hasUniform "isCanvasEnabled" then
        asteroidShader:send("isCanvasEnabled", love.graphics.getCanvas() ~= nil)
    end
    self.asteroid.mesh:setTexture(bgtex)
    love.graphics.drawInstanced(self.asteroid.mesh, 1300, 0, 0)
    love.graphics.setShader()
end

return AsteroidField