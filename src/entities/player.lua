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
local Asset = require 'src/managers/asset'
local image = Asset.getImage('player')
local Utility = require 'lib/utility'
local Signal = require 'lib/signal'
local vecToDir = Utility.vecToDir
local grid = anim8.newGrid(40, 40, image:getWidth(), image:getHeight())
local Entity = require 'src/managers/entity'
local SoundManager = require 'src/managers/sound'
local max, min = math.max, math.min
local intersectsAABB, intersectsPolygon = Utility.AABB, require 'lib/polygon-collision'

local Player = {}
local Player_mt = {}

local SIN45 = 0.70710678118
local STUN_TIME = 0.75
local INVINCIBILITY_TIME = 1.5
local CHARGE_TIME = 0.75
local RATE_OF_FIRE = 0.2
local MP_REGEN_RATE = 50
local MP_COST = 20


local function playerFilter(self, other)
  if other.Body and other.Body.type == 'projectile' then
    return 'cross'
  end
  
  if other.properties or (other.Body and other.Body.type == 'bump') then 
    return 'slide'
  end
  return nil
end

local function die(self)
  self.state = 'dying'
  Timer.after(2, function() self.destroyed = true end)
end

function Player.new(args) 
  local transform = {
    position = args.position or Vec2(0, 0),
    forward = Vec2(0, -1),
  }
  local body = {
    size = Vec2(32, 32),
    offset = Vec2(4, 8),
    filter = playerFilter,
    type = 'player',
    damage = 1,
    properties = {
      damage = 1,
      knockback = 500,
    },
  }
  local animations = {
    idle_u = anim8.newAnimation(grid(2, 3), 1000),
    idle_r = anim8.newAnimation(grid(2, 2), 1000),
    idle_d = anim8.newAnimation(grid(2, 1), 1000),
    idle_l = anim8.newAnimation(grid(2, 4), 1000),
    running_u = anim8.newAnimation(grid('1-3', 3, 2, 3), 0.2),
    running_r = anim8.newAnimation(grid('1-3', 2, 2, 2), 0.2),
    running_d = anim8.newAnimation(grid('1-3', 1, 2, 1), 0.2),
    running_l = anim8.newAnimation(grid('1-3', 4, 2, 4), 0.2),
  }
  local animator = {
    animations = animations,
    current = animations.idle_u
  }
  local entity = {
    Transform = transform,
    Body = body,
    Velocity = Vec2(0, 0),
    animator = animator,
    timer = Timer.new(),
    active = true,
    state = 'idle',
    health = 50,
    max_health = 50,
    center = transform.position + body.offset + body.size * 0.5,
    velocity_dir = transform.forward:clone(),
    sprite = image,
    speed = 0,
    max_speed = 250,
    seconds_to_max_speed = 0.1,
    time_running = 0,
    mp = 100,
    max_mp = 100,
    stunned_timer = 0,
    --inner hitbox
    ih_offsetx = body.offset.x + 4,
    ih_offsety = body.offset.y + 4,
    ih_sizex = 24,
    ih_sizey = 24,
    render = true,
  }
  return setmetatable(entity, Player_mt)
end

function Player.draw(self)
  if self.render then
    self.animator.current:draw(self.sprite, self.Transform.position:unpack())
    local x, y = self.Transform.position.x + self.ih_offsetx, self.Transform.position.y + self.ih_offsety
    --love.graphics.rectangle('fill', x, y, self.ih_sizex, self.ih_sizey)
  end
end

function Player.onCollision(self, other, type)
  if type ~= 'tile' then
    if type == 'bumper' then
      self.time_running = 0
      SoundManager.playSound('bump')
      --self.animator.current = self.animator.animations['idle_' .. vecToDir(self.Transform.forward)]
    elseif type == 'bumped' and state ~= 'knockbacked' and not self.is_invincible then
      --TODO? use tweening instead with some kind of interpolation that makes it seem 
      --like there is friction(entity slows down before stopping, instead of stopping suddenly)
      SoundManager.playSound('hurt')
      self.health = max(self.health - (other.Body.damage or 0), 0) 
      self.Velocity = other.Transform.forward * 250
      self.state = 'stunned'
      self.stunned_timer = STUN_TIME
      self.invincibility_timer = INVINCIBILITY_TIME
      self.is_invincible = true
      self.animator.current = self.animator.animations['idle_' .. vecToDir(self.Transform.forward)]
    elseif type == 'projectile' and not self.is_invincible then
      --TODO put somewhere more appropriate.
      --Player has a separate, smaller hitbox for non bump collisions (projectiles and normal attacks)
      local x, y = self.Transform.position.x + self.ih_offsetx, self.Transform.position.y + self.ih_offsety
      local w, h = self.ih_sizex, self.ih_sizey
      if other.Body.polygon then
         if not intersectsPolygon({x, y, x + w, y, x + w, y + h, x, y + h}, other.Body.polygon) then return end
      else
        local x2, y2 = (other.Transform.position + other.Body.offset):unpack()
        if not intersectsAABB(x, y, w, h, x2, y2, other.Body.size:unpack()) then return end
      end
      if other.onCollision then other:onCollision(self, 'playerih') end
      self.health = max(self.health - (other.Body.damage or 0), 0) 
      self.Velocity = Vec2(0, 0)
      self.state = 'stunned'
      self.stunned_timer = STUN_TIME
      self.is_invincible = true
      self.invincibility_timer = INVINCIBILITY_TIME
    end
  end
  if self.health <= 0 then
    --die
  end
