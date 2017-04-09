local Bullet = require 'src/entities/projectiles/bullet'
local Vec2 = require 'lib/vec2'

local Entity = {}
local Entity_mt = {}



function Entity.update(self, dt)
  if self.timer > 0 then
    self.timer = self.timer - dt
    self.Velocity.x, self.Velocity.y = rotate(self.rotation_speed * dt, self.Velocity:unpack())
  end
end

function Entity.new(x, y, vx, vy, body, angle) 
  local entity = Bullet({
    position = Vec2(x, y),
    velocity = Vec2(vx, vy),
    size = Vec2(w, h),
    update = Entity.update,
  })
  entity.timer = 1
  entity.angle = angle
  return entity
end

Entity_mt.__index = Entity

function Entity_mt.__call(_, args)
    return Entity.new(args)
end

return setmetatable({}, Entity_mt)