local Vec2 = require 'lib/vec2'
local VectorLight = require 'lib/vector-light'
local Timer = require 'lib/timer'
local Physics = require "src/systems/physics"
local EntityManager = require 'src/managers/entity'
local bezierToMesh = require('lib/utility').bezierToMesh
local abs, atan2, max, min = math.abs, math.atan2, math.max, math.min
local Entity = {}
local Entity_mt = {}

local function bbox(self)
  local vertices = self.Body.polygon
  local ulx,uly = vertices[1], vertices[2]
	local lrx,lry = ulx,uly
	for i=3,#vertices, 2 do
    local x, y = vertices[i], vertices[i + 1]
		if ulx > x then ulx = x end
		if uly > y then uly = y end

		if lrx < x then lrx = x end
		if lry < y then lry = y end
	end

  self.Transform.position.x, self.Transform.position.y = ulx, uly
  local w, h = lrx - ulx, lry - uly
  self.Body.size.x, self.Body.size.y = w, h
  Physics.updateRectSize(self, w, h)
end

function Entity.onCollision(self, other, type)
  if other == self.target then 
    for k, v in pairs(self.children) do
      v.destroyed = true
    end
    self.destroyed = true
  end
end


function Entity.draw(self)
  --love.graphics.line(self.curve:render())
  self.mesh:setVertices(bezierToMesh(self.curve, 6))
  love.graphics.draw(self.mesh)
  love.graphics.circle('fill', self.Transform.position.x, self.Transform.position.y, 3)
  love.graphics.circle('fill', self.endp.Transform.position.x, self.endp.Transform.position.y, 3)
end

local function filter(self, other)
  if not other.Body or other.Body.type == 'player' then return 'cross'
  else return nil end
end

function Entity.update(self, dt)
  local position = self.Transform.position
  self.curve:setControlPoint(1, position:unpack())
  if self.state == 0 then
    local dx, dy = self.target.center.x - position.x, self.target.center.y - position.y
    local dirx, diry = Vec2(dx, dy):normalize():unpack()
    self.Transform.forward.x , self.Transform.forward.y = dirx, diry
    self.Velocity.x , self.Velocity.y = dirx * self.speed , diry * self.speed
    if dx * dx + dy * dy <= self.dist2 then
      self.state = 1
      self.Timer:script(function(wait)
        self.Timer:tween(self.slow_time, self, {speed = self.min_speed}, 'linear')
        wait(self.slow_time * 0.5)
        self.Timer:tween(self.slow_time, self.mid, {speed = self.min_speed}, 'linear')
        wait(self.slow_time * 0.5)
        self.Timer:tween(self.slow_time, self.endp, {speed = self.min_speed}, 'linear')
        wait(self.delay)

        if  self.state ~= 6 then self.state = 2 end
        self.Timer:tween(self.speedup_time, self, {speed = self.max_speed}, 'quad')
        wait(self.speedup_time * 0.5)
        self.Timer:tween(self.speedup_time, self.mid, {speed = self.max_speed}, 'quad')
        wait(self.speedup_time * 0.5)
        self.Timer:tween(self.speedup_time, self.endp, {speed = self.max_speed}, 'quad')
        self.state = 3

        --wait(0.5)
        --self.state = 5
        --wait(4)
        --self.state = 6
      end) 
    end
  elseif self.state == 1 then
    local dx, dy = self.target.center.x - position.x, self.target.center.y - position.y
    local dirx, diry = Vec2(dx, dy):normalize():unpack()
    self.Transform.forward.x , self.Transform.forward.y = dirx, diry
    self.Velocity.x , self.Velocity.y = dirx * self.speed , diry * self.speed
  elseif self.state == 2 or self.state == 3 then
    local desired = atan2(self.target.center.y - position.y, self.target.center.x - position.x)
    local current = atan2(self.Transform.forward.y, self.Transform.forward.x)
    local diff = desired - current
    if math.abs(diff) > math.pi then diff = -(diff - math.pi) end
    local rate = math.max(-self.rotation_speed * dt, math.min(self.rotation_speed * dt, diff))
    self.Transform.forward = self.Transform.forward:rotate(rate)
    self.Velocity.x , self.Velocity.y = self.Transform.forward.x * self.speed, self.Transform.forward.y * self.speed
    if self.state == 3 then
      local dx, dy = self.target.center.x - position.x, self.target.center.y - position.y
      if dx*dx + dy*dy < 2000 then 
        self.state = 4
        self.last_rate = rate
        self.Timer:after(1, function() self.state = 5 end)
        self.Timer:after(3, function() self.state = 6 end)
      end
    end
  elseif self.state == 4 then
    if self.last_rate then self.Transform.forward = self.Transform.forward:rotate(self.last_rate / 2) end
    self.Velocity.x , self.Velocity.y = self.Transform.forward.x * self.speed, self.Transform.forward.y * self.speed
  elseif self.state == 5 then
  elseif self.state == 6 then
    self.destroyed = true
    for i, v in ipairs(self.children) do
      v.destroyed = true
    end
  end
  local x, y = self.Transform.position:unpack()
  self.Timer:update(dt)
  --self.Timer:after(0.25, function() self.curve:setControlPoint(2, x, y) end)
  --self.Timer:after(0.5, function() self.curve:setControlPoint(3, x, y) end)
