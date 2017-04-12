local Vec2 = require 'lib/vec2'
local Asset = require 'src/managers/asset'
local Timer = require 'lib/timer'
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

local image = Asset.getImage('graphics/projectiles/bullet2')
local quad = love.graphics.newQuad(32, 0, 16, 16, image:getDimensions())

function Entity.onCollision(self, other, type)
  if type == 'player' or type == 'tile' then
    self.destroyed = true
  end
end

function Entity.draw(self)
  if _use_shader then 
    setShader(shader)
  end
  if self.is_rotated then
    local x, y =  self.Transform.position:unpack()
    draw(self.image, self.quad, x, y, self.Transform.forward:to_polar())
  else
    draw(self.image, self.quad, self.Transform.position:unpack())
  end
  setShader()
end

local function filter(self, other)
  if other.properties or (other.Body and other.Body.type == 'player') then
    return 'cross'
  end
  return nil 
end


function Entity.new(args, properties) 

  local transform = args.transform or {
    position = args.position or Vec2(0, 0),
    forward = Vec2(0, -1),
  }
  local body = args.body or {
    size = Vec2(4, 4),
    offset = Vec2(6, 6),
    filter = args.filter or filter,
    type = args.type or 'projectile',
    damage = 1,
  }

  local entity = {
    Transform = transform,
    Body = body,
    Velocity = args.velocity or Vec2(0, 0),
    update = args.update or nil,
    image = image,
    quad = quad,
  }

  if properties then
    for k, v in pairs(properties) do
      entity[k] = v
    end
  end

  return setmetatable(entity, Entity_mt)
end

Entity_mt.__index = Entity

function Entity_mt.__call(_, args)
    return Entity.new(args)
end

return setmetatable({}, Entity_mt)