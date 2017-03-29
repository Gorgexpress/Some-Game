--[[
  Code isn't as pretty as I'd like but it works.

  Finding a way to handle player speed and acceleration in a way that feels good
  was a bit tough. 
  
  I tried no acceleration at first, but it makes making small movements tough.
  One way to handle that would be a walk button, which would work perfectly in something like a shmup.
  I can see that method being annoying when dealing with the bump system though. Don't want to have to
  hold the walk button everytime you want to make small movements to align your hitbox the right way.
  Maybe I'll give no acceleration another chance later in development though.

  Linear interpolation felt nice but definitely doesn't fit the needs of the game. A simple
  acceleration implementation with a capped speed was floaty.

  I settled on just keeping track of the time spent in the running state, and scaling speed
  based off the current time elapsed while running and the time it takes to reach max speed.
  This way, the player is only accelerating when they have just begun to move from the idle state.

]]


local Vec2 = require 'lib/vec2'
local anim8 = require 'lib/anim8'
local Timer = require 'lib/timer'
local Asset = require 'src/managers/asset-manager'
local image = Asset.getImage('player')
local Utility = require 'lib/utility'
local Signal = require 'lib/signal'
local vecToDir = Utility.vecToDir
local grid = anim8.newGrid(40, 40, image:getWidth(), image:getHeight())
local SIN45 = 0.70710678118
local Entity = require 'src/managers/entity-manager'
local SoundManager = require 'src/managers/sound-manager'
local max, min = math.max, math.min
local STAMINA_REGEN = 50
local Player = {}
local Player_mt = {}

local function playerFilter(self, other)
  return 'slide'
end

function Player.new(args) 
  local entity = {}
  entity.transform = {
    position = args.position or Vec2(0, 0),
    forward = Vec2(0, -1),
  }
  entity.body = {
    size = Vec2(32, 32),
    offset = Vec2(4, 8),
    filter = playerFilter,
    type = 'player',
    properties = {
      damage = 1,
      knockback = 500,
    },
  }
  entity.center = entity.transform.position + entity.body.offset + entity.body.size * 0.5
  entity.velocity = Vec2(0, 0)
  entity.velocity_dir = Vec2(0, 0)
  entity.animator = {
    animations = {
    idle_u = anim8.newAnimation(grid(2, 3), 1000),
    idle_r = anim8.newAnimation(grid(2, 2), 1000),
    idle_d = anim8.newAnimation(grid(2, 1), 1000),
    idle_l = anim8.newAnimation(grid(2, 4), 1000),
    running_u = anim8.newAnimation(grid('1-3', 3, 2, 3), 0.2),
    running_r = anim8.newAnimation(grid('1-3', 2, 2, 2), 0.2),
    running_d = anim8.newAnimation(grid('1-3', 1, 2, 1), 0.2),
    running_l = anim8.newAnimation(grid('1-3', 4, 2, 4), 0.2),
    },
  }
  entity.animator.current = entity.animator.animations.idle_u

  entity.active = true
  entity.state = 'idle'
  entity.buffer = {}
  entity.health, entity.max_health = 50, 50
  entity.stamina = {
    current = 100,
    max = 100,
    exhausted = false
  }
  entity.sprite = image
  entity.timer = Timer.new()
  entity.speed = 0
  entity.max_speed = 250
  entity.seconds_to_max_speed = 0.1
  entity.time_running = 0
  --Unused right now. Will be used if I decide to factor in trajectory of the player in collisions.
  entity.old_x = 0
  entity.old_y = 0
  return setmetatable(entity, Player_mt)
end

function Player.draw(self)
  self.animator.current:draw(self.sprite, self.transform.position:unpack())
end

