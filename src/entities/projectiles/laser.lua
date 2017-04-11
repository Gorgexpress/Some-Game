local Vec2 = require 'lib/vec2'
local Physics = require "src/systems/physics"
local EntityManager = require 'src/managers/entity'
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

--spawns another laser
local function iterate(self)
  local vertices = self.Body.polygon
  local cx, cy = (vertices[1] + vertices[3]) / 2, (vertices[2] + vertices[4]) / 2
  local after = function()
    local v = (self.target.center - Vec2(cx, cy)):normalize() * self.velocity:len()
    EntityManager.add(Entity.new({position = Vec2(cx, cy), target = self.target, iterations = self.iterations - 1, velocity = v, 
      spawn_time = self.spawn_time, linger_time = self.linger_time, extend_time = self.extend_time, move_time = self.move_time}))
  end
  if self.spawn_time <= 0 then
    after()
  else
    EntityManager.add('projectiles/spawner', {after = after, time = self.spawn_time, position = Vec2(cx, cy)})
  end
end

--[[this function will be passed to Timer.script and handles 
all stage changes(with the exception of collision which forces the laser
into the "shorten" state, all state changes are time based).]]
local function scriptUpdate(self)
  return
  function(wait)
    --extend laser by only moving the front 2 vertices
    wait(self.extend_time)
    --move entire laser
    self.state = 'move'
    --no more logic if no iterations, just move the laser normally until it is destroyed by collision
    if self.iterations == 0 then return end 
    --time spent normally moving the entire laser
    wait(self.move_time)
    --spawns another laser (a separate entity) from the current one
    iterate(self) 
    --determine when the back vertices will touch the front ones
    local shorten_time = abs((self.Body.polygon[3] - self.Body.polygon[5]) / self.velocity.x)
    --linger_time causes the laser to delay moving to the shorten state. None of the vertices move in this state
    if self.linger_time > 0 then
      self.state = 'linger'
      wait(self.linger_time)
    end
    --shorten laser until there's nothing left then destroy it
    self.state = 'shorten'
    wait(shorten_time)
    self.state = 'destroyed'
    end
end

function Entity.onCollision(self, other, type)
  if type == 'tile' and self.state ~= 'shorten' then
    self.state = 'shorten'
    self.Timer:clear()
    self.Timer:after(abs((self.Body.polygon[3] - self.Body.polygon[5]) / self.velocity.x), function() self.state = 'destroyed' end)
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
  self.Timer:update(dt)
  local vertices = self.Body.polygon
  local dx, dy = self.velocity.x * dt, self.velocity.y * dt
  if self.state == 'extend' then 
    --only the front of the laser is moving(causing the polygon to extend)
    extend(vertices, dx, dy)
    updateBoundingBox(self)
  elseif self.state == 'move' then
    move(vertices, dx, dy)
    --no need to update the bounding box in this case, just move it with velocity
    self.Transform.position.x, self.Transform.position.y = self.Transform.position.x + dx, self.Transform.position.y + dy
  elseif self.state == 'linger' then
    --nothing needs to be done
  elseif self.state == 'shorten' then
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
    Transform = transform,
    Body = body,
    velocity = velocity, --lowercase v, not a component!
    target = args.target or g_player,
    extend_time = args.extend_time or 0.2,
    iterations = args.iterations or 1,
    spawn_time = args.spawn_time or 1,
    move_time = args.move_time or 0.1,
    parent = args.parent or nil,
    active = true,
    state = 'init',
    linger_time = args.linger_time or 0,
    Timer = Timer.new(),
  }

  entity.Timer:script(scriptUpdate(entity))
  return setmetatable(entity, Entity_mt)
end

Entity_mt.__index = Entity

function Entity_mt.__call(_, args)
  return Entity.new(args)
end

return setmetatable({}, Entity_mt)