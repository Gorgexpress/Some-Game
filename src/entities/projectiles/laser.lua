local Vec2 = require 'lib/vec2'
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
  if type == 'tile' and self.state < 3 then
    self.state = 2
    self.timer = abs((self.body.polygon[3] - self.body.polygon[5]) / self.vel.x)
  elseif type == 'player' then
  end
end

function Entity.draw(self)
  local v = self.body.polygon
  love.graphics.polygon('fill', unpack(self.body.polygon))  
  --love.graphics.line(v[1], v[2], v[3], v[4])   
end

local function filter(self, other)
  if other.body and other.body.polygon then return nil end
  return 'cross'
end

function Entity.update(self, dt)
  local polygon = self.body.polygon
  local dx, dy = self.vel.x * dt, self.vel.y * dt
  if self.state == 0 then 
    self.timer = self.timer - dt
    if self.timer <= 0 then self.state = 1 end
    --only the front of the laser is moving(causing the polygon to extend)
    polygon[1], polygon[2], polygon[3], polygon[4] = 
      polygon[1] + dx, polygon[2] + dy, 
      polygon[3] + dx, polygon[4] + dy
    bbox(self)
  elseif self.state == 1 then
    --I'm kinda surprised this code even runs
    --move every vertice in the laser
    polygon[1], polygon[2], polygon[3], polygon[4], 
      polygon[5], polygon[6], polygon[7], polygon[8] = 
      polygon[1] + dx, polygon[2] + dy, 
      polygon[3] + dx, polygon[4] + dy,
      polygon[5] + dx, polygon[6] + dy, 
      polygon[7] + dx, polygon[8] + dy
    --no need to update the bounding box in this case, just move it with velocity
    self.transform.position.x, self.transform.position.y = self.transform.position.x + dx, self.transform.position.y + dy
    if self.iterations > 0 then
      self.timer = self.timer - dt
      if self.timer <= 0 then
        local cx, cy = (polygon[1] + polygon[3]) / 2, (polygon[2] + polygon[4]) / 2
        local v = (self.target.center - Vec2(cx, cy)):normalize() * self.vel:len()
        EntityManager.add(Entity.new({position = Vec2(cx, cy), target = self.target, iterations = self.iterations - 1, velocity = v}))
        self.state = 2
        self.timer = abs((self.body.polygon[3] - self.body.polygon[5]) / self.vel.x)
      end
    end
  elseif self.state == 2 then
    self.timer = self.timer - dt
    if self.timer <= 0 then self.state = 3 end
    --only the back of the laser moves, causing it to shorten
    polygon[5], polygon[6], polygon[7], polygon[8] = 
      polygon[5] + dx, polygon[6] + dy, 
      polygon[7] + dx, polygon[8] + dy
    bbox(self)
  else
    self.destroyed = true
  end
end

function Entity.new(args) 
  local entity = {}
  local width = args.width or 4
  local half_width = width / 2
  entity.vel = args.velocity or Vec2(0, 0)
  local forward = entity.vel:normalize()
  local x, y = args.position.x or 0, args.position.y or 0
  local x1, y1 = x + half_width * forward.y, y - half_width * forward.x
  local x2, y2 = x - half_width * forward.y, y + half_width * forward.x
  local dx, dy = x2 - x1, y2 - y1
  entity.transform = args.transform or {
      position = Vec2(x1, y1),
      forward = forward
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
      polygon = {x1, y1, x2, y2, x2, y2, x1, y1}

  }
  entity.target = args.target or g_player
  entity.iterations = args.iterations or 0
  entity.iterate_time = args.iterate_time or 1
  entity.wait = args.wait or 0.35
  entity.parent = args.parent or nil
  entity.active = true
  entity.timer = args.timer or 0.5
  entity.state = 0
  return setmetatable(entity, Entity_mt)
end

Entity_mt.__index = Entity

function Entity_mt.__call(_, args)
    return Entity.new(args)
end

return setmetatable({}, Entity_mt)