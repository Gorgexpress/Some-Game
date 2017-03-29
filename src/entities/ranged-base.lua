local Vec2 = require 'lib/vec2'
local THINK_TIME = 0.25
local EntityManager = require 'src/managers/entity-manager'
local Entity = {}
local Entity_mt = {}

local DEFAULT_AGGRO_RANGE = 500

local DEFAULT_THINK_TIMER = 0.5
local DEFAULT_ATTACK_TIMER = 2


function Entity.think(self)
  if self.state == 'hurt' or self.state =='melee' then return end
  self.velocity.x, self.velocity.y = 0, 0
  if not self.attacking then
    local dx, dy = self.transform.position.x - self.target.center.x, self.transform.position.y - self.target.center.y
    if dx * dx + dy * dy < self.aggro_range then
      self.attacking = true
      self.think_timer = self.attack_timer
    end
  else 
    local args =  {
      position = self.transform.position:clone(),
      velocity = (self.target.center - self.transform.position):normalize() * 50
    }
    EntityManager.add('bullet', args)
    self.think_timer = self.attack_timer
  end
end


function Entity.onCollision(self, other, type)
  if type ~= 'tile' and type ~= 'projectile' then
    self.velocity = Vec2(0, 0)
    if type == 'bumper' then
      self.think_timer = 0.1
      self.state = 'bump'
      self.velocity = -self.transform.forward:normalize() * 250
    elseif type == 'bumped' then 
      local info = other.body.response_info
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

local function filter(self, other)
  if other.properties or other == self.target then
    return 'slide'
  end
  return nil
end

function Entity.update(self, dt)
  self.think_timer = self.think_timer - dt
  if self.think_timer <= 0 then
    self:think()
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
      response_info = {
        damage = 1,
      },

  }
  entity.velocity = args.velocity or Vec2(0, 0)
  entity.state = 'idle'
  entity.think_timer = args.think_timer or DEFAULT_THINK_TIMER 
  entity.think_time = args.think_time or DEFAULT_THINK_TIMER 
  entity.attack_timer = args.attack_timer or DEFAULT_ATTACK_TIMER
  entity.attacking = false
  entity.health, entity.max_health = 50, 50
  
  entity.active = true
  entity.speed = args.speed or 50
  entity.target = args.target or g_player
  if args.aggro_range then
    entity.aggro_range = args.aggro_range * args.aggro_range
  else
    entity.aggro_range = DEFAULT_AGGRO_RANGE * DEFAULT_AGGRO_RANGE
  end
  return setmetatable(entity, Entity_mt)
end

Entity_mt.__index = Entity

function Entity_mt.__call(_, args)
    return Entity.new(args)
end

return setmetatable({}, Entity_mt)