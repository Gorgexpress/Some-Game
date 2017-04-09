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
  local x, y, w, h = bbox(self.Body.polygon)
  self.Transform.position.x, self.Transform.position.y = x, y
  self.Body.size.x, self.Body.size.y = w, h
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
    self.timer = abs((self.Body.polygon[3] - self.Body.polygon[5]) / self.velocity.x)
  elseif type == 'player' then
  end
end


function Entity.draw(self)
  love.graphics.polygon('fill', unpack(self.Body.polygon))  
end

local function filter(self, other)
  if not other.Body or other.Body.type == 'player' then return 'cross'
  else return nil end
end

function Entity.update(self, dt)
  local vertices = self.Body.polygon
  local dx, dy = self.velocity.x * dt, self.velocity.y * dt
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
    self.Transform.position.x, self.Transform.position.y = self.Transform.position.x + dx, self.Transform.position.y + dy
    if self.iterations > 0 then
      self.timer = self.timer - dt
      if self.timer <= 0 then
        self.state = 2
        self.timer = abs((vertices[3] - vertices[5]) / self.velocity.x)
        local cx, cy = (vertices[1] + vertices[3]) / 2, (vertices[2] + vertices[4]) / 2
        local after = function()
          local v = (self.target.center - Vec2(cx, cy)):normalize() * self.velocity:len()
          EntityManager.add(Entity.new({position = Vec2(cx, cy), target = self.target, iterations = self.iterations - 1, velocity = v, 
            wait = self.wait, linger_time = self.linger_time, expand_time = self.expand_time}))
        end
        if self.wait <= 0 then
          after()
        else
          EntityManager.add('projectiles/spawner', {after = after, time = self.wait, position = Vec2(cx, cy)})
        end
      end
    end
  elseif self.state == 2 then
    if self.linger_time > 0 then
      self.linger_time = self.linger_time - dt
      return
    end
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

  local linger_time = args.iterations > 0 and (args.linger_time or 0) or 0
  local wait = args.wait or 0.35
  if linger_time > wait then linger_time = wait end
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
    Transform = transform,
    Body = body,
    velocity = velocity, --lowercase v, not a component!
    target = args.target or g_player,
    expand_time = args.expand_time or 0.35,
    iterations = args.iterations or 0,
    iterate_time = args.iterate_time or 1,
    wait = wait or 0.35,
    parent = args.parent or nil,
    active = true,
    timer = args.expand_time or 0.35,
    state = 0,
    linger_time = linger_time
  }
  return setmetatable(entity, Entity_mt)
end

Entity_mt.__index = Entity

function Entity_mt.__call(_, args)
  return Entity.new(args)
end

return setmetatable({}, Entity_mt)