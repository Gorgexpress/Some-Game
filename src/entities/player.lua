local Vec2 = require 'lib/vec2'
local anim8 = require 'lib/anim8'
local Timer = require 'lib/timer'
local Asset = require 'src/managers/asset-manager'
local image = Asset.getImage('player')
local Utility = require 'lib/utility'
local vecToDir = Utility.vecToDir
local grid = anim8.newGrid(40, 40, image:getWidth(), image:getHeight())
local SIN45 = 0.70710678118
local Entity = require 'src/managers/entity-manager'
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
    response_info = {
      damage = 1,
      stamina_damage = 25,
      knockback = 500,
    },
  }
  entity.center = entity.transform.position + entity.body.offset + entity.body.size * 0.5
  entity.velocity = Vec2(0, 0)
  entity.animator = {
    animations = {
    idle_u = anim8.newAnimation(grid(2, 3), 1000),
    idle_r = anim8.newAnimation(grid(2, 2), 1000),
    idle_d = anim8.newAnimation(grid(2, 1), 1000),
    idle_l = anim8.newAnimation(grid(2, 4), 1000),
    running_u = anim8.newAnimation(grid('1-3', 3), 0.2),
    running_r = anim8.newAnimation(grid('1-3', 2), 0.2),
    running_d = anim8.newAnimation(grid('1-3', 1), 0.2),
    running_l = anim8.newAnimation(grid('1-3', 4), 0.2),
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
  entity.speed = 250
  return setmetatable(entity, Player_mt)
end

function Player.draw(self)
  self.animator.current:draw(self.sprite, self.transform.position:unpack())
end

local function recover(self)
  movement()
end

function Player.onCollision(self, other, type)
  if type then
    self.velocity = Vec2(0, 0)
    if type == 'bumper' then
      self.timer:after(0.1, function() self.state = 'idle' movement() end)
      self.state = 'bumping'
      self.animator.current = self.animator.animations['idle_' .. vecToDir(self.transform.forward)]
    else
      local info = other.body.response_info
      self.health, self.stamina.current = self.health - info.damage, self.stamina.current - info.stamina_damage
      self.timer:after(0.2, function() self.state = 'idle' movement() end)
      self.state = 'bumped'
      self.animator.current = self.animator.animations['idle_' .. vecToDir(self.transform.forward)]
    end
  end
end

function Player.update(self, dt)
  self.center = self.transform.position + self.body.offset + self.body.size * 0.5
  self.timer:update(dt)
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
    else 
      if dir_x == 0 or dir_y == 0 then
        self.velocity = Vec2(self.speed * dir_x, self.speed * dir_y)
        self.transform.forward.x, self.transform.forward.y = dir_x, dir_y
      else
        self.velocity = Vec2(self.speed * SIN45 * dir_x, self.speed * SIN45 * dir_y)
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