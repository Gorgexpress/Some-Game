local Vec2 = require 'lib/vec2'
local VectorLight = require 'lib/vector-light'
local Timer = require 'lib/timer'
local Physics = require "src/systems/physics"
local EntityManager = require 'src/managers/entity'
local AssetManager = require 'src/managers/asset'
local Game = require 'src/game'
local homing = require('src/entities/components/update').homing
local abs, atan2, max, min = math.abs, math.atan2, math.max, math.min
local Entity = {}
local Entity_mt = {}

local _image = AssetManager.getImage('curve')


function Entity.onCollision(self, other, type)
  if other == self.target then 
    self.destroyed = true
  end
end


function Entity.draw(self)
  love.graphics.points(self.previous_positions)
  love.graphics.points(self.Transform.position:unpack())
end

local function filter(self, other)
  if not other.Body or other.Body.type == 'player' then return 'cross'
  else return nil end
end

function Entity.update(self, dt)
  if self.timer < 5 then
    homing(self, dt)
  end
  local x, y = self.Transform.position:unpack()
  local npoints = #self.previous_positions
  local lastx, lasty = self.previous_positions[npoints - 1], self.previous_positions[npoints]
  if math.abs((lastx*lastx + lasty*lasty) - (x*x + y*y)) > 5 then
    table.remove(self.previous_positions, 1)
    table.remove(self.previous_positions, 1)
    self.previous_positions[npoints - 1] = self.Transform.position.x
    self.previous_positions[npoints] = self.Transform.position.y
  end
  self.timer = self.timer + dt
end


function Entity.new(x, y, properties) 
  local entity = {}
  local width = properties.width or 4
  local half_width = width / 2
  entity.speed = properties.speed or 500
  entity.Velocity = properties.velocity or Vec2(0, 0)
  local x, y = x or 0, y or 0
  entity.Transform = {
      position = Vec2(x, y),
      forward = Vec2(properties.dirx or 0, properties.diry or -1)
  }

  entity.Body = properties.body or {
      size = Vec2(1, 1),
      offset = Vec2(-0.5, -0.5),
      filter = properties.filter or filter,
      type = properties.type or 'projectile',
      damage = 1,
  }
  entity.timer = 0
  entity.target = properties.target or Game.player
  entity.rotation_speed = math.pi / 2
  entity.previous_positions = {x, y, x, y, x, y, x, y, x, y, x, y, x, y, x ,y ,x ,y ,x ,y ,x, y,x ,y}
  return setmetatable(entity, Entity_mt)
end

Entity_mt.__index = Entity

function Entity_mt.__call(_, x, y, properties)
    return Entity.new(x, y, properties)
end

return setmetatable({}, Entity_mt)