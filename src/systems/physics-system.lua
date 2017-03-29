local Bump = require 'lib/bump'
local vec2 = require 'lib/vec2'
local acos, abs, min = math.acos, math.abs, math.min


local m_physics

local PhysicsSystem = {}

--[[
local function bumpCollision2(self, other, normal)
  local angle = acos(self.transform.forward.dot(other.transform.forward))
end
]]

--TODO move this into player.lua or a utility function.
--[[
The self variable always refers to the player here. The normal variable is always in respect to the player too.
3 cases here.
Case 1: If the player is idle, the other entity will always attack the player
Case 2: If one entity A into the side or back of entity B, then entity A attacks entity B.
Case 3: For head on collision, the player must 'clip' the side of the other entity to do damage. If the centers
of both entities are too close, the player is the one that gets attacked.

This code is a mess, but it works so I haven't bothered changing it. The way it is now is pretty efficient,
but this method will rarely be called so that's not an issue.

Another way to do this could be using angles and trajectories.
Could grab forward+middle point of player and compare with either
forward+middle of the enemy, or the touch variable from bump.

]]
local function bumpCollision(self, other, normal, touch)
  --player always loses if idle
  if self.state == 'idle' then
    self:onCollision(other, 'bumped')
    other:onCollision(self, 'bumper')
    return
  end
  local p1, p2 = self.transform.position + self.body.offset, other.transform.position + other.body.offset
  local f1, f2 = self.transform.forward, other.transform.forward
  local s1, s2 = self.body.size, other.body.size
  local angle = math.atan2(touch.y - self.old_y, touch.x - self.old_x)
  --print(math.deg(angle))
  local depth_hit = 16
  if normal.y == -1 or normal.y == 1 then
    if f1.y == -f2.y then
      if p1.x < p2.x and p1.x + s1.x > p2.x + s2.x then
        self:onCollision(other, 'bumped')
        other:onCollision(self, 'bumper')
      else
        local depth_left = abs(p2.x + s2.x - p1.x)
        local depth_right = abs(p1.x + s1.x - p2.x)
        if min(depth_left, depth_right) > depth_hit then
          self:onCollision(other, 'bumped')
          other:onCollision(self, 'bumper') 
        else 
          self:onCollision(other, 'bumper')
          other:onCollision(self, 'bumped')
        end
      end
    elseif f1.y == f2.y then 
      if f1.y == 1 then 
        if p1.y <= p2.y then 
          self:onCollision(other, 'bumper')
          other:onCollision(self, 'bumped') 
        else 
          self:onCollision(other, 'bumped')
          other:onCollision(self, 'bumper')
        end
      else 
        if p1.y <= p2.y then 
          self:onCollision(other, 'bumped')
          other:onCollision(self, 'bumper')
        else 
          self:onCollision(other, 'bumper')
          other:onCollision(self, 'bumped')  
        end
      end
    else
      if f1.y == 0 then 
        self:onCollision(other, 'bumped')
        other:onCollision(self, 'bumper') 
      else 
        self:onCollision(other, 'bumper')
        other:onCollision(self, 'bumped')  
      end
    end
  else 
    if f1.x == -f2.x then
      if p1.y < p2.y and p1.y + s1.y > p2.y + s2.y then
        self:onCollision(other, 'bumped')
        other:onCollision(self, 'bumper')
      else
        local depth_left = abs(p2.y + s2.y - p1.y)
        local depth_right = abs(p1.y + s1.y - p2.y)
        if min(depth_left, depth_right) > depth_hit then
          self:onCollision(other, 'bumped')
          other:onCollision(self, 'bumper') 
        else 
          self:onCollision(other, 'bumper')
          other:onCollision(self, 'bumped')
        end
      end
    elseif f1.x == f2.x then 
      if f1.x == 1 then 
        if p1.x <= p2.x then 
          self:onCollision(other, 'bumper')
          other:onCollision(self, 'bumped') 
        else 
          self:onCollision(other, 'bumped')
          other:onCollision(self, 'bumper')
        end
      else 
        if p1.x <= p2.x then 
          self:onCollision(other, 'bumped')
          other:onCollision(self, 'bumper')
        else 
          self:onCollision(other, 'bumper')
          other:onCollision(self, 'bumped') 
        end
      end
    else
      if f1.x == 0 then 
        self:onCollision(other, 'bumped')
        other:onCollision(self, 'bumper') 
      else 
        self:onCollision(other, 'bumper')
        other:onCollision(self, 'bumped')  
      end
    end
  end   
