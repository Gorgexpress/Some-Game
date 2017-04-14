local Vec2 = require 'lib/vec2'
local addEntity = require('src/managers/entity').add
local Bullet = require 'src/entities/projectiles/bullet'
local BigLaser = require 'src/entities/projectiles/big_laser'
local rain = require 'src/entities/patterns/rain'
local spawner = require 'src/projectile-spawner'
local Timer = require 'lib/timer'
local Entity = {}
local Entity_mt = {}

local THINK_TIME = 2.5

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
  if not other.Body then return 'slide'
  elseif other.Body.type == 'projectile' then return nil
  else return 'cross'
  end
end

local function fire1(self)
  local center = self.Transform.position + self.Body.size * 0.5
  local dir = (self.target.center - center):normalize()
  local n = math.random()
  if n > 0.3 then
    rain(center.x, center.y, dir.x, dir.y, 400, 1, {0.0, 0.2, 1, 1.2, 1.4, 1.6})
  else
    rain(center.x, center.y, dir.x, dir.y, 400, 1, {0.0, 0.2, 0.4, 0.6, 1.4, 1.6})
  end
end

function Entity.think(self)
  self.Timer:every(0.35, function() fire1(self) end, 3)
  self.Timer:tween(2.5, self.Transform.position, {x = self.target.center.x}, 'out-cubic')
end


function Entity.onCollision(self, other, type)
  if type == 'p_projectile' then
    self.health = math.max(self.health - (other.Body.damage or 0), 0) 
    if self.health <= 0 then self.destroyed = true end
  end
end

function Entity.draw(self)
  love.graphics.rectangle('fill', self.Transform.position.x, self.Transform.position.y, self.Body.size:unpack())   
end


function Entity.update(self, dt)
  self.Timer:update(dt)
  self.think_timer = self.think_timer - dt
  if self.think_timer <= 0 then
    self:think()
    self.think_timer = THINK_TIME
  end
  if self.health < 35 and not self.laser then
    self.laser = addEntity('projectiles/big_laser', {position = self.Transform.position + self.Body.size})
  end
  if self.laser then
    self.laser.Transform.position.x = (self.Transform.position.x + self.Body.size.x * 0.5) - self.laser.Body.size.x * 0.5
  end
  if self.health < 49 and not self.fastlaser then
    spawner.fire(self.Transform.position, Vec2(0, 500),'fastlaser')
    self.fastlaser = true
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
    think_timer = 1,
    health = 50,
    max_health = 50,
    Timer = Timer.new(),
    target = args.target or g_player
  }
  return setmetatable(entity, Entity_mt)
end

Entity_mt.__index = Entity

function Entity_mt.__call(_, args)
    return Entity.new(args)
end

return setmetatable({}, Entity_mt)