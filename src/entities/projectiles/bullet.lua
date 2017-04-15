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
  if type == 'playerih' or type == 'tile' then
    self.destroyed = true
  end
end

function Entity.draw(self)
  if _use_shader then 
    setShader(shader)
  end
  if self.is_rotated then
    local x, y =  self.Transform.position:unpack()
    --local theta = self.Transform.forward:angle_between(Vec2.unit_x)
    local _, theta = self.Transform.forward:to_polar()
    print(theta)
    --hard coded right now, but offset should be half the size of the quad. See Quad:getViewport()
    draw(self.image, self.quad, x + 8, y + 8, theta, 1, 1, 8, 8)
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
    offset = Vec2(5, 5),
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
  transform.position.x, transform.position.y = transform.position.x - body.offset.x - body.size.x * 0.5, transform.position.y - body.offset.y - body.size.y * 0.5
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