local Vec2 = require 'lib/vec2'
local VectorLight = require 'lib/vector-light'
local Timer = require 'lib/timer'
local Physics = require "src/systems/physics-system"
local EntityManager = require 'src/managers/entity-manager'
local abs, atan, max, min = math.abs, math.atan, math.max, math.min
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
  if other == self.target then self.state = 4 end
end


function Entity.draw(self)
  love.graphics.line(self.curve:render(3))
end

local function filter(self, other)
  if not other.body or other.body.type == 'player' then return 'cross'
  else return nil end
end

function Entity.update(self, dt)
  local position = self.transform.position
  self.curve:setControlPoint(1, position:unpack())
  if self.state == 0 then
    local dx, dy = self.target.center.x - position.x, self.target.center.y - position.y
    local dirx, diry = Vec2(dx, dy):normalize():unpack()
    self.transform.forward.x , self.transform.forward.y = dirx, diry
    self.velocity.x , self.velocity.y = dirx * self.speed , diry * self.speed
    if dx * dx + dy * dy <= self.dist2 then
      self.state = 1
      self.Timer:script(function(wait)
        self.Timer:tween(self.slow_time, self, {speed = self.min_speed}, 'linear')
        wait(self.wait)
        self.state = 2
        self.Timer:tween(self.speedup_time, self, {speed = self.max_speed}, 'quad')
        wait(0.5)
        self.state = 4
        wait(4)
        self.state = 5
      end) 
    end
  elseif self.state == 1 then
    local dx, dy = self.target.center.x - position.x, self.target.center.y - position.y
    local dirx, diry = Vec2(dx, dy):normalize():unpack()
    self.transform.forward.x , self.transform.forward.y = dirx, diry
    self.velocity.x , self.velocity.y = dirx * self.speed , diry * self.speed
  elseif self.state == 2 then
    local dx, dy = self.target.center.x - position.x, self.target.center.y - position.y
    local dirx, diry = Vec2(dx, dy):normalize():unpack()
    local forward = self.transform.forward
    local current_angle = forward:to_polar()
    local target_angle = Vec2(dirx, diry)
    local diff = forward:angle_between(target_angle)
    --might be better to do atan2(v2.y,v2.x) - atan2(v1.y,v1.x) for the angle, clamp the value, then
    --rotate using the clamped angle 
    local rate = math.min((self.rotation_speed * dt) / diff, 1)
    self.transform.forward = self.transform.forward:lerp(target_angle, rate)
    --self.transform.forward = self.transform.forward:rotate(diff)
    self.velocity.x , self.velocity.y = self.transform.forward.x * self.speed, self.transform.forward.y * self.speed
  elseif self.state == 4 then
  else
    self.destroyed = true
    for i, v in ipairs(self.children) do
      v.destroyed = true
    end
  end
  local x, y = self.transform.position:unpack()
  self.Timer:after(0.25, function() self.curve:setControlPoint(2, x, y) end)
  self.Timer:after(0.5, function() self.curve:setControlPoint(3, x, y) end)
  self.Timer:update(dt)
end


function Entity.new(args) 
  local entity = {}
  local width = args.width or 4
  local half_width = width / 2
  entity.speed = 250
  entity.velocity_dir = Vec2(0, 0)
  entity.velocity = Vec2(0, 0)
  local x, y = args.position.x or 0, args.position.y or 0
  entity.transform = args.transform or {
      position = Vec2(x, y),
      forward = Vec2(0, 0)
  }

  entity.body = args.body or {
      size = Vec2(1, 1),
      offset = Vec2(-0.5, -0.5),
      filter = args.filter or filter,
      type = args.type or 'projectile',
      damage = 1,
      properties = {
        damage = 1,
      },
  }
  entity.Timer = Timer.new()
  entity.curve = love.math.newBezierCurve(x, y, x, y, x, y)
  entity.target = args.target or g_player
  if args.dist then entity.dist2 = args.dist * args.dist2 else entity.dist2 = 150*150  end
  entity.wait = args.wait or 1
  entity.timer = 0
  entity.state = 0
  entity.min_speed = args.min_speed or 40
  entity.max_speed = 500
  entity.slow_time = args.slow_time or 0.4
  entity.speedup_time = args.speedup_time or 0.2
  entity.rotation_speed = math.pi / 2


  local mid = {
    transform = {
      position = entity.transform.position:clone(),
      forward = Vec2(0, 0)
    },
    body = entity.body,
    update = function(self) self.transform.position.x, self.transform.position.y = entity.curve:evaluate(0.5) end,
    draw = function(self)    end,
    onCollision = Entity.onCollision
  }
  local endp = {
    transform = {
      position = entity.transform.position:clone(),
      forward = Vec2(0, 0)
    },
    body = entity.body,
    update = function(self) self.transform.position.x, self.transform.position.y = entity.curve:evaluate(0.9) end,
    draw = function(self)  end,
    onCollision = Entity.onCollision
  }
  entity.children = {mid, endp}
  EntityManager.add(mid)
  EntityManager.add(endp)
  return setmetatable(entity, Entity_mt)
end

Entity_mt.__index = Entity

function Entity_mt.__call(_, args)
    return Entity.new(args)
end

return setmetatable({}, Entity_mt)