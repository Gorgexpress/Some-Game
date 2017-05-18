local Vec2 = require 'lib/vec2'
local VectorLight = require 'lib/vector-light'
local Timer = require 'lib/timer'
local Physics = require "src/systems/physics"
local EntityManager = require 'src/managers/entity'
local addEntity = EntityManager.add
local AssetManager = require 'src/managers/asset'
local Game = require 'src/game'
local seek = require('src/entities/components/update').seek
local abs, atan2, max, min = math.abs, math.atan2, math.max, math.min
local Entity = {}
local Entity_mt = {}

local _image = AssetManager.getImage('curve')

local function lock(self)
  local p = self.Transform.forward:perpendicular()
  local tc = self.target.center
  local lc = self.Transform.position + p * 20
  if math.abs((lc.x * lc.x + lc.y * lc.y) - (tc.x * tc.x + tc.y * tc.y)) < 400 then
    Timer.after(0.25, function() self.homing = false end)
  end
  lc = self.Transform.position + -p * 20
  if math.abs((lc.x * lc.x + lc.y * lc.y) - (tc.x * tc.x + tc.y * tc.y)) < 400 then
    Timer.after(0.25, function() self.homing = false end)
  end
end

function Entity.onCollision(self, other, type)
  if other == self.target then 
    self.destroyed = true
  end
end


function Entity.draw(self)
  local x, y = self.Transform.position:unpack()
  local _, theta = self.Velocity:to_polar()
  --hard coded right now, but offset should be half the size of the quad. See Quad:getViewport()
  --love.graphics.draw(self.image, self.quad, x + 8, y + 8, theta, 1, 1, 8, 8)
  love.graphics.draw(self.ps)
end

local function filter(self, other)
  if not other.Body or other.Body.type == 'player' then return 'cross'
  else return nil end
end

function Entity.update(self, dt)
  seek(self, dt)
  lock(self)
  self.speed = math.min(self.max_speed, self.speed + self.max_speed * dt)
  local dimx, dimy = self.image:getDimensions()
  self.ps:moveTo(self.Transform.position.x +16, self.Transform.position.y - 16)
  self.ps:update(dt)
  self.hb_timer = self.hb_timer - dt
  if self.hb_timer <= 0 then
    self.hb_timer = 0.05
    addEntity({
      Transform = {
        position = self.Transform.position:clone(),
      },
      Body = {
        size = self.Body.size:clone(),
        offset = self.Body.offset:clone(),
        filter = filter,
        type = 'projectile',
        damage = self.Body.damage,
      },
      draw = function(self) end,
      time = 0,
      update = function(self, dt)
        self.time = self.time + dt
        if self.time >= 0.2 then self.destroyed  = true end
      end,
      onCollision = function(self, other) if other == Game.player then self.destroyed = true end end
    })
  end
end


function Entity.new(x, y, dirx, diry, w, h, ox, oy, damage, image, quad, properties) 
  ps = love.graphics.newParticleSystem(image, 200)
  ps:setQuads(quad)
  ps:setParticleLifetime(0.2)
  ps:setEmissionRate(200)
  return setmetatable({
    Transform = {
      position = Vec2(x, y),
      forward = Vec2(dirx, diry):normalize()
    },
    Body = {
      size = Vec2(w, h),
      offset = Vec2(ox, oy),
      filter = filter,
      type = 'projectile',
      damage = damage,
    },
    Velocity = Vec2(0, 0),
    image = image or _image,
    quad = quad or _quad,
    Properties = properties,
    target = Game.player,
    rotation_speed = math.pi,
    speed = 0,
    max_speed = 750,
    homing = true,
    ps = ps,
    hb_timer = 0.05,
  }, Entity_mt)
end

Entity_mt.__index = Entity

function Entity_mt.__call(_, x, y, properties)
    return Entity.new(x, y, properties)
end

return setmetatable({}, Entity_mt)