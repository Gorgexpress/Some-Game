local Vec2 = require 'lib/vec2'
local VectorLight = require 'lib/vector-light'

local Physics = require "src/systems/physics-system"
local EntityManager = require 'src/managers/entity-manager'
local abs = math.abs
local Entity = {}
local Entity_mt = {}

local function bbox(self)
  local vertices = self.body.polygon
  local ulx,uly = vertices[1], vertices[2]
	local lrx,lry = ulx,uly
	for i=3,#vertices, 2 do
    local x, y = vertices[i], vertices[i + 1]
		if ulx > x then ulx = x end
		if uly > y then uly = y end

		if lrx < x then lrx = x end
		if lry < y then lry = y end
	end

  self.transform.position.x, self.transform.position.y = ulx, uly
  local w, h = lrx - ulx, lry - uly
  self.body.size.x, self.body.size.y = w, h
  Physics.updateRectSize(self, w, h)
end

function Entity.onCollision(self, other, type)

end


function Entity.draw(self)
  love.graphics.polygon('fill', unpack(self.body.polygon))  
end

local function filter(self, other)
  return nil
end

function Entity.update(self, dt)
  self.curve:setControlPoint(1, position:unpack())
  local position = self.transform.position
  if self.state == 0 then
    local dx, dy = self.target.center.x - position.x, self.target.center.y - position.y
    local dirx, diry = Vec2(dx, dy):normalize():unpack()
    self.velocity = dirx * self.speed, diry * self.speed
    if dx * dx + dy * dy <= self.dist2 then
      self.state = 1
      self.timer = self.wait
    end
  elseif state == 1 then

  end
end

function Entity.new(args) 
  local entity = {}
  local width = args.width or 4
  local half_width = width / 2
  entity.speed = 100
  entity.velocity_dir = Vec2(0, 0)
  local x, y = args.position.x or 0, args.position.y or 0
  entity.transform = args.transform or {
      position = Vec2(x, y),
      forward = Vec2(0, 0)
  }
  entity.body = args.body or {
      size = Vec2(1, 1),
      offset = Vec2(0, 0),
      filter = args.filter or filter,
      type = args.type or 'projectile',
      damage = 1,
      properties = {
        damage = 1,
      },
  }
  entity.curve = love.math.newBezierCurve(x, y, x, y, x, y)
  entity.target = args.target or g_player
  if args.dist then entity.dist2 = args.dist * args.dist2 else entity.dist = 250*250 
  entity.wait = args.wait or 1.5
  entity.timer = 0
  entity.state = 0
  return setmetatable(entity, Entity_mt)
end

Entity_mt.__index = Entity

function Entity_mt.__call(_, args)
    return Entity.new(args)
end

return setmetatable({}, Entity_mt)