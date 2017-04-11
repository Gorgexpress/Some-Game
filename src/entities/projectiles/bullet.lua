local Vec2 = require 'lib/vec2'
local Asset = require 'src/managers/asset'
local Timer = require 'lib/timer'

local image = Asset.getImage('bullet')
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

local image = Asset.getImage('bullet')
local quad = love.graphics.newQuad(0, 0, 16, 16, image:getDimensions())

function Entity.onCollision(self, other, type)
  if type == 'player' or type == 'tile' then
    self.destroyed = true
  end
end

function Entity.draw(self)
  if _use_shader then 
    love.graphics.setShader(shader)
  end
  love.graphics.draw(image, quad, self.Transform.position:unpack())
  love.graphics.setShader()
end

local function filter(self, other)
  if other.properties or (other.Body and other.Body.type == 'player') then
    return 'cross'
  end
  return nil 
end

function Entity.update(self, dt)

end

function Entity.new(args) 

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
    properties = {
      damage = 1
    }
  }
  if not body.filter then body.filter = filter end
  if args.position then
    transform.position = transform.position - body.offset - body.size * 0.5
  end

  local entity = {
    Transform = transform,
    Body = body,
    Velocity = args.velocity or Vec2(0, 0),
    update = args.update
  }

  return setmetatable(entity, Entity_mt)
end

Entity_mt.__index = Entity

function Entity_mt.__call(_, args)
    return Entity.new(args)
end

return setmetatable({}, Entity_mt)