end

function Player.update(self, dt)
  self.center.x = self.Transform.position.x + self.Body.offset.x + self.Body.size.x * 0.5
  self.center.y = self.Transform.position.y + self.Body.offset.y + self.Body.size.y * 0.5
  self.mp = min(self.mp + MP_REGEN_RATE * dt, self.max_mp)
  self.timer:update(dt)
  self.old_x, self.old_y = self.Transform.position.x + self.Body.offset.x, self.Transform.position.y + self.Body.offset.y
  if self.state == 'running' and self.time_running < self.seconds_to_max_speed then
    self.time_running = math.min(self.time_running + dt, self.seconds_to_max_speed)
    self.speed = self.max_speed * (self.time_running / self.seconds_to_max_speed)
    self.Velocity = self.velocity_dir * self.speed
  end
  if self.state == 'idle' or self.state == 'running' then

  end
  if self.state == 'stunned' then
    self.stunned_timer = max(self.stunned_timer - dt, 0)
    if self.stunned_timer == 0 then 
      self.state = 'idle'
      movement() 
    end
  end
  if self.is_invincible then
    self.render = not self.render
    self.invincibility_timer = max(self.invincibility_timer - dt, 0)
    if self.invincibility_timer  == 0 then 
      self.is_invincible = false 
      self.render = true 
    end
  end
end

function Player.move(self, dir_x, dir_y)
  if self.state == 'idle' or self.state == 'running' then
    if dir_x == 0 and dir_y == 0 then 
      self.animator.current = self.animator.animations['idle_' .. vecToDir(self.Transform.forward)]
      self.state = 'idle'
      self.Velocity = Vec2(0, 0)
      self.time_running = 0
    else 
      if dir_x == 0 or dir_y == 0 then
        --self.Velocity = Vec2(self.speed * dir_x, self.speed * dir_y)
        self.velocity_dir = Vec2(dir_x, dir_y)
        self.Transform.forward.x, self.Transform.forward.y = dir_x, dir_y
        if self.time_running == self.seconds_to_max_speed then
          self.Velocity = Vec2(self.speed * dir_x, self.speed * dir_y)
        end
      else
        --self.Velocity = Vec2(self.speed * SIN45 * dir_x, self.speed * SIN45 * dir_y)
        self.velocity_dir = Vec2(SIN45 * dir_x, SIN45 * dir_y)
        if self.time_running == self.seconds_to_max_speed then
          self.Velocity = Vec2(SIN45 * self.speed * dir_x, SIN45 * self.speed * dir_y)
        end
      end
      self.animator.current = self.animator.animations['running_' .. vecToDir(self.Transform.forward)]
      if self.state == 'idle' then 
        self.animator.current:gotoFrame(1)
        self.state = 'running'
      end
    end
    return true
  else --in a state where we cant move, buffer input.
    --if dir_x == 0 and dir_y == 0 then 
      --self.Velocity.frictionless.direction = Vec2(dir_x, dir_y)
   -- else 
      --if dir_x == 0 or dir_y == 0 then
        --self.Velocity.frictionless.direction = Vec2(dir_x, dir_y)
        --self.buffer.direction = Vec2(dir_x, dir_y)
      --else
        --self.Velocity.frictionless.direction = Vec2(SIN45 * dir_x, SIN45 * dir_y)
      --end
    --end
    return false
  end
end

function Player.action1(self)
  if not self.rate_limited and self.mp >= MP_COST then
    Entity.add('projectiles/fireball', {position = self.center:clone(), velocity = self.velocity_dir * 500})
    self.mp = self.mp - MP_COST
  end
  self.charge_handle = Timer.after(CHARGE_TIME, function() self.charged = true end)
  self.rate_limited = true
  Timer.after(RATE_OF_FIRE, function() self.rate_limited = false end)
end

function Player.action2(self)
  if self.charged then
    if self.mp >= MP_COST * 3 then
      local velocity = self.velocity_dir:is_zero() and self.Transform.forward or self.Velocity:normalize()
      Entity.add('projectiles/fireball', {position = self.center:clone(), velocity = self.velocity_dir * 500, damage = 4, radius = 12})
      self.mp = self.mp - MP_COST * 3
    end
    self.charged = false
  end
  if self.charge_handle then Timer.cancel(self.charge_handle) end
end




Player_mt.__index = Player

function Player_mt.__call(_, args)
  return Player.new(args)
end

return setmetatable({}, Player_mt)