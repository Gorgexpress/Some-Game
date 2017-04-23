local Vec2 = require 'lib/vec2'
local Vec2l = require 'lib/vector-light'
local Game = require 'src/game'
local Laser = require 'src/entities/projectiles/laser'
local Bullet = require 'src/entities/projectiles/bullet'
local Asset = require 'src/managers/asset'
local add, sub, mul, normalize = Vec2l.add, Vec2l.sub, Vec2l.mul, Vec2l.normalize
local sqrt, random, rad = math.sqrt, math.random, math.rad
local EntityManager = require 'src/managers/entity'
local addEntity = EntityManager.add

local ProjectileSpawner = {}

local _player = Game.player
local _defs = {}

function ProjectileSpawner.fire(type, x, y, vx, vy, damage, update, properties)
  if _defs[type] then
    _defs[type](x, y, vx, vy, damage, update, properties)
  else
    addEntity('projectiles/'..type, {position = position:clone(), velocity = velocity:clone()}, properties)
  end
end
--[[
function ProjectileSpawner.fireAtPosition(self, target, type)
  local position = self.transform.position + self.body.offset + self.body.size * 0.5
  if not target.transform then
    local velocity = (target - position):normalize() * 50
    EntityManager.add('bullet', {position = position, velocity = velocity})
  end

end

function ProjectileSpawner.fireAtPlayer(self, speed, arg3, arg4, arg5)
  if Vec2.is_vec2(self) then
    local vx, vy = mul(speed, normalize(_player.x - self.x, _player.y - self.y))
  elseif type(self) == 'number' then
    local vx, vy = mul(arg5, normalize(arg3 - self, arg4 - speed))
  else
    --entities
  end
end

function ProjectileSpawner.fireFromCenter(self, forward, speed, type, properties)
  local x, y = self.Transform.position:unpack()
  local ox, oy = self.Body.offset:unpack()
  local sx, sy = self.Body.size:unpack()
  x, y = x + ox + sx * 0.5, y + oy + sy * 0.5
  addEntity('projectiles/'..type, {position = Vec2(x1, y1), velocity = forward * speed}, properties)
end]]

function ProjectileSpawner.fireAtPlayerFromCenter(self, type, speed, damage, variance, properties)
  local x, y = self.Transform.position:unpack()
  local ox, oy = self.Body.offset:unpack()
  local sx, sy = self.Body.size:unpack()
  local x1, y1 = x + ox + sx * 0.5, y + oy + sy * 0.5
  local x2, y2 = _player.center:unpack()
  local dx, dy = x2 - x1, y2 - y1
  local len = sqrt(dx * dx + dy * dy)
  local vx, vy = (dx / len) * speed, (dy / len) * speed
  if variance then
    vx, vy = rotate(rad(random(-variance, variance)), vx, vy)
  end
  ProjectileSpawner.fire(type, x1, y1, vx, vy)
end

function _defs.basiclaser(x, y, vx, vy)
  addEntity(Laser{position = Vec2(x, y), velocity = Vec2(vx, vy), iterations = 1})
end

local _basicimage = Asset.getImage('graphics/projectiles/bullet2')
local _basicquad = love.graphics.newQuad(32, 0, 16, 16, _basicimage:getDimensions())
function _defs.basic(x, y, vx, vy)
  addEntity(Bullet.new(x, y, vx, vy, 3, 3, 6, 6, 10, _basicimage, _basicquad))
end

local _bpurpleimage = Asset.getImage('graphics/projectiles/bigpurple')
local _bpurplequad = love.graphics.newQuad(64, 0, 32, 32, _basicimage:getDimensions())
function _defs.bigpurple(x, y, vx, vy)
  addEntity(Bullet.new(x, y, vx, vy, 6, 6, 12, 12, 10, _bbpurpleimage, _bpurplequad))
end

local _abimage = Asset.getImage('graphics/projectiles/bullet2')
local _abquad = love.graphics.newQuad(32, 32, 16, 16, _abimage:getWidth(), _abimage:getHeight())
function _defs.angledbullet(x, y, vx, vy, damage, update, properties)
  addEntity(Bullet.new(x, y, vx, vy, 3, 3, 6, 6, damage, _abimage, _abquad, 'true', update, properties))
end



return ProjectileSpawner