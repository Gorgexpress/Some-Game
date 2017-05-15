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
local image = Asset.getImage('player2')
local Utility = require 'lib/utility'
local Signal = require 'lib/signal'
local vecToDir = Utility.vecToDir
local grid = anim8.newGrid(32, 32, image:getWidth(), image:getHeight(), 0, 0, 2)
local Entity = require 'src/managers/entity'
local addEntity = Entity.add
local Fireball = require 'src/entities/projectiles/fireball'
local InwardsFX = require 'src/entities/gfx/inwards'
local SoundManager = require 'src/managers/sound'
local Game = require 'src/game'
local max, min = math.max, math.min
local intersectsAABB, intersectsPolygon = Utility.AABB, require 'lib/polygon-collision'

local Player = {}
local Player_mt = {}

local SIN45 = 0.70710678118
local STUN_TIME = 0.75
local INVINCIBILITY_TIME = 1.5
local CHARGE_TIME = 0.75
local RATE_OF_FIRE = 0.1
local MP_REGEN_RATE = 50
local MP_COST = 20

--TODO? move all this stuff in a separate file
local _sfimage = Asset.getImage('smallfire')
local _sfquad = love.graphics.newQuad(32, 0, 16, 16, _sfimage:getDimensions())
local _bfimage = Asset.getImage('bigfire')
local _bfquad = love.graphics.newQuad(64, 0, 32, 32, _bfimage:getDimensions())
local _particlequad = love.graphics.newQuad(48, 16, 16, 16, _sfimage:getDimensions())
local _shader = love.graphics.newShader[[
    extern number iGlobalTime;
    vec4 effect( vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords ){
      vec4 pixel = Texel(texture, texture_coords );//This is the current pixel color
      return pixel * (1.0 + (cos(iGlobalTime * 3.0) + 1.0));
    }
  ]]
local function playerFilter(self, other)
  if other.Body and other.Body.type == 'projectile' then
    return 'cross'
  end
  
  if other.properties or (other.Body and (other.Body.type == 'bump' or other.Body.type == 'tile')) then 
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
    size = Vec2(14, 22),
    offset = Vec2(8, 8),
    filter = playerFilter,
    type = 'player',
    damage = 10,
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
    ih_offsetx = 12,
    ih_offsety = 18,
    ih_sizex = 4,
    ih_sizey = 4,
    render = true,
  }
  entity.ps = addEntity(InwardsFX.new(entity, entity.center.x - transform.position.x, entity.center.y - transform.position.y, _sfimage, _particlequad))
  entity.ps.ps:stop()
  entity.ps.ps:setEmitterLifetime(-1)
  return setmetatable(entity, Player_mt)
end

function Player.draw(self)
  if self.render then
    if self.charged then
      love.graphics.setShader(_shader)
      _shader:send('iGlobalTime', self.time_since_charged)
      self.animator.current:draw(self.sprite, self.Transform.position:unpack())
      love.graphics.setShader()
    else
      self.animator.current:draw(self.sprite, self.Transform.position:unpack())
    end
    --local x, y = self.Transform.position.x + self.ih_offsetx, self.Transform.position.y + self.ih_offsety
    --love.graphics.rectangle('fill', x, y, self.ih_sizex, self.ih_sizey)
  end
end

