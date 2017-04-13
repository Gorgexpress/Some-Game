local Bullet = require 'src/entities/projectiles/bullet'
local Vec2 = require 'lib/vec2'
local rotate = require('lib/vector-light').rotate
local addEntity = require('src/managers/entity').add
local ProjectileSpawner = require 'src/projectile-spawner'
local fire = ProjectileSpawner.fireAtPlayerFromCenter --(self, speed, type, properties)
local Asset = require 'src/managers/asset'
local image = Asset.getImage('graphics/projectiles/bluelaser')
local quad = love.graphics.newQuad(0, 0, 16, 16, 16, 16)

local function bulletUpdate(self, dt)
  if self.timer > 0 then
    self.timer = self.timer - dt
    self.Velocity.x, self.Velocity.y = rotate(self.rotation_speed * dt, self.Velocity:unpack())
  end
end

local function filter(self, other)
  if other.properties or (other.Body and other.Body.type == 'player') then
    return 'cross'
  end
  return nil 
end



local function spawnBulletFunction(position, velocity, damage) 
  local body = {
    size = Vec2(4, 10),
    offset = Vec2(5, 3),
    type = 'projectile',
    damage = damage,
    filter = filter,
  }  
  position = position - body.offset - body.size * 0.5
  return 
  function(angle)
    local entity = Bullet({
      position = position:clone(),
      velocity = velocity:rotate(angle),
      body = body,
    })
    entity.update = bulletUpdate
    entity.timer = 1
    entity.rotation_speed = -angle
    entity.image = image
    entity.quad = quad
    return entity
  end
end

function rain(x, y, dirx, diry, speed, damage, angles)
  spawnBullet = spawnBulletFunction(Vec2(x, y), Vec2(dirx, diry) * speed, damage)
  for k, v in ipairs(angles) do
    addEntity(spawnBullet(v))
    if v ~= 0 then
      addEntity(spawnBullet(-v))
    end
  end
end

return rain