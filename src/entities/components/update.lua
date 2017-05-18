local Vec2l = require 'lib/vector-light'
local abs = math.abs
local rotate = Vec2l.rotate
local Update = {}

function Update.rotatingBullet(time) return
  function(self, dt)
    if not self.timer then
      self.timer = time
    elseif self.timer > 0 then
      self.timer = self.timer - dt
      self.Transform.forward.x, self.Transform.forward.y = rotate(self.rotation_speed * dt, self.Transform.forward:unpack())
      self.Velocity.x, self.Velocity.y = rotate(self.rotation_speed * dt, self.Velocity:unpack())
    end
  end
end


function Update.seek(self, dt)
  if self.homing then
    local position = self.Transform.position
    local desired = math.atan2(self.target.center.y - position.y, self.target.center.x - position.x)
    local current = math.atan2(self.Transform.forward.y, self.Transform.forward.x)
    local diff = desired - current
    if abs(diff) > math.pi then diff = -(diff - math.pi) end
    if self.rotation_speed then
      diff = math.max(-self.rotation_speed * dt, math.min(self.rotation_speed * dt, diff))
    end
    self.Transform.forward = self.Transform.forward:rotate(diff)
  end
  self.Velocity.x , self.Velocity.y = self.Transform.forward.x * self.speed, self.Transform.forward.y * self.speed
end

return Update