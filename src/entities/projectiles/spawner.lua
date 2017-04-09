local Vec2 = require 'lib/vec2'
local Entity = {}
local Entity_mt = {}


function Entity.onCollision(self, other, type)
  
end


function Entity.draw(self)
  love.graphics.circle('fill', self.Transform.position.x, self.Transform.position.y, 6)  
end

local function filter(self, other)
  if other.Body and other.Body.polygon then return nil end
  return 'cross'
end

function Entity.update(self, dt)
  self.timer = self.timer - dt 
  if self.timer <= 0 then
    self.after()
    self.destroyed = true
  end
end

function Entity.new(args) 
  local entity = {}
  local x, y = args.position.x or 0, args.position.y or 0

  entity.Transform = args.transform or {
      position = Vec2(x, y),
      forward = Vec2(0, 0)
  }
  entity.Body = args.body or {
      size = Vec2(1, 1),
      offset = Vec2(-0.5, -0.5),
      filter = args.filter or filter,
      type = args.type or 'projectile',
      damage = 1,
      properties = {
        damage = 1,
      },

  }
  entity.timer = args.time or 1
  entity.after = args.after or function() end
  return setmetatable(entity, Entity_mt)
end

Entity_mt.__index = Entity

function Entity_mt.__call(_, args)
    return Entity.new(args)
end

return setmetatable({}, Entity_mt)