end

function PhysicsSystem.update(entities, num_entities, dt)
  local ignore = {}
  for i=1, num_entities do
    local entity = entities[i]
    if entity.body then
      local p = entity.transform.position
      local ox, oy = entity.body.offset:unpack()
      local actual_x, actual_y, cols, len = m_physics:move(entity, p.x + ox , p.y + oy, entity.body.filter)
      p.x, p.y = actual_x - ox, actual_y - oy
      for j=1, len do
        local col = cols[j]
        if col.other.body and not (ignore[entity] and ignore[entity][col.other]) then
          if not ignore[col.other] then ignore[col.other] = {} end
          ignore[col.other][entity] = true
          if entity.body.type == 'player' and col.other.body.type == 'bump' then
            bumpCollision(entity, col.other, col.normal, col.touch)
          elseif entity.body.type == 'bump' and col.other.body.type == 'player' then
            bumpCollision(col.other, entity, {x = -col.normal.x, y = -col.normal.y}, col.touch)
          else
            if entity.onCollision then entity:onCollision(col.other, col.other.body.type) end
            if col.other.onCollision then col.other:onCollision(entity.body.type) end
          end
        elseif col.other.properties then
          entity:onCollision(col.other, 'tile')
        end
      end
    end
  end
end

function PhysicsSystem.setWorld(map)
  m_physics = Bump.newWorld() 
  map:bump_init(m_physics)
end

function PhysicsSystem.onAdd(entity)
  if entity.body and entity.transform then
    local x, y = entity.transform.position:unpack()
    local w, h = entity.body.size:unpack()
    m_physics:add(entity, x, y, w, h)
  end
end

function PhysicsSystem.onDestroy(entity)
  m_physics:remove(entity)
end

local function getCellRect(world, cx,cy)
  local cellSize = world.cellSize
  local l,t = world:toWorld(cx,cy)
  return l,t,cellSize,cellSize
end

function PhysicsSystem.drawCollision(entities, num_entities)
  local cellSize = m_physics.cellSize
  local font = love.graphics.getFont()
  local fontHeight = font:getHeight()
  local topOffset = (cellSize - fontHeight) / 2
  local r, g, b, a = love.graphics.getColor()
  for cy, row in pairs(m_physics.rows) do
    for cx, cell in pairs(row) do
      local l,t,w,h = getCellRect(m_physics, cx,cy)
      local intensity = cell.itemCount * 12 + 16
      love.graphics.setColor(255,255,255,intensity)
      love.graphics.rectangle('fill', l,t,w,h)
      love.graphics.setColor(255,255,255, 64)
      love.graphics.printf(cell.itemCount, l, t+topOffset, cellSize, 'center')
      love.graphics.setColor(255,255,255,10)
      love.graphics.rectangle('line', l,t,w,h)
    end
  end

  for i=1, num_entities do
    local entity = entities[i]
    if entity.body then
      local p = entity.transform.position
      local o = entity.body.offset
      local s = entity.body.size
      local l, t = (p + o):unpack()
      love.graphics.setColor(255,0,0,70)
      love.graphics.rectangle("fill", l, t, s.x, s.y)
      love.graphics.setColor(255,0,0)
      love.graphics.rectangle("line", l, t, s.x, s.y)
    end
  end
  love.graphics.setColor(r, g, b, a)
end

return PhysicsSystem