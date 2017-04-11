local Vec2 = require 'lib/vec2'
local addEntity = require('src/managers/entity').add
local Bullet = require 'src/entities/projectiles/bullet'
local rain = require 'src/entities/patterns/rain'
local Entity = {}
local Entity_mt = {}

local THINK_TIME = 1

local function bulletFilter(self, other)
  if other.properties or other == g_player then return 'cross' end
  return nil
end

local small_bullet_body = {
  size = Vec2(6, 12),
  offset = Vec2(0, 0),
  type = 'projectile',
  damage = 1,
  filter = bulletFilter,
}
local big_bullet_body = {
  size = Vec2(12, 24),
  offset = Vec2(0, 0),
  type = 'projectile',
  damage = 1,
  filter = bulletFilter,
}


local function filter(self, other)
  if not other.Body or other.Body.type == 'player' then return 'slide'
  elseif other.Body.type == 'projectile' then return nil
  else return 'cross'
  end
end

local function fire1(self)
  local center = self.Transform.position + self.Body.size * 0.5
  local dir = (self.target.center - center):normalize()
  addEntity(Bullet({position = center:clone(), body = big_bullet_body, velocity = dir * 300}))
  local n = math.random()
  if n > 0.3 then
    rain(center.x, center.y, dir.x, dir.y, 300, 1, {0.2, 0.8, 1, 1.2, 1.4, 1.6})
  else
    rain(center.x, center.y, dir.x, dir.y, 300, 1, {0.2, 0.4, 0.6, 1.2, 1.4, 1.6})
  end
end

function Entity.think(self)
 
end


function Entity.onCollision(self, other, type)
  
end

function Entity.draw(self)
  love.graphics.rectangle('fill', self.Transform.position.x, self.Transform.position.y, self.Body.size:unpack())   
end


function Entity.update(self, dt)
  self.think_timer = self.think_timer - dt
  if self.think_timer <= 0 then
    fire1(self)
    self.think_timer = THINK_TIME
  end
end

function Entity.new(args) 
  local transform = args.transform or {
    position = args.position or Vec2(0, 0),
    forward = Vec2(0, -1),
  }
  local body = args.body or {
    size = Vec2(50, 50),
    offset = Vec2(0, 0),
    filter = filter,
    type = 'boss',
    damage = 1,
  }

  local entity = {
    Transform = transform,
    Body = body,
    Velocity = args.velocity or Vec2(0, 0),
    state = 'idle',
    think_timer = THINK_TIME,
    health = 50,
    max_health = 50,
    target = args.target or g_player
  }
  return setmetatable(entity, Entity_mt)
end

Entity_mt.__index = Entity

function Entity_mt.__call(_, args)
    return Entity.new(args)
end

return setmetatable({}, Entity_mt)