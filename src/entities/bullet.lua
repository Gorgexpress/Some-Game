local Vec2 = require 'lib/vec2'

local Entity = {}
local Entity_mt = {}


function Entity.onCollision(self, other, type)
  self.destroyed = true
  if type then
    if type == 'player' then
    end
  end
end

function Entity.draw(self)
  love.graphics.rectangle('fill', self.transform.position.x, self.transform.position.y, self.body.size:unpack())   
end

local function filter(self, other)
  if other.properties or other == self.target then
    return 'cross'
  end
  return nil 
end

function Entity.update(self, dt)
 
end

function Entity.new(args) 
  local entity = {}
  entity.transform = args.transform or {
      position = args.position or Vec2(0, 0),
      forward = Vec2(0, -1),
  }
  entity.body = args.body or {
      size = Vec2(6, 6),
      offset = Vec2(0, 0),
      filter = filter,
      type = 'projectile',
      damage = 1,
      properties = {
        damage = 1,
      },

  }
  entity.velocity = args.velocity or Vec2(0, 0)
  entity.target = args.target or g_player
  entity.active = true
  return setmetatable(entity, Entity_mt)
end

Entity_mt.__index = Entity

function Entity_mt.__call(_, args)
    return Entity.new(args)
end

return setmetatable({}, Entity_mt)