local Vec2 = require 'lib/vec2'
local THINK_TIME = 0.25

local Entity = {}
local Entity_mt = {}





function Entity.think(self)
  if self.state.current == 'hurt' or self.state.current =='melee' or self.state.current== 'stun' then return end
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
  if type ~= 'tile' then
    self.velocity = Vec2(0, 0)
    if type == 'bumper' then
      self.think_timer = 0.1
      self.state.current = 'bump'
      self.velocity = -self.transform.forward:normalize() * 250
    else
      local info = other.body.properties
      self.think_timer = 0.2
      self.state.current = 'bump'
      self.health = self.health - info.damage
      self.velocity = other.transform.forward:normalize() * info.knockback
    end
  end
end

function Entity.draw(self)
  love.graphics.rectangle('fill', self.transform.position.x, self.transform.position.y, self.body.size:unpack())   
end

local function filter(self, other)
  if other.body and other.body.type == 'projectile' then return nil end
  return 'slide'
end

function Entity.update(self, dt)
  self.think_timer = self.think_timer - dt
  if self.think_timer <= 0 then
    self:think()
    self.think_timer = THINK_TIME
  end
end

function Entity.new(args) 
  local entity = {}
  entity.transform = args.transform or {
      position = args.position or Vec2(0, 0),
      forward = Vec2(0, -1),
  }
  entity.body = args.body or {
      size = Vec2(32, 32),
      offset = Vec2(0, 0),
      filter = filter,
      type = 'bump',
      properties = {
        damage = 1,
      },

  }
  entity.velocity = args.velocity or Vec2(0, 0)
  entity.state = {
    current = 'idle'
  }
  entity.think_timer = 0.25
  entity.health, entity.max_health = 50, 50
  
  entity.active = true
  entity.speed = args.speed or 50
  return setmetatable(entity, Entity_mt)
end

Entity_mt.__index = Entity

function Entity_mt.__call(_, args)
    return Entity.new(args)
end

return setmetatable({}, Entity_mt)