local Bomb = require 'src/entities/other/bomb'
local Bump = require 'src/entities/enemies/bump'
local addEntity = require('src/managers/entity').add

local Entity = {}
local Entity_mt = {}

function Entity.draw(self)
  Bump.draw(self)
end

function Entity.onCollision(self, other, type)
  Bump.onCollision(self, other, type)
  if (type == 'p_projectile' or type == 'bumped') and self.is_bomb_ready  then
    local x, y = (self.Transform.position + self.Body.offset + self.Body.size * 0.5):unpack()
    addEntity(Bomb.new(x, y, 7, 1.5, self.types))
    self.is_bomb_ready = false
    self.t_bomb = self.t_between_bombs
  end
end

function Entity.update(self, dt)
  Bump.update(self, dt)
  if not self.is_bomb_ready then
    self.t_bomb = self.t_bomb - dt
    if self.t_bomb <= 0 then self.is_bomb_ready = true end
  end
end

function Entity.new(x, y, properties)
  local entity = Bump.new(x, y)
  entity.t_bomb = 0
  entity.t_between_bombs = 3
  entity.is_bomb_ready = true
  entity.types = {'x', '+'}
  return setmetatable(entity, Entity_mt)
end

Entity_mt = {
  __index = Entity,
  __call = function(_, ...) return Entity.new(...) end
}

return setmetatable({}, Entity_mt)