local Vec2 = require 'lib/vec2'
local THINK_TIME = 0.25

local Enemy = {}
local Enemy_mt = {}





local function enemyThink(self)
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


local function onCollision(self, other, type)
  if type then
    self.velocity = Vec2(0, 0)
    if type == 'bumper' then
      self.ai.timer = 0.1
      self.state.current = 'bump'
      self.velocity = -self.transform.forward:normalize() * 250
    else
      local info = other.body.response_info
      self.ai.timer = 0.2
      self.state.current = 'bump'
      self.health, self.stamina = self.health - info.damage, self.stamina - info.stamina_damage
      self.velocity = other.transform.forward:normalize() * info.knockback
    end
  end
end

local function draw(self)
  love.graphics.rectangle('fill', self.transform.position.x, self.transform.position.y, self.body.size:unpack())   
end

local function filter(self, other)
  return 'slide'
end

local function update(self, dt)
  self.ai.timer = self.ai.timer - dt
  if self.ai.timer <= 0 then
    enemyThink(self)
    self.ai.timer = THINK_TIME
  end
end

function Enemy.new(args) 
  local entity = {}
  entity.transform = {
      position = args.position or Vec2(0, 0),
      forward = Vec2(0, -1),
  }
  entity.body = {
      size = Vec2(32, 32),
      offset = Vec2(0, 0),
      filter = filter,
      type = 'bump',
      response_info = {
        damage = 1,
        stamina_damage = 1,
      },

  }
  entity.velocity = Vec2(0, 0)
  entity.state = {
    current = 'idle'
  }
  entity.ai = {
    timer = 0.25
  }
  entity.health, entity.max_health = 50, 50
  entity.stamina, entity.max_stamina = 100, 100
  
  entity.update = update
  entity.active = true
  entity.draw = draw
  entity.onCollision = onCollision
  entity.speed = 50
  return entity
end

Enemy_mt.__index = Enemy

function Enemy_mt.__call(_, args)
    return Enemy.new(args)
end

return setmetatable({}, Enemy_mt)