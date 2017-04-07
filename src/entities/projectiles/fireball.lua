local Vec2 = require 'lib/vec2'

local Entity = {}
local Entity_mt = {}


function Entity.onCollision(self, other, type)
  if type then
    if type == 'bump' or type == 'tile' then
      self.destroyed = true
    end
  end
end

function Entity.draw(self)
  --TODO refractor all code related to drawing so that the get color is not needed
  local r, g, b, a = love.graphics.getColor()
  love.graphics.setColor(226, 88, 34)
  love.graphics.circle('fill', self.transform.position.x, self.transform.position.y, self.body.size.x / 2)  
  love.graphics.setColor(r, g, b, a) 
end

local function filter(self, other)
  if other.properties or (other.body and other.body.type ~= 'player' and other.body.type ~= 'projectile') then
    return 'cross'
  end
  return nil 
end

function Entity.update(self, dt)
  
end

function Entity.new(args) 
  local entity = {}
  local size = args.size or 12
  local half_size = size / 2
  entity.body = args.body or {
      size = Vec2(size, size),
      offset = Vec2(-half_size, -half_size),
      filter = args.filter or filter,
      type = args.type or 'p_projectile',
      damage = 1,
      properties = {
        damage = 1,
      },
  }
  entity.transform = args.transform or {
      position = args.position or Vec2(0, 0),
      forward = Vec2(0, -1),
  }
  entity.velocity = args.velocity or Vec2(0, 0)
  return setmetatable(entity, Entity_mt)
end

Entity_mt.__index = Entity

function Entity_mt.__call(_, args)
  return Entity.new(args)
end

return setmetatable({}, Entity_mt)