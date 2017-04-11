local Vec2 = require 'lib/vec2'
local Vec2l = require 'lib/vector-light'
local add, sub, mul, normalize = Vec2l.add, Vec2l.sub, Vec2l.mul, Vec2l.normalize
local EntityManager = require 'src/managers/entity'

local ProjectileSpawner = {}

local _player = g_player

function ProjectileSpawner.fireAtPosition(self, target, type)
  local position = self.transform.position + self.body.offset + self.body.size * 0.5
  if not target.transform then
    local velocity = (target - position):normalize() * 50
    EntityManager.add('bullet', {position = position, velocity = velocity})
  end

end

function ProjectileSpawner.fireAtPlayer(self, speed, arg3, arg4, arg5)
  if Vec2.is_vec2(self) then
    local vx, vy = mul(speed, normalize(_player.x - self.x, _player.y - self.y))
  elseif type(self) == 'number' then
    local vx, vy = mul(arg5, normalize(arg3 - self, arg4 - speed))
  else
    --entities
  end
end

function ProjectileSpawner.fireAtPlayerFromCenter(self, target, speed, arg4, arg5, arg6)
  local x1, y1 = self.Transform.position:unpack()
  local ox, oy = self.Body.offset:unpack()
  local sx, sy = self.Body.size:unpack()
  local x2, y2 = _player.center:unpack()
  local x, y = x2 - (x1 + ox + sx * 0.5), y2 - (y1 + oy + sy * 0.5)
  local len = math.sqrt(x * x + y * y)
  local vx, vy = (x / len) * speed, (y / len) * speed 

end


return ProjectileSpawner