local Vec2 = require 'lib/vec2'
local THINK_TIME = 0.25

local Entity = {}
local Entity_mt = {}


local function filter(self, other)
  if not other.body or other.body.type == 'player' then return 'slide'
  elseif other.body.type == 'projectile' then return nil
  else return 'cross'
  end
end

function Entity.think(self)
  if self.state == 'hurt' or self.state =='melee' or self.state == 'stun' then return end
  local dx, dy = self.transform.position.x - g_player.center.x, self.transform.position.y - g_player.center.y
  if dx * dx + dy * dy < 700* 700 then
    if math.abs(dx) > math.abs(dy) then
      if dx <= 0 then
        self.velocity = Vec2(self.speed, 0)
        self.transform.forward = Vec2(1, 0)
      else
        self.velocity= Vec2(-self.speed, 0)
        self.transform.forward = Vec2(-1, 0)
      end
    else
      if dy <= 0 then
        self.velocity = Vec2(0, self.speed)
        self.transform.forward = Vec2(0, 1)
      else
        self.velocity = Vec2(0, -self.speed)
        self.transform.forward = Vec2(0, -1)
      end
    end
  else
    self.velocity.x, self.velocity.y = 0, 0
  end
end


function Entity.onCollision(self, other, type)
  if type == 'tile' or type == 'bump' then return end
  if type ~= 'tile' then
    self.velocity = Vec2(0, 0)
    if type == 'bumper' then
      self.think_timer = 0.1
      self.state = 'bump'
      self.velocity = -self.transform.forward:normalize() * 250
    elseif type =='bumped' then
      local info = other.body.properties
      self.think_timer = 0.2
      self.state = 'bump'
      self.health = self.health - info.damage
      self.velocity = other.transform.forward:normalize() * info.knockback
    end
  end
end

function Entity.draw(self)
  love.graphics.rectangle('fill', self.transform.position.x, self.transform.position.y, self.body.size:unpack())   
end


function Entity.update(self, dt)
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
    properties = {
      damage = 1,
    },
  }

  local entity = {
    transform = transform,
    body = body,
    velocity = args.velocity or Vec2(0, 0),
    state = 'idle',
    think_timer = 0.25,
    health = 50,
    max_health = 50,
    speed = args.speed or 50
  }
  return setmetatable(entity, Entity_mt)
end

Entity_mt.__index = Entity

function Entity_mt.__call(_, args)
    return Entity.new(args)
end

return setmetatable({}, Entity_mt)