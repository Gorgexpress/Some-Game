local Vec2 = require 'lib/vec2'
local Game = require 'src/game'
local addEntity = require('src/managers/entity').add
local Bullet = require 'src/entities/projectiles/bullet'
local BigLaser = require 'src/entities/projectiles/big_laser'
local fire = require('src/projectile-spawner').fire
local rotate = require('lib/vector-light').rotate
local Timer = require 'lib/timer'
local Entity = {}
local Entity_mt = {}

local THINK_TIME = 2.5

local function bulletUpdate(self, dt)
  if self.Properties.timer > 0 then
    self.Properties.timer = self.Properties.timer - dt
    self.Velocity = self.Velocity:rotate(self.Properties.rotation_speed * dt)
  end
end


local function rain(x, y, dirx, diry, speed, angles)
  for k, v in ipairs(angles) do
    local rotated_dirx, rotated_diry = rotate(v, dirx, diry)
    fire('angledbullet', x, y, rotated_dirx * speed, rotated_diry * speed, 10, bulletUpdate, {timer = 1, rotation_speed = -v})
    if v ~= 0 then
      rotated_dirx, rotated_diry = rotate(-v, dirx, diry)
      fire('angledbullet', x, y, rotated_dirx * speed, rotated_diry * speed, 10, bulletUpdate, {timer = 1, rotation_speed = v})
    end
  end
end

local function filter(self, other)
  if not other.Body then return 'slide'
  elseif other.Body.type == 'projectile' then return nil
  else return 'cross'
  end
end

local function fire1(self)
  local center = self.Transform.position + self.Body.size * 0.5
  local dir = (self.target.center - center):normalize()
  local n = love.math.random()
  if n > 0.3 or self.health >= 115 then
    rain(center.x, center.y, dir.x, dir.y, 400, {0.0, 0.1, 0.2, 1, 1.1, 1.2, 1.3, 1.4, 1.5, 1.6})
  else
    rain(center.x, center.y, dir.x, dir.y, 400, {0.0,0.1, 0.2, 0.3, 0.4,0.5, 0.6, 1.4, 1.5, 1.6})
  end
end

local function fire2(self)
  local center = self.Transform.position + self.Body.size * 0.5
  for i=1,8 do
    local angle = self.rotoffset + math.rad(i * 45)
    local forward = Vec2.from_cartesian(1, angle)
    fire('basic', center.x, center.y, forward.x * self.shotspeed, forward.y * self.shotspeed)
  end
end

local function fire3(self)
  local center = self.Transform.position + self.Body.size * 0.5
  local dir = (self.target.center - center):normalize()
  fire('basiclaser', center.x, center.y, dir.x * 700, dir.y * 700)
end


function Entity.think(self)
  if self.health > 60 then
    self.Timer:every(0.35, function() fire1(self) end, self.count)
  else
    fire2(self)
  end
end


function Entity.onCollision(self, other, type)
  if type == 'p_projectile' then
    self.health = math.max(self.health - (other.Body.damage or 0), 0) 
    if self.health <= 0 then self.destroyed = true end
    if self.health <= 80 and self.count == 3 then 
      self.count = self.count * 2 
      self.think_time = self.think_time + 0.75
    end
    if not self.flag1 and self.health <= 60 then
      self.flag1 = true
      self.think_time = 0.3
      self.think_timer = self.think_timer + 1.5
      self.laser_timer1 = self.think_timer
      self.laser_timer2 = self.think_timer + 0.5
    elseif not self.flag2 and self.health <= 40 then
      self.flag2 = true
      self.think_time = 0.225
      self.rotspeed = self.rotspeed + 0.3
      self.shotspeed = self.shotspeed + 150
    elseif not self.flag3 and self.health <= 20 then
      self.flag3 = true
      self.think_time = 0.15
      self.rotspeed = self.rotspeed + 0.3
      self.shotspeed = self.shotspeed + 150
    --[[elseif not self.flag4 and self.health <= 15 then
      self.flag4 = true
      self.think_time = 0.1
      self.rotspeed = self.rotspeed + 0.2
      self.shotspeed = self.shotspeed + 100]]
    end
  end
end

function Entity.draw(self)
  love.graphics.rectangle('fill', self.Transform.position.x, self.Transform.position.y, self.Body.size:unpack())   
end


function Entity.update(self, dt)
  self.Timer:update(dt)
  self.rotoffset = self.rotoffset + self.rotspeed * dt
  if self.rotoffset > 2 * math.pi then self.rotoffset = 0 end
  self.think_timer = self.think_timer - dt
  if self.think_timer <= 0 then
    self:think()
    self.think_timer = self.think_time
  end
  --if self.health < 49 and not self.laser then
    --self.laser = addEntity('projectiles/big_laser', {position = self.Transform.position + self.Body.size})
  --end
  if self.target.center.x > self.Transform.position.x + self.Body.size.x * 0.5 then
    if self.Velocity.x > 0 then
      self.Velocity.x = self.Velocity.x + self.acceleration * dt
    else
      self.Velocity.x = self.Velocity.x + self.acceleration * dt * 10
    end
  else
    if self.Velocity.x > 0 then
      self.Velocity.x = self.Velocity.x - self.acceleration * dt * 10
    else
      self.Velocity.x = self.Velocity.x - self.acceleration * dt
    end
  end
  if self.flag1 then
    self.laser_timer1 = self.laser_timer1 - dt
    self.laser_timer2 = self.laser_timer2 - dt
    if self.laser_timer1 <= 0 then 
      fire3(self)
      self.laser_timer1 = 5 
    end
    if self.laser_timer2 <= 0 then 
      fire3(self)
      self.laser_timer2 = 5 
    end
  end
end

function Entity.new(x, y) 
  local transform = {
    position = Vec2(x, y),
    forward = Vec2(0, -1),
  }
  local body = {
    size = Vec2(50, 50),
    offset = Vec2(0, 0),
    filter = filter,
    type = 'boss',
    damage = 1,
  }

  local entity = {
    Transform = transform,
    Body = body,
    Velocity = Vec2(0, 0),
    state = 'idle',
    think_timer = 1,
    health = 125,
    max_health = 125,
    Timer = Timer.new(),
    target = Game.player,
    think_time = THINK_TIME,
    acceleration = 50,
    count = 3,
    rotspeed = 0.4,
    frequency = 0.4,
    rotoffset = 0,
    shotspeed = 250,
    flag1 = false,
    flag2 = false,
    flag3 = false,
  }
  return setmetatable(entity, Entity_mt)
end

Entity_mt.__index = Entity

function Entity_mt.__call(_, ...)
    return Entity.new(...)
end


return setmetatable({}, Entity_mt)
