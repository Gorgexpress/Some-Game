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
  if other == self.target then self.state = 5 end
end


function Entity.draw(self)
  --love.graphics.line(self.curve:render())
  self.mesh:setVertices(bezierToMesh(self.curve, 6))
  love.graphics.draw(self.mesh)
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
        wait(0.75)
        self.state = 4
        wait(1)
        self.state = 5
        wait(4)
        self.state = 6
      end) 
    end
  elseif self.state == 1 then
    local dx, dy = self.target.center.x - position.x, self.target.center.y - position.y
    local dirx, diry = Vec2(dx, dy):normalize():unpack()
    self.transform.forward.x , self.transform.forward.y = dirx, diry
    self.velocity.x , self.velocity.y = dirx * self.speed , diry * self.speed
  elseif self.state == 2 then
    --[[
    local dx, dy = self.target.center.x - position.x, self.target.center.y - position.y
    local dirx, diry = Vec2(dx, dy):normalize():unpack()
    local forward = self.transform.forward
    local current_angle = forward:to_polar()
    local target_angle = Vec2(dirx, diry)
    local diff = forward:angle_between(target_angle)
    local rate = math.min((self.rotation_speed * dt) / diff, 1)
    self.transform.forward = self.transform.forward:lerp(target_angle, rate)]]
    local desired = atan2(self.target.center.y - position.y, self.target.center.x - position.x)
    local current = atan2(self.transform.forward.y, self.transform.forward.x)
    local diff = desired - current
    if math.abs(diff) > math.pi then diff = -(diff - math.pi) end
    local rate = math.max(-self.rotation_speed * dt, math.min(self.rotation_speed * dt, diff))
    self.transform.forward = self.transform.forward:rotate(rate)
    self.last_rate = rate
    self.velocity.x , self.velocity.y = self.transform.forward.x * self.speed, self.transform.forward.y * self.speed
  elseif self.state == 4 then
    if self.last_rate then self.transform.forward = self.transform.forward:rotate(self.last_rate / 4) end
    self.velocity.x , self.velocity.y = self.transform.forward.x * self.speed, self.transform.forward.y * self.speed
  elseif self.state == 5 then
  elseif self.state == 6 then
    self.destroyed = true
    for i, v in ipairs(self.children) do
      v.destroyed = true
    end
  end
  local x, y = self.transform.position:unpack()
  self.Timer:update(dt)
  if self.flag then
    local idx = #self.prev / 2
    if idx % 2 == 0 then idx = idx + 1 end
    self.mid.transform.position.x, self.mid.transform.position.y = self.prev[idx], self.prev[idx + 1]
  end
  if not self.prevsize then
    local s = #self.prev
    self.prev[s + 1] = x 
    self.prev[s + 2] = y 
  else
    self.mid.transform.position.x, self.mid.transform.position.y = self.prev[self.mid_idx], self.prev[self.mid_idx + 1]
    self.endp.transform.position.x, self.endp.transform.position.y = self.prev[1], self.prev[2]
    table.remove(self.prev, 1)
    table.remove(self.prev, 1)
    self.prev[self.prevsize - 1] = x 
    self.prev[self.prevsize] = y 
  end
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
  entity.mesh = love.graphics.newMesh(bezierToMesh(entity.curve, 6), 'strip', 'stream')
  love.graphics.setPointSize(4)
  local c = love.graphics.newCanvas(6, 6)
  love.graphics.setCanvas(c)
  love.graphics.rectangle('fill', 0, 0, 6, 6 )
  love.graphics.setCanvas()
  entity.mesh:setTexture(c)


  local mid = {
    transform = {
      position = entity.transform.position:clone(),
      forward = Vec2(0, 0)
    },
    body = body,
    update = function(self) 
      entity.curve:setControlPoint(2, self.transform.position:unpack())
      
    end,
    draw = function(self)    end,
    onCollision = Entity.onCollision,
  }
  local endp = {
    transform = {
      position = entity.transform.position:clone(),
      forward = Vec2(0, 0)
    },
    body = entity.body,
    update = function(self) 
      entity.curve:setControlPoint(3, self.transform.position:unpack())

    end,
    draw = function(self)  end,
    onCollision = Entity.onCollision,
  }
  entity.children = {mid, endp}
  EntityManager.add(mid)
  EntityManager.add(endp)
  entity.Timer:after(0.25, function() entity.half = true end)
  entity.Timer:after(0.5, function() 
    entity.half = false
    entity.prevsize = #entity.prev
    entity.mid_idx = math.floor(entity.prevsize / 2)
    if entity.mid_idx % 2 == 0 then entity.mid_idx = entity.mid_idx + 1 end
    end)
  entity.mid = mid
  entity.endp = endp
  entity.flag = false
  entity.prev = {}
  return setmetatable(entity, Entity_mt)
end

Entity_mt.__index = Entity

function Entity_mt.__call(_, args)
    return Entity.new(args)
end

return setmetatable({}, Entity_mt)