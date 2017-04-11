local Vec2 = require 'lib/vec2'
local THINK_TIME = 0.25

local Entity = {}
local Entity_mt = {}


local function filter(self, other)
  if not other.Body or other.Body.type == 'player' then return 'slide'
  elseif other.Body.type == 'projectile' then return nil
  else return 'cross'
  end
end

function Entity.think(self)
  if self.state == 'hurt' or self.state =='melee' or self.state == 'stun' then return end
  local dx, dy = self.Transform.position.x - g_player.center.x, self.Transform.position.y - g_player.center.y
  if dx * dx + dy * dy < 700* 700 then
    if math.abs(dx) > math.abs(dy) then
      if dx <= 0 then
        self.Velocity = Vec2(self.speed, 0)
        self.Transform.forward = Vec2(1, 0)
      else
        self.Velocity= Vec2(-self.speed, 0)
        self.Transform.forward = Vec2(-1, 0)
      end
    else
      if dy <= 0 then
        self.Velocity = Vec2(0, self.speed)
        self.Transform.forward = Vec2(0, 1)
      else
        self.Velocity = Vec2(0, -self.speed)
        self.Transform.forward = Vec2(0, -1)
      end
    end
  else
    self.Velocity.x, self.Velocity.y = 0, 0
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
      self.state = 'bump'
      self.Velocity = -self.Transform.forward:normalize() * 250
    elseif type =='bumped' then
      if self.invincibility_to_bump_timer > 0 then return end
      self.Velocity = Vec2(0, 0)
      self.invincibility_to_bump_timer = 0.1
      self.think_timer = 0.2
      self.state = 'bumped'
      self.health = math.max(self.health - other.Body.damage or 0, 0)
      self.Velocity = other.Transform.forward:normalize() * 500
    end
  end
  if self.health <= 0 then self.destroyed = true end
end

function Entity.draw(self)
  love.graphics.rectangle('fill', self.Transform.position.x, self.Transform.position.y, self.Body.size:unpack())   
end


function Entity.update(self, dt)
  if self.invincibility_to_bump_timer > 0 then
    self.invincibility_to_bump_timer = self.invincibility_to_bump_timer - dt 
  end
  self.think_timer = self.think_timer - dt
  if self.think_timer <= 0 then
    self:think()
    self.think_timer = THINK_TIME
  end
end

function Entity.new(args) 
  local transform = args.transform or {
    position = args.position or Vec2(0, 0),
    forward = Vec2(0, -1),
  }
  local body = args.body or {
    size = Vec2(32, 32),
    offset = Vec2(0, 0),
    filter = filter,
    type = 'bump',
    damage = 1,
    properties = {
      damage = 1,
    },
  }

  local entity = {
    Transform = transform,
    Body = body,
    Velocity = args.velocity or Vec2(0, 0),
    state = 'idle',
    think_timer = 0.25,
    health = 50,
    max_health = 50,
    speed = args.speed or 50,
    invincibility_to_bump_timer = 0,
  }
  return setmetatable(entity, Entity_mt)
end

Entity_mt.__index = Entity

function Entity_mt.__call(_, args)
    return Entity.new(args)
end

return setmetatable({}, Entity_mt)