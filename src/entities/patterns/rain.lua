local Bullet = require 'src/entities/projectiles/bullet'
local Vec2 = require 'lib/vec2'
local addEntity = require('src/managers/entity').add
local rotate = require('lib/vector-light').rotate

local function bulletUpdate(self, dt)
  if self.timer > 0 then
    self.timer = self.timer - dt
    self.Velocity.x, self.Velocity.y = rotate(self.rotation_speed * dt, self.Velocity:unpack())
  end
end


local function spawnBulletFunction(position, velocity, damage) 
  local body = {
    size = Vec2(6, 18),
    offset = Vec2(0, 0),
    type = 'projectile',
    damage = damage,
  } 
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
    return entity
  end
end

function rain(x, y, dirx, diry, speed, damage, angles)
  spawnBullet = spawnBulletFunction(Vec2(x, y), Vec2(dirx, diry) * speed, damage)
  for k, v in ipairs(angles) do
    addEntity(spawnBullet(v))
    addEntity(spawnBullet(-v))
  end
end

return rain