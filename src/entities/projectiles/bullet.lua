local Vec2 = require 'lib/vec2'
local Asset = require 'src/managers/asset'
local Timer = require 'lib/timer'
local normalize = require('lib/vector-light').normalize
local centerEntity = require('lib/utility').centerEntity
local draw, setShader = love.graphics.draw, love.graphics.setShader

local Entity = {}
local Entity_mt = {}



local shader = love.graphics.newShader[[
    vec4 effect( vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords ){
      vec4 pixel = Texel(texture, texture_coords );//This is the current pixel color
      return pixel * 1.15;
    }
  ]]
local _use_shader = false
Timer.every(0.2, function() _use_shader = not _use_shader end)

local image = Asset.getImage('bullet2')
local quad = love.graphics.newQuad(32, 0, 16, 16, image:getDimensions())

function Entity.onCollision(self, other, type)
  if type == 'playerih' or type == 'tile' then
    self.destroyed = true
  end
end

function Entity.draw(self)
  if _use_shader then 
    setShader(shader)
  end
  if self.is_rotated then
    local x, y = self.Transform.position:unpack()
    local _, theta = self.Velocity:to_polar()
    --hard coded right now, but offset should be half the size of the quad. See Quad:getViewport()
    draw(self.image, self.quad, x + 8, y + 8, theta, 1, 1, 8, 8)
  else
    draw(self.image, self.quad, self.Transform.position:unpack())
  end
  setShader()
end

local function filter(self, other)
  if other.properties or other.Body.type == 'tile' or other.Body.type == 'player' then
    return 'cross'
  end
  return nil 
end


function Entity.new(x, y, vx, vy, w, h, ox, oy, damage, image, quad, isrotated, update, properties) 
  x, y = centerEntity(x, y, w, h, ox, oy)
  return setmetatable({
    Transform = {
      position = Vec2(x, y),
    },
    Body = {
      size = Vec2(w, h),
      offset = Vec2(ox, oy),
      filter = filter,
      type = 'projectile',
      damage = damage,
    },
    Velocity = Vec2(vx, vy),
    image = image or _image,
    quad = quad or _quad,
    is_rotated = isrotated,
    update = update,
    Properties = properties,
  }, Entity_mt)
end

function Entity.clone(self)
  local entity = {}
  for k, v in pairs(self) do entity[k] = v end
  return setmetatable(entity, Entity_mt)
end

Entity_mt.__index = Entity

function Entity_mt.__call(_, x, y, vx, vy, w, h, ox, oy, image, quad, isrotated, update, properties)
    return Entity.new(x, y, vx, vy, w, h, ox, oy, damage, image, quad, isrotated, update, properties)
end

return setmetatable({}, Entity_mt)