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
  love.graphics.rectangle('fill', self.Transform.position.x, self.Transform.position.y, self.Body.size:unpack())   
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

  local transform = args.transform or {
    position = args.position or Vec2(0, 0),
    forward = Vec2(0, -1),
  }
  local body = {
    size = Vec2(6, 6),
    offset = Vec2(0, 0),
    filter = args.filter or filter,
    type = args.type or 'projectile',
    damage = 1,
    properties = {
      damage = 1
    }
  }

  if args.position then
    transform.position = transform.position - body.size * 0.5
  end

  local entity = {
    Transform = transform,
    Body = body,
    Velocity = args.velocity or Vec2(0, 0),
    target = args.target or g_player
  }

  return setmetatable(entity, Entity_mt)
end

Entity_mt.__index = Entity

function Entity_mt.__call(_, args)
    return Entity.new(args)
end

return setmetatable({}, Entity_mt)