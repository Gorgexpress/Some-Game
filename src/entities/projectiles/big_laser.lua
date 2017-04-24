local Vec2 = require 'lib/vec2'
local Physics = require "src/systems/physics"
local addEntity = require('src/managers/entity').add
local Timer = require 'lib/timer'
local Game = require 'src/game'
local Asset = require 'src/managers/asset'
local Utility = require 'lib/utility'
local InwardsFX = require 'src/entities/gfx/inwards'
local bbox = Utility.bbox
local abs = math.abs
local Entity = {}
local Entity_mt = {}

local _image = Asset.getImage('bullet2')
local _quad = love.graphics.newQuad(16, 20, 16, 1, _image:getDimensions())
local _quad2 = love.graphics.newQuad(48, 16, 16, 16, _image:getDimensions())

local function updateBoundingBox(self)
  Physics.updateRectSize(self, self.Body.size:unpack())
end

local function tileFilter(other)
  if not other.properties then return nil end
  return 'cross' 
end

local function extend(v, dx, dy)
  v[1], v[2], v[3], v[4] = v[1] + dx, v[2] + dy, v[3] + dx, v[4] + dy
end

local function move(v, dx, dy)
  v[1], v[2], v[3], v[4], v[5], v[6], v[7], v[8] = 
    v[1] + dx, v[2] + dy, v[3] + dx, v[4] + dy, v[5] + dx, v[6] + dy, v[7] + dx, v[8] + dy
end

local function shorten(v, dx, dy)
  v[5], v[6], v[7], v[8] = v[5] + dx, v[6] + dy, v[7] + dx, v[8] + dy
end



function Entity.onCollision(self, other, type)
  if type == 'tile' then
  elseif type == 'player' then
  end
end


function Entity.draw(self)
  if self.delay <= 0 then
    love.graphics.draw(_image, _quad, self.Transform.position.x, self.Transform.position.y, 0, 1, self.Body.size.y)
  end
end

local function filter(self, other)
  if not other.Body or other.Body.type == 'player' then return 'cross'
  else return nil end
end

function Entity.update(self, dt)
  if self.delay > 0 then
    self.delay = self.delay - dt
    return
  end
  local items, len = Game.physics.querySegment(self.Transform.position.x + 8, self.Transform.position.y, self.Transform.position.x + 8, self.Transform.position.y + 1000, tileFilter)
  if len > 0 then
    if self.Transform.position.y + self.Body.size.y == items[1].y then return end
    self.Body.size.y = items[1].y - self.Transform.position.y - 1
    updateBoundingBox(self)
  end
  self.lifetime = self.lifetime - dt
  if self.lifetime <= 0 then self.destroyed = true end
end



function Entity.new(args) 
  local transform = args.transform or {
    position = args.position,
    forward = forward
  }
  local body = {
    size = Vec2(16, 1),
    offset = Vec2(0, 0),
    filter = args.filter or filter,
    type = args.type or 'projectile',
    damage = 1,
  }

  Utility.center(transform.position, body.size, body.offset)

  local entity = {
    Transform = transform,
    Body = body,
    active = false,
    lifetime = args.lifetime or 4,
    delay = args.delay or 2.5,
  }
  entity.ps = addEntity(InwardsFX.new(entity, body.size.x * 0.5, 0))
  return setmetatable(entity, Entity_mt)
end

Entity_mt.__index = Entity

function Entity_mt.__call(_, args)
  return Entity.new(args)
end

return setmetatable({}, Entity_mt)