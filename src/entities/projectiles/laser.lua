local Vec2 = require 'lib/vec2'
local Physics = require "src/systems/physics-system"
local EntityManager = require 'src/managers/entity-manager'
local Timer = require 'lib/timer'
local Utility = require 'lib/utility'
local bbox = Utility.bbox
local abs = math.abs
local Entity = {}
local Entity_mt = {}

local function updateBoundingBox(self)
  local x, y, w, h = bbox(self.body.polygon)
  self.transform.position.x, self.transform.position.y = x, y
  self.body.size.x, self.body.size.y = w, h
  Physics.updateRectSize(self, w, h)
end

local function extend(v, dx, dy)
  v[1], v[2], v[3], v[4] = v[1] + dx, v[2] + dy, v[3] + dx, v[4] + dy
end

local function move(v, dx, dy)
  v[1], v[2], v[3], v[4], v[5], v[6], v[7], v[8] = 
    v[1] + dx, v[2] + dy, v[3] + dx, v[4] + dy, v[5] + dx, v[6] + dy, v[7] + dx, v[8] + dy
end

local function shorten(v, dx, dy)
  v[5], v[6], v[7], v[8] = v[5] + dx, v[6] + dy, v[7] + dx, v[8] + dy
end

local function update(self, dt)

end

function Entity.onCollision(self, other, type)
  if type == 'tile' and self.state < 3 then
    self.state = 2
    self.timer = abs((self.body.polygon[3] - self.body.polygon[5]) / self.vel.x)
  elseif type == 'player' then
  end
end


function Entity.draw(self)
  love.graphics.polygon('fill', unpack(self.body.polygon))  
end

local function filter(self, other)
  if not other.body or other.body.type == 'player' then return 'cross'
  else return nil end
end

function Entity.update(self, dt)
  local vertices = self.body.polygon
  local dx, dy = self.vel.x * dt, self.vel.y * dt
  if self.state == 0 then 
    self.timer = self.timer - dt
    if self.timer <= 0 then 
      self.timer = self.iterate_time
      self.state = 1 
    end
    --only the front of the laser is moving(causing the polygon to extend)
    extend(vertices, dx, dy)
    updateBoundingBox(self)
  elseif self.state == 1 then
    move(vertices, dx, dy)
    --no need to update the bounding box in this case, just move it with velocity
    self.transform.position.x, self.transform.position.y = self.transform.position.x + dx, self.transform.position.y + dy
    if self.iterations > 0 then
      self.timer = self.timer - dt
      if self.timer <= 0 then
        self.state = 2
        self.timer = abs((vertices[3] - vertices[5]) / self.vel.x)
        local cx, cy = (vertices[1] + vertices[3]) / 2, (vertices[2] + vertices[4]) / 2
        local after = function()
          local v = (self.target.center - Vec2(cx, cy)):normalize() * self.vel:len()
          EntityManager.add(Entity.new({position = Vec2(cx, cy), target = self.target, iterations = self.iterations - 1, velocity = v, wait = self.wait}))
        end
        if self.wait <= 0 then
          after()
        else
          EntityManager.add('projectiles/spawner', {after = after, time = self.wait, position = Vec2(cx, cy)})
        end
      end
    end
  elseif self.state == 2 then
    self.timer = self.timer - dt
    if self.timer <= 0 then self.state = 3 end
    --only the back of the laser moves, causing it to shorten
    shorten(vertices, dx, dy)
    updateBoundingBox(self)
  else
    self.destroyed = true
  end
end

function Entity.new(args) 
  local width = args.width or 4
  local half_width = width / 2
  --determine forward based off of velocity
  local velocity = args.velocity or Vec2(0, 0)
  local forward = velocity:normalize()
  local x, y = args.position.x or 0, args.position.y or 0
  --calculate x and y of the frontmost 2 vertices based off the width, forward,
  --and the initial position of the center
  local x1, y1 = x + half_width * forward.y, y - half_width * forward.x
  local x2, y2 = x - half_width * forward.y, y + half_width * forward.x
  local dx, dy = x2 - x1, y2 - y1

  local transform = args.transform or {
    position = Vec2(x1, y1),
    forward = forward
  }
  local body = {
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

  local entity = {
    transform = transform,
    body = body,
    vel = velocity,
    target = args.target or g_player,
    iterations = args.iterations or 0,
    iterate_time = args.iterate_time or 1,
    wait = args.wait or 0.35,
    parent = args.parent or nil,
    active = true,
    timer = args.timer or 0.5,
    state = 0
  }
  return setmetatable(entity, Entity_mt)
end

Entity_mt.__index = Entity

function Entity_mt.__call(_, args)
  return Entity.new(args)
end

return setmetatable({}, Entity_mt)