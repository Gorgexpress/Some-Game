local Vec2 = require 'lib/vec2'
local centerEntity = require('lib/utility').centerEntity
local Game = require 'src/game'


local Entity = {}
local Entity_mt = {}


function Entity.onCollision(self, other, type)
  if type then
    if type == 'bump' or type == 'tile' or type == 'boss' then
      self.destroyed = true
    end
    if type == 'bump' or type == 'boss' then
      Game.playSound('fireballhit')
    end
  end
end

function Entity.draw(self)
  love.graphics.draw(self.image, self.quad, self.Transform.position:unpack())
end

local function filter(self, other)
  if other.properties or (other.Body and other.Body.type ~= 'player' and other.Body.type ~= 'projectile') then
    return 'cross'
  end
  return nil 
end

function Entity.update(self, dt)
  
end

function Entity.new(x, y, vx, vy, w, h, ox, oy, damage, image, quad) 
  x, y = centerEntity(x, y, w, h, ox, oy)
  return setmetatable( {
    Transform =  {
      position = Vec2(x, y),
    },
    Body = {
      size = Vec2(w, h),
      offset = Vec2(ox, oy),
      filter = filter,
      type = 'p_projectile',
      damage = damage,
    },
    Velocity = Vec2(vx, vy),
    image = image,
    quad = quad, 
  }, Entity_mt)
end

Entity_mt.__index = Entity

function Entity_mt.__call(_, x, y, vx, vy, w, h, ox, oy, damage, image, quad)
  return Entity.new(x, y, vx, vy, w, h, ox, oy, damage, image, quad)
end

return setmetatable({}, Entity_mt)