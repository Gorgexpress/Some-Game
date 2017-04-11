local Vec2 = require 'lib/vec2'
local Vec2l = require 'lib/vector-light'
local mul, normalize = Vec2l.mul, Vec2l.normalize
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

function ProjectileSpawner.fireAtPlayer(self, target, speed)
  if Vec2.is_vec2(self) then
    local vx, vy = mul(speed, normalize(target.x - self.x, target.y - self.y))
end


return ProjectileSpawner