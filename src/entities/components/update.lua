local Vec2l = require 'lib/vector-light'
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

return Update