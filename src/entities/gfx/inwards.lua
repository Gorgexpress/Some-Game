local Vec2 = require 'lib/vec2'
local Timer = require 'lib/timer'
local Game = require 'src/game'
local Asset = require 'src/managers/asset'
local Utility = require 'lib/utility'

local Entity = {}
local Entity_mt = {}

local _image = Asset.getImage('bullet2')
local _quad = love.graphics.newQuad(48, 16, 16, 16, _image:getDimensions())
local _ps = love.graphics.newParticleSystem(_image, 20)
--[[
_ps:setParticleLifetime(0.25)
_ps:setRadialAcceleration(-2000)
_ps:setAreaSpread('uniform', 80, 80)
_ps:setEmissionRate(5)
_ps:setQuads(_quad)
_ps:setRelativeRotation('true')
_ps:setEmitterLifetime(2.5)]]
_ps:setParticleLifetime(0.15)
_ps:setRadialAcceleration(-2000)
_ps:setAreaSpread('ellipse', 32, 32)
_ps:setEmissionRate(10)
_ps:setQuads(_quad)
_ps:setRelativeRotation('true')
_ps:setEmitterLifetime(2.5)


function Entity.draw(self)

  love.graphics.draw(self.ps, self.Transform.position.x, self.Transform.position.y)
end



function Entity.update(self, dt)
  self.ps:update(dt)
end

function Entity.start(self)
  self.ps:start()
end

function Entity.new(parent, localx, localy, image, quad) 
  local transform =  {
    position = parent.Transform.position + Vec2(localx, localy),
    localp = Vec2(localx, localy),
  }
  local ps = _ps:clone()
  ps:start()
  local entity = {
    Transform = transform,
    Parent = parent,
    ps = ps,
  }
  if image then ps:setTexture(image) end
  if quad then ps:setQuads(quad) end
  return setmetatable(entity, Entity_mt)
end

Entity_mt.__index = Entity

function Entity_mt.__call(_, parent, localx, localy, image, quad)
  return Entity.new(parent, localx, localy, image, quad)
end

return setmetatable({}, Entity_mt)