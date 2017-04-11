local Vec2 = require 'lib/vec2'

local Entity = {}
local Entity_mt = {}


function Entity.onCollision(self, other, type)
  if type == 'player' or type == 'tile' then
    self.destroyed = true
  end
end

function Entity.draw(self)
  love.graphics.rectangle('fill', self.Transform.position.x, self.Transform.position.y, self.Body.size:unpack())   
end

local function filter(self, other)
  if other.properties or (other.Body and other.Body.type == 'player') then
    return 'cross'
  end
  return nil 
end

function Entity.update(self, dt)
  
end

function Entity.new(args) 

  local transform = args.transform or {
    position = args.position or Vec2(0, 0),
    forward = Vec2(0, -1),
  }
  local body = args.body or {
    size = Vec2(6, 6),
    offset = Vec2(0, 0),
    filter = args.filter or filter,
    type = args.type or 'projectile',
    damage = 1,
    properties = {
      damage = 1
    }
  }
  if not body.filter then body.filter = filter end
  if args.position then
    transform.position = transform.position - body.size * 0.5
  end

  local entity = {
    Transform = transform,
    Body = body,
    Velocity = args.velocity or Vec2(0, 0),
    update = args.update
  }

  return setmetatable(entity, Entity_mt)
end

Entity_mt.__index = Entity

function Entity_mt.__call(_, args)
    return Entity.new(args)
end

return setmetatable({}, Entity_mt)