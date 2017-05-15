local Vec2 = require 'lib/vec2'
local Asset = require 'src/managers/asset'
local Game = require 'src/game'
local Timer = require 'lib/timer'

local Entity = {}
local Entity_mt = {}


function Entity.onCollision(self, other, type)
  if type == 'player' then
    
  end
end

function Entity.draw(self)
  love.graphics.rectangle('fill', self.Transform.position.x, self.Transform.position.y, self.Body.size:unpack())
end

local function filter(self, other)
  return nil 
end

local function decreaseCount(self)
  self.count = self.count - 1
  if self.count <= 0 then self.destroyed = true end
  Game.Signal.remove('enemy-destroyed', self.handle)
end


function Entity.new(x, y, properties) 
  local entity = {
    Transform = {
      position = Vec2(x, y),
    },
    Body = {
      size = Vec2(properties.width, properties.height),
      offset = Vec2(0, 0),
      filter = filter,
      type = 'tile',
    },
    count = properties.count or 0,
  }
  entity.handle = Game.Signal.register('enemy-destroyed', function() decreaseCount(entity) end)
  return setmetatable(entity, Entity_mt)
end

function Entity.clone(self)
  local entity = {}
  for k, v in pairs(self) do entity[k] = v end
  return setmetatable(entity, Entity_mt)
end

Entity_mt.__index = Entity

function Entity_mt.__call(_, x, y, properties)
    return Entity.new(x, y, properties)
end

return setmetatable({}, Entity_mt)