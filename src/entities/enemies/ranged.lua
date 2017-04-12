local Vec2 = require 'lib/vec2'
local THINK_TIME = 0.25
local fire = require('src/projectile-spawner').fireAtPlayerFromCenter
local Utility = require 'lib/utility'
local round = Utility.round
local floor, abs = math.floor, math.abs
local Entity = {}
local Entity_mt = {}

local DEFAULT_AGGRO_RANGE = 500
local DEFAULT_THINK_TIMER = 0.5
local DEFAULT_ATTACK_TIMER = 2
local DEAGGRO_RANGE2 = 1500 * 1500

local function facePlayer(self, dx, dy) 
  local forward = Vec2(dx, dy):normalize()
  if abs(forward.x) > abs(forward.y) then
    self.Transform.forward = Vec2(round(forward.x), 0)
  else
    self.Transform.forward = Vec2(0, round(forward.y))
  end
end

function Entity.think(self)
  if self.state == 'hurt' or self.state =='melee' then return end
  self.Velocity.x, self.Velocity.y = 0, 0
  local dx, dy =  self.target.center.x - self.Transform.position.x, self.target.center.y - self.Transform.position.y
  local dist2 = dx * dx + dy * dy
  if not self.attacking then
    if dist2 < self.aggro_range2 then
      self.attacking = true
      self.think_timer = self.attack_timer
      --facePlayer(self, dx, dy)
    end
  else
    if dist2 > DEAGGRO_RANGE2 then
      self.attacking = false
    elseif dist2 > self.seal_range2 then
      --fire(self, 200, 'bullet')
      --EntityManager.add('projectiles/laser', {position = position, velocity = velocity, iterations = 1})
      --EntityManager.add('projectiles/curve', {position = position})
      --EntityManager.add('projectiles/rect-laser', {position = position, iterations = 1})
    end
    self.think_timer = self.attack_timer
    --facePlayer(self, dx, dy)
  end
end


function Entity.onCollision(self, other, type)
  if type == 'tile' or type == 'projectile' then return end
  if type == 'p_projectile' then
    self.health = math.max(self.health - other.Body.damage or 0, 0)
  elseif type == 'bumper' or type == 'bumped' then
    if type == 'bumper' then
      self.Velocity = Vec2(0, 0)
      self.think_timer = 0.1
      self.attacking = false
      self.state = 'bump'
      self.Velocity = -self.Transform.forward:normalize() * 250
    elseif type == 'bumped' then 
       if self.invincibility_to_bump_timer > 0 then return end
      self.Velocity = Vec2(0, 0)
      self.invincibility_to_bump_timer = 0.1
      self.think_timer = 0.2
      self.attacking = false
      self.state = 'bump'
      self.health = math.max(self.health - other.Body.damage or 0, 0)
      self.Velocity = other.Transform.forward:normalize() * 500
    end
  end
  if self.health <= 0 then self.destroyed = true end
end

function Entity.draw(self)
  love.graphics.rectangle('fill', self.Transform.position.x, self.Transform.position.y, self.Body.size:unpack())   
end

local function filter(self, other)
  if not other.Body or other.Body.type == 'player' then return 'slide'
  elseif other.Body.type == 'projectile' then return nil
  else return 'cross'
  end
end

function Entity.update(self, dt)
  if self.invincibility_to_bump_timer > 0 then
    self.invincibility_to_bump_timer = self.invincibility_to_bump_timer - dt 
  end
  self.think_timer = self.think_timer - dt
  if self.think_timer <= 0 then
    self:think()
  end
end

function Entity.new(args) 
  local transform =  {
    position = args.position or Vec2(0, 0),
    forward = Vec2(0, -1),
  }
  local body = {
    size = Vec2(32, 32),
    offset = Vec2(0, 0),
    filter = filter,
    type = 'bump',
    damage = 1,
    properties = {
      damage = 1,
    }
  }
  local aggro_range = args.aggro_range or DEFAULT_AGGRO_RANGE
  local seal_range = args.seal_range or 60
  local entity = {
    Transform = transform,
    Body = body,
    Velocity = args.velocity or Vec2(0, 0),
    state = 'idle',
    think_timer = args.think_timer or DEFAULT_THINK_TIMER, 
    think_time = args.think_time or DEFAULT_THINK_TIMER,
    attack_timer = args.attack_timer or DEFAULT_ATTACK_TIMER,
    attacking = false,
    health = 10,
    max_health = 10,
    speed = args.speed or 50,
    target = args.target or g_player,
    aggro_range2 = aggro_range * aggro_range,
    seal_range2 = seal_range * seal_range,
    invincibility_to_bump_timer = 0
  }

  return setmetatable(entity, Entity_mt)
end

Entity_mt.__index = Entity

function Entity_mt.__call(_, args)
    return Entity.new(args)
end

return setmetatable({}, Entity_mt)