local Vec2 = require 'lib/vec2'
local Vec2l = require 'lib/vector-light'
local Game = require 'src/game'
local addEntity = require ('src/managers/entity').add
local bbox = require('lib/utility').bbox
local sub, normalize, perpendicular = Vec2l.sub, Vec2l.normalize, Vec2l.perpendicular
local Physics = Game.Physics

local RANGE = 300

local Entity = {}
local Entity_mt = {}

local Explosion = {}

local function explode(self)
  if self.type == '+' or self.type == '*' then
    addEntity(Explosion.new(self.x, self.y - RANGE, self.x, self.y + RANGE, 6, self.damage, 0.75))
    addEntity(Explosion.new(self.x - RANGE, self.y, self.x + RANGE, self.y, 6, self.damage, 0.75))
  end
  if self.type == 'x' or self.type =='*'then
    addEntity(Explosion.new(self.x - RANGE, self.y + RANGE, self.x + RANGE, self.y - RANGE, 6, self.damage, 0.75))
    addEntity(Explosion.new(self.x - RANGE, self.y - RANGE, self.x + RANGE, self.y + RANGE, 6, self.damage, 0.75))
  end
end

function Entity.draw(self)
  if self.image then
    love.graphics.draw(self.image, self.quad, self.x, self.y)
  else
    if self.time > 0.5 then
      love.graphics.setColor(0, 0, 0)
    else
      love.graphics.setColor(255, 0, 0)
    end
    love.graphics.circle('fill', self.x, self.y, 6)
    love.graphics.setColor(255, 255, 255)
  end
end


function Entity.update(self, dt)
  if self.time <= 0 then
    explode(self)
    self.destroyed = true
  else
    self.time = self.time - dt
  end    
end

function Entity.new(x, y, damage, time, types)
  if type(types) == 'table' then types = types[love.math.random(#types)] end
  return setmetatable({
    x = x,
    y = y,
    type = types,
    damage = damage or 1,
    time = time or 3,
  }, Entity_mt)
end

Entity_mt.__index = Entity

function Entity_mt.__call(_, args)
    return Entity.new(args)
end

local Explosion_mt = {}
Explosion_mt.__index = Explosion

local function filter(self, other)
  if other == Game.player then return 'cross' end
  return nil
end

function Explosion.draw(self)
  love.graphics.polygon('fill', self.Body.polygon)
end

function Explosion.update(self, dt)
  self.time = self.time - dt
  if self.time <= 0 then self.destroyed = true end
end

function Explosion.new(x1, y1, x2, y2, width, damage, time)
  width = width * 0.5
  local px, py = perpendicular(normalize(sub(x2, y2, x1, y1)))
  local polygon = {x1 - px * width, y1 - py * width, x1 + px * width, y1 + py * width, x2 + px * width, y2 + py * width, x2 - px * width, y2 - py * width}
  local x, y, w, h = bbox(polygon)
  return setmetatable({
    Transform = {
      position = Vec2(x, y)
    },
    Body = {
      size = Vec2(w, h),
      offset = Vec2(0, 0),
      filter = filter,
      polygon = polygon,
      type = 'projectile'
    },
    time = time or 3,
  }, Explosion_mt)
end

function Explosion_mt.__call(_, x1, y1, x2, y2, width, damage)
    return Explosion.new(x1, y1, x2, y2, width, damage)
end


return setmetatable({}, Entity_mt)