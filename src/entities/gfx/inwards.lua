local Vec2 = require 'lib/vec2'
local Timer = require 'lib/timer'
local Game = require 'src/game'
local Asset = require 'src/managers/asset'
local Utility = require 'lib/utility'

local Entity = {}
local Entity_mt = {}

local _image = Asset.getImage('graphics/projectiles/bullet2')
local _quad = love.graphics.newQuad(48, 16, 16, 16, _image:getDimensions())
local _ps = love.graphics.newParticleSystem(_image, 20)
ps:setParticleLifetime(0.25)
ps:setRadialAcceleration(-2000)
ps:setAreaSpread('uniform', 80, 80)
ps:setEmissionRate(5)
ps:setQuads(_quad)
ps:setRelativeRotation('true')
ps:setEmitterLifetime(2.5)


function Entity.draw(self)
  love.graphics.draw(self.ps, self.Transform.position.x, self.Transform.position.y)
end



function Entity.update(self, dt)
  self.ps:update(dt)
end

function Entity.new(parent, localx, localy) 
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
  Timer.after(2.5, function() entity.destroyed = true end)
  return setmetatable(entity, Entity_mt)
end

Entity_mt.__index = Entity

function Entity_mt.__call(_, args)
  return Entity.new(args)
end

return setmetatable({}, Entity_mt)