function Player.onCollision(self, other, type)
  if type ~= 'tile' then
    if type == 'bumper' then
      self.time_running = 0
      --self.animator.current = self.animator.animations['idle_' .. vecToDir(self.Transform.forward)]
    elseif type == 'bumped' and state ~= 'knockbacked' and not self.is_invincible then
      --TODO? use tweening instead with some kind of interpolation that makes it seem 
      --like there is friction(entity slows down before stopping, instead of stopping suddenly)
      SoundManager.playSound('playerhurt')
      self.health = max(self.health - (other.Body.damage or 0), 0) 
      self.Velocity = other.Transform.forward * 250
      self.state = 'stunned'
      self.stunned_timer = STUN_TIME
      self.invincibility_timer = INVINCIBILITY_TIME
      self.is_invincible = true
      self.animator.current = self.animator.animations['idle_' .. vecToDir(self.Transform.forward)]
    elseif type == 'projectile' and not self.is_invincible then
      --Player has a separate, smaller hitbox for non bump collisions (projectiles and normal attacks)
      --disabled for now since i made the regular hitbox smaller
      --[[-TODO? put somewhere more appropriate. This works for now, but if I make a system that 
      aligns certain children entities with a a parent entity, I could make the inner hitbox
      a separate entity, which will make this either less confusing or more confusing]]
      --[[
      local x, y = self.Transform.position.x + self.ih_offsetx, self.Transform.position.y + self.ih_offsety
      local w, h = self.ih_sizex, self.ih_sizey
      if other.Body.polygon then
         if not intersectsPolygon({x, y, x + w, y, x + w, y + h, x, y + h}, other.Body.polygon) then return end
      else
        local x2, y2 = (other.Transform.position + other.Body.offset):unpack()
        if not intersectsAABB(x, y, w, h, x2, y2, other.Body.size:unpack()) then return end
      end]]
      if other.onCollision then other:onCollision(self, 'playerih') end
      self.health = max(self.health - (other.Body.damage or 0), 0) 
      self.Velocity = Vec2(0, 0)
      self.state = 'stunned'
      self.stunned_timer = STUN_TIME
      self.is_invincible = true
      self.invincibility_timer = INVINCIBILITY_TIME
      SoundManager.playSound('playerhurt')
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
  if self.charged then self.time_since_charged = self.time_since_charged + dt end
  --self.old_x, self.old_y = self.Transform.position.x + self.Body.offset.x, self.Transform.position.y + self.Body.offset.y
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
      self:move() 
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

function Player.move(self)
  local uvx, uvy = 0, 0

  if Game.input_state['up'] then uvy = uvy -1 end
  if Game.input_state['right'] then uvx = uvx + 1 end 
  if Game.input_state['down'] then uvy = uvy + 1 end
  if Game.input_state['left'] then uvx = uvx - 1 end
  if self.state == 'idle' or self.state == 'running' then
    if uvx == 0 and uvy == 0 then 
      self.animator.current = self.animator.animations['idle_' .. vecToDir(self.Transform.forward)]
      self.state = 'idle'
      self.Velocity = Vec2(0, 0)
      self.time_running = 0
    else 
      if uvx == 0 or uvy == 0 then
        self.velocity_dir = Vec2(uvx, uvy)
        self.Transform.forward.x, self.Transform.forward.y = uvx, uvy
        if self.time_running == self.seconds_to_max_speed then
          self.Velocity = Vec2(self.speed * uvx, self.speed * uvy)
        end
      else
        self.velocity_dir = Vec2(SIN45 * uvx, SIN45 * uvy)
        if self.time_running == self.seconds_to_max_speed then
          self.Velocity = Vec2(SIN45 * self.speed * uvx, SIN45 * self.speed * uvy)
        end
      end
      self.animator.current = self.animator.animations['running_' .. vecToDir(self.Transform.forward)]
      if self.state == 'idle' then 
        self.animator.current:gotoFrame(1)
        self.state = 'running'
      end
    end
  end
end


function Player.action1(self)
  if self.rate_limited then 
    self.charge_handle = Timer.after(CHARGE_TIME, function() self.charged = true end)
    return 
  end
  if self.mp >= MP_COST and not self.rate_limited then
    addEntity(Fireball(self.center.x, self.center.y, self.velocity_dir.x * 500, self.velocity_dir.y * 500, 16, 16, 0, 0, 1, _sfimage, _sfquad))
    self.mp = self.mp - MP_COST
  end
  self.charge_handle = Timer.after(CHARGE_TIME, function() 
    self.charged = true
    self.time_since_charged = 0 
  end)
  self.ps_handle = Timer.after(0.2, function() self.ps:start() end)
  self.rate_limited = true
  Timer.after(RATE_OF_FIRE, function() self.rate_limited = false end)
end


function Player.action2(self)
  if self.charged then
    if self.mp >= MP_COST * 2 then
      local velocity = self.velocity_dir:is_zero() and self.Transform.forward or self.Velocity:normalize()
      addEntity(Fireball(self.center.x, self.center.y, self.velocity_dir.x * 500, self.velocity_dir.y * 500, 32, 32, 0, 0, 3, _bfimage, _bfquad))
      self.mp = self.mp - MP_COST * 2
      self.rate_limited = true
      self.ps_handle = nil
      Timer.after(RATE_OF_FIRE, function() self.rate_limited = false end)
    end
    self.charged = false
  end
  if self.charge_handle then Timer.cancel(self.charge_handle) end
  self.ps.ps:stop()
  if self.ps_handle then Timer.cancel(self.ps_handle) end
end




Player_mt.__index = Player

function Player_mt.__call(_, args)
  return Player.new(args)
end

return setmetatable({}, Player_mt)