function Player.onCollision(self, other, type)
  if type ~= 'tile' then
    if type == 'bumper' then
      self.time_running = 0
      SoundManager.playSound('bump')
      --self.animator.current = self.animator.animations['idle_' .. vecToDir(self.transform.forward)]
    elseif type == 'bumped' and state ~= 'knockbacked' then
      SoundManager.playSound('hurt')
      self.state = 'knockbacked'
      local info = other.body.properties
      self.velocity = other.transform.forward:normalize() * 250
      self.health = self.health - info.damage
      --TODO? use tweening instead with some kind of interpolation that makes it seem 
      --like there is friction(entity slows down before stopping, instead of stopping suddenly)
      self.timer:after(0.2, function() 
        if self.state == 'knockbacked' then
          self.state = 'idle' 
          movement() 
        end
      end)
      self.animator.current = self.animator.animations['idle_' .. vecToDir(self.transform.forward)]
    elseif type == 'projectile' then
      if other.body.damage then 
        self.health = max(self.health - other.body.properties.damage, 0) 
      end
    end
  end
  if self.health <= 0 then

  end
end

function Player.update(self, dt)
  self.center.x = self.transform.position.x + self.body.offset.x + self.body.size.x * 0.5
  self.center.y = self.transform.position.y + self.body.offset.y + self.body.size.y * 0.5
  self.timer:update(dt)
  self.old_x, self.old_y = self.transform.position.x + self.body.offset.x, self.transform.position.y + self.body.offset.y
  if self.state == 'running' and self.time_running < self.seconds_to_max_speed then
    self.time_running = math.min(self.time_running + dt, self.seconds_to_max_speed)
    self.speed = self.max_speed * (self.time_running / self.seconds_to_max_speed)
    self.velocity = self.velocity_dir * self.speed
  end
  if self.state == 'idle' or self.state == 'running' then
    self.stamina.current = math.min(self.stamina.current + STAMINA_REGEN* dt, self.stamina.max)
  end
end

function Player.move(self, dir_x, dir_y)
  if self.state == 'idle' or self.state == 'running' then
    if dir_x == 0 and dir_y == 0 then 
      self.animator.current = self.animator.animations['idle_' .. vecToDir(self.transform.forward)]
      self.state = 'idle'
      self.velocity = Vec2(0, 0)
      self.time_running = 0
    else 
      if dir_x == 0 or dir_y == 0 then
        --self.velocity = Vec2(self.speed * dir_x, self.speed * dir_y)
        self.velocity_dir = Vec2(dir_x, dir_y)
        self.transform.forward.x, self.transform.forward.y = dir_x, dir_y
        if self.time_running == self.seconds_to_max_speed then
          self.velocity = Vec2(self.speed * dir_x, self.speed * dir_y)
        end
      else
        --self.velocity = Vec2(self.speed * SIN45 * dir_x, self.speed * SIN45 * dir_y)
        self.velocity_dir = Vec2(SIN45 * dir_x, SIN45 * dir_y)
        if self.time_running == self.seconds_to_max_speed then
          self.velocity = Vec2(SIN45 * self.speed * dir_x, SIN45 * self.speed * dir_y)
        end
      end
      self.animator.current = self.animator.animations['running_' .. vecToDir(self.transform.forward)]
      if self.state == 'idle' then 
        self.animator.current:gotoFrame(1)
        self.state = 'running'
      end
    end
    return true
  else --in a state where we cant move, buffer input.
    --if dir_x == 0 and dir_y == 0 then 
      --self.velocity.frictionless.direction = Vec2(dir_x, dir_y)
   -- else 
      --if dir_x == 0 or dir_y == 0 then
        --self.velocity.frictionless.direction = Vec2(dir_x, dir_y)
        --self.buffer.direction = Vec2(dir_x, dir_y)
      --else
        --self.velocity.frictionless.direction = Vec2(SIN45 * dir_x, SIN45 * dir_y)
      --end
    --end
    return false
  end
end




Player_mt.__index = Player

function Player_mt.__call(_, args)
    return Player.new(args)
end

return setmetatable({}, Player_mt)