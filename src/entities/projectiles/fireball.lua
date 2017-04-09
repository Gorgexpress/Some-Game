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
  love.graphics.circle('fill', self.Transform.position.x, self.Transform.position.y, self.radius)  
  love.graphics.setColor(r, g, b, a) 
end

local function filter(self, other)
  if other.properties or (other.Body and other.Body.type ~= 'player' and other.Body.type ~= 'projectile') then
    return 'cross'
  end
  return nil 
end

function Entity.update(self, dt)
  
end

function Entity.new(args) 
  local radius = args.radius or 6
  local diameter = 2 * radius
  local transform = args.transform or {
      position = args.position or Vec2(0, 0),
      forward = Vec2(0, -1),
  }
  local body = {
      size = Vec2(diameter, diameter),
      offset = Vec2(-radius, -radius),
      filter = args.filter or filter,
      type = args.type or 'p_projectile',
      damage = args.damage or 1,
      properties = {
        damage = args.damage or 1,
      },
  }
  local entity = {
    Transform = transform,
    Body = body,
    Velocity = args.velocity or Vec2(0, 0),
    radius = radius
  }
  return setmetatable(entity, Entity_mt)
end

Entity_mt.__index = Entity

function Entity_mt.__call(_, args)
  return Entity.new(args)
end

return setmetatable({}, Entity_mt)