end


function Entity.new(args) 
  local entity = {}
  local width = args.width or 4
  local half_width = width / 2
  entity.speed = 250
  entity.velocity_dir = Vec2(0, 0)
  entity.Velocity = Vec2(0, 0)
  local x, y = args.position.x or 0, args.position.y or 0
  entity.Transform = args.transform or {
      position = Vec2(x, y),
      forward = Vec2(0, 0)
  }

  entity.Body = args.body or {
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
  entity.delay = args.delay or 1
  entity.wait = args.wait or 0.5
  entity.timer = 0
  entity.state = 0
  entity.min_speed = args.min_speed or 40
  entity.max_speed = 500
  entity.slow_time = args.slow_time or 0.4
  entity.speedup_time = args.speedup_time or 0.2
  entity.rotation_speed = math.pi / 2
  entity.mesh = love.graphics.newMesh(bezierToMesh(entity.curve, 6), 'strip', 'stream')
  love.graphics.setPointSize(4)
  local c = love.graphics.newCanvas(6, 6)
  love.graphics.setCanvas(c)
  love.graphics.rectangle('fill', 0, 0, 6, 6 )
  love.graphics.setCanvas()
  entity.mesh:setTexture(c)


  local mid = {
    Transform = {
      position = entity.Transform.position:clone(),
      forward = Vec2(0, 0)
    },
    update = function(self) 
      entity.curve:setControlPoint(2, self.Transform.position:unpack())
      if self.Velocity then
        local x1, y1 = entity.curve:evaluate(0.5)
        local x2, y2 = entity.curve:evaluate(0.4)
        local dir = Vec2(x2 - x1, y2 - y1):normalize()
        self.Velocity = dir * self.speed

      end
    end,
    draw = function(self)    end,
    speed = entity.speed
  }
  local endp = {
    Transform = {
      position = entity.Transform.position:clone(),
      forward = Vec2(0, 0)
    },
    Body = entity.Body,
    update = function(self) 
      entity.curve:setControlPoint(3, self.Transform.position:unpack())
      if self.Velocity then
        local x1, y1 = entity.curve:evaluate(1)
        local x2, y2 = entity.curve:evaluate(0.9)
        local dir = Vec2(x2 - x1, y2 - y1):normalize()
        self.Velocity = dir * self.speed
      end
    end,
    draw = function(self)  end,
    onCollision = Entity.onCollision,
    speed = entity.speed
  }
  entity.children = {mid, endp}
  EntityManager.add(mid)
  EntityManager.add(endp)
  entity.Timer:after(entity.wait * 0.5, function() mid.Velocity = Vec2(0, 0) end)
  entity.Timer:after(entity.wait, function() endp.Velocity = Vec2(0, 0) end)
  entity.mid = mid
  entity.endp = endp
  return setmetatable(entity, Entity_mt)
end

Entity_mt.__index = Entity

function Entity_mt.__call(_, args)
    return Entity.new(args)
end

return setmetatable({}, Entity_mt)