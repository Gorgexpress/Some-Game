local Vec2 = require 'lib/vec2'
local Physics = require 'src/systems/physics-system'
local addEntity = require('src/managers/entity-manager').add
local Entity = {}
local Entity_mt = {}

local function filter(self, other)
  if other.properties or other == self.target then
    return 'cross'
  end
  return nil 
end

local function targetFilter(self, other)
  if other and other.body and other.body.type == 'player' then return 'cross' end
  return nil
end


function Entity.onCollision(self, other, type)
  if other.properties or other.body.type == 'player' then
    self.destroyed = true
  end
end

function Entity.draw(self)
  love.graphics.rectangle('fill', self.transform.position.x, self.transform.position.y, self.body.size:unpack())   
end

function Entity.update(self, dt)
  if self.state == 1 then
    local x, y = self.transform.position:unpack()
    if self.velocity.x ~= 0 then
      local other, len = Physics.querySegment(x, y - 1000, x, y + 1000, function(other) if self.target == other then return 'cross' else return nil end end)
      if len ~= 0 then
        for k, v in pairs(other[1]) do print(k, v) end
        if other[1].center.y > self.transform.position.y + self.body.size.y * 0.5 then
          addEntity(Entity.new({
            position = Vec2(self.transform.position.x, self.transform.position.y + self.body.size.y),
            speed = self.speed,
            target = self.target,
            forward = Vec2(0, 1)}))
        else
          addEntity(Entity.new({
            position = Vec2(self.transform.position.x, self.transform.position.y + self.body.size.y),
            speed = self.speed,
            target = self.target,
            forward = Vec2(0, -1)}))
        end
        self.destroyed = true
      end
    else
      local other, len = Physics.querySegment(x - 1000, y, x + 1000, y, function(other) if self.target == other then return 'cross' else return nil end end)
      if len ~= 0 then
        if other[1].center.x > self.transform.position.x + self.body.size.x * 0.5 then
          addEntity(Entity.new({
            position = Vec2(self.transform.position.x, self.transform.position.y + self.body.size.y),
            speed = self.speed,
            target = self.target,
            forward = Vec2(1, 0)}))
        else
          addEntity(Entity.new({
            position = Vec2(self.transform.position.x, self.transform.position.y + self.body.size.y),
            speed = self.speed,
            target = self.target,
            forward = Vec2(-1, 0)}))
        end
        self.destroyed = true
      end
    end
  else
  end
end

function Entity.new(args) 
  local target = args.target or g_player
  if not args.forward then
    local dx, dy = target.center.x - args.position.x, target.center.y - args.position.y
    if math.abs(dx) > math.abs(dy) then
      if dx > 0 then args.forward = Vec2(1, 0)
      else args.forward = Vec2(-1, 0) end
    else
      if dy > 0 then args.forward = Vec2(0, 1)
      else args.forward = Vec2(0, -1) end
    end
  end

  local transform = args.transform or {
    position = args.position or Vec2(0, 0),
    forward = args.forward or Vec2(0, -1),
  }
  local width = args.width or 6
  local length = args.length or 20
  local size = transform.forward.x ~= 0 and Vec2(length, width) or Vec2(width, length)

  local body = {
    size = size,
    offset = Vec2(0, 0),
    filter = function() return nil end,
    type = args.type or 'projectile',
    damage = 1,
  }

  local velocity = transform.forward * (args.speed or 350)

  if args.position then
    transform.position = transform.position - body.size * 0.5
  end

  local entity = {
    transform = transform,
    body = body,
    velocity = velocity,
    state = 1,
    target = args.target or g_player,
    iterations = args.iterations or 0
  }
  if entity.iterations == 0 then entity.state = 2 end

  return setmetatable(entity, Entity_mt)
end

Entity_mt.__index = Entity

function Entity_mt.__call(_, args)
    return Entity.new(args)
end

return setmetatable({}, Entity_mt)