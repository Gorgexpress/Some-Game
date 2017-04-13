local Bump = require 'lib/bump'
local Game = require 'src/game'
local vec2 = require 'lib/vec2'
local Vec2l = require 'lib/vector-light'
local dot = Vec2l.dot
local PolygonCollision = require 'lib/polygon-collision'
local acos, abs, min = math.acos, math.abs, math.min

local m_physics

local PhysicsSystem = {}


local function bumpCollision2(self, other, normal)
  --player always loses if idle
  if self.state == 'idle' then
    self:onCollision(other, 'bumped')
    other:onCollision(self, 'bumper')
    return
  end
  --We want the signed angle between two vectors, with the vectors being a forward vector extending
  --from the corresponding entity's position
  local p1 = self.center
  local p2 = (other.Transform.position + other.Body.offset + other.Body.size * 0.5) 
  local t1 = p1 * self.Transform.forward
  local t2 = p2 * other.Transform.forward
  local between = math.atan2(t2.y, t2.x) - math.atan2(t1.y, t1.x)
  if between > math.pi then between = between - math.pi * 2
  elseif between < -math.pi then between = between + math.pi * 2
  end
  local moe = 2
  --[[case 0: has already been handled. The player being idle is a special case where they always lose.
  case 1: if between roughly equals math.pi or -math.pi, head on collision
  case 2: between == 0, someone was hit in the back. Who wins depends on the player's forward, the normal, and 
  the difference between the entities' positions. The dot multiplication below is only to extract the necessary
  value without an if statement. normal and forward will always have one axis set to 0.
  case 3: if other cases arent met, someone was hit in the side. As mentioned before, only one value in the normal
  and forward 2d vectors will be set. If someone was hit in the side, then which axis is set will be different
  between the two entities' forwards. The winner is the one whos' forward has the same axis set as the collision normal]]
  if math.abs(between) > math.abs(math.pi - 0.5) then --head on
    --[[Imagine a ray is sent forward from the center of the player, in the direction the player is facing. 
    If that ray hits the enemy, the player is hurt. If it does not, then the player succeeds in damaging the enemy.
    A variable  called "moe"(margin of error, not the japanese moe) is added to the comparisons. A positive value indicates
    how many pixels into the enemy's hitbox is allowed before the attack becomes unsuccesful. A negative value will do the opposite
    and make things harder.]]
    local axis = normal.x ~= 0 and 'x' or 'y'
    if p1[axis] <= other.Transform.position[axis] + moe or 
    p1[axis] >= other.Transform.position[axis] + other.Body.offset[axis] + other.Body.size[axis] - moe then
      self:onCollision(other, 'bumper')
      other:onCollision(self, 'bumped')
    else
      self:onCollision(other, 'bumped')
      other:onCollision(self, 'bumper') 
    end
  elseif between == 0 then -- backside hit
    local d = p2 - p1
    d.x, d.y = d.x * normal.x, d.y * normal.y
    local sum = dot(normal.x, normal.y, 1, 1) - dot(self.Transform.forward.x, self.Transform.forward.y, 1, 1)
    if sum ~= 0 then
      self:onCollision(other, 'bumped')
      other:onCollision(self, 'bumper')
    else
      self:onCollision(other, 'bumper')
      other:onCollision(self, 'bumped')
    end
  else --side hit
    if math.abs(normal.x) == math.abs(self.Transform.forward.x) or math.abs(normal.y) == math.abs(self.Transform.forward.y) then
      self:onCollision(other, 'bumped')
      other:onCollision(self, 'bumper')
    else
      self:onCollision(other, 'bumper')
      other:onCollision(self, 'bumped')
    end
  end
end


--TODO? move this into player.lua or a utility function.
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

EDIT: Head on collision results now determined by a trajectory. If a line
that infinitely extends from the center of the player on the axis of least seperation
does NOT collide with the enemy, then the player succeeds. Otherwise, the player is hurt.
Old code for head on collision commented out. New code only works for the case
where entities can only face 4 directions(which they currently do and i have no plans of change that right now).

Still would like a cleaner way to determine the results of non head on collisions.

]]
local function bumpCollision(self, other, normal, touch)
  --player always loses if idle
  if self.state == 'idle' then
    self:onCollision(other, 'bumped')
    other:onCollision(self, 'bumper')
    return
  end
  local p1, p2 = self.Transform.position + self.Body.offset, other.Transform.position + other.Body.offset
  local f1, f2 = self.Transform.forward, other.Transform.forward
  local s1, s2 = self.Body.size, other.Body.size
  local depth_hit = 16
  local safe = 2
  if normal.y == -1 or normal.y == 1 then
    if f1.y == -f2.y then
      local x = self.center.x
      if x <= p2.x + safe or x >= p2.x + s2.x - safe then
        self:onCollision(other, 'bumper')
        other:onCollision(self, 'bumped')
      else
        self:onCollision(other, 'bumped')
        other:onCollision(self, 'bumper') 
      end
      --[[if p1.x < p2.x and p1.x + s1.x > p2.x + s2.x then
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
      ]]
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
      local y = self.center.y
      if y <= p2.y + safe or y >= p2.y + s2.y - safe then
        self:onCollision(other, 'bumper')
        other:onCollision(self, 'bumped')
      else
        self:onCollision(other, 'bumped')
        other:onCollision(self, 'bumper') 
      end
      --[[
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
      end]]
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
    if entity.Body then
      local p = entity.Transform.position
      local old_x, old_y = p:unpack() --for debugging
      local ox, oy = entity.Body.offset:unpack()
      local actual_x, actual_y, cols, len = m_physics:move(entity, p.x + ox , p.y + oy, entity.Body.filter)
      p.x, p.y = actual_x - ox, actual_y - oy
      for j=1, len do
        local col = cols[j]
        if col.other.Body and not (ignore[entity] and ignore[entity][col.other]) then --aabb vs aabb or aabb vs swept shape collision
          if not ignore[col.other] then ignore[col.other] = {} end
          ignore[col.other][entity] = true
          if entity.Body.type == 'player' and col.other.Body.type == 'bump' then
            bumpCollision(entity, col.other, col.normal, col.touch)
          elseif entity.Body.type == 'bump' and col.other.Body.type == 'player' then
            bumpCollision(col.other, entity, {x = -col.normal.x, y = -col.normal.y}, col.touch)
          elseif entity.Body.polygon or col.other.Body.polygon then --aabb has collided with a polygon's swept shape
            if old_x ~= p.x or old_y ~= p.y then
              print("Swept shape might have caused an illegal collision response!")
            end
            local collided = false
            --convert the aabb to a set of vertices and test for collision
            if col.other.Body.polygon then --collided with swept shape
              local w, h = entity.Body.size:unpack()
              vertices = {actual_x, actual_y, actual_x + w, actual_y, actual_x + w, actual_y + h, actual_x, actual_y + h}
              collided = PolygonCollision(vertices, col.other.Body.polygon)
            else --the entity we just moved is the polygon surrounded by a swept shape
              local x, y = (col.other.Transform.position + col.other.Body.offset):unpack()
              local w, h = col.other.Body.size:unpack()
              vertices = {x, y, x + w, y, x + w, y + h, x, y + h}
              collided = PolygonCollision(vertices, entity.Body.polygon)
            end
            if collided then
              if entity.onCollision then entity:onCollision(col.other, col.other.Body.type) end
              if col.other.onCollision then col.other:onCollision(entity, entity.Body.type) end
            end
          --end aabb vs polygon code
          else --only standard aabb vs aabb collisions remain at this point
            if entity.onCollision then 
            local exit = entity:onCollision(col.other, col.other.Body.type) 
              if exit then return end
            end
            if col.other.onCollision then 
              --TODO handle level change triggers somewhere else
              local exit = col.other:onCollision(entity, entity.Body.type)
              if exit then return end 
            end
          end
        elseif col.other.properties then --tile collision. 
          --aabb vs tile
          if not entity.Body.polygon then
            entity:onCollision(col.other, 'tile')
          --polygon vs tile
          else
            local x, y = col.other.x, col.other.y
            local w, h = col.other.width, col.other.height
            vertices = {x, y, x + w, y, x + w, y + h, x, y + h}
            if PolygonCollision(vertices, entity.Body.polygon) then
              entity:onCollision(col.other, 'tile')
            end
          end
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
  if entity.Body and entity.Transform then
    local x, y = entity.Transform.position:unpack()
    local w, h = entity.Body.size:unpack()
    m_physics:add(entity, x, y, w, h)
  end
end

function PhysicsSystem.onDestroy(entity)
  if entity.Body then
    m_physics:remove(entity)
  end
end

function PhysicsSystem.clear()
  m_physics = nil
end

function PhysicsSystem.updateRectSize(entity, width, height)
  m_physics:update(entity, entity.Transform.position.x, entity.Transform.position.y, width, height)
end
--methods for drawing hitboxes and such for debugging purposes below
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
--[[
  for i=1, num_entities do
    local entity = entities[i]
    if entity.Body then
      local p = entity.Transform.position
      local o = entity.Body.offset
      local s = entity.Body.size
      local l, t = (p + o):unpack()
      love.graphics.setColor(255,0,0,70)
      love.graphics.rectangle("fill", l, t, s.x, s.y)
      love.graphics.setColor(255,0,0)
      love.graphics.rectangle("line", l, t, s.x, s.y)
    end
  end
  ]]
  for i, v in pairs(m_physics.rects) do
    if v then
      love.graphics.setColor(255,0,0,70)
      love.graphics.rectangle("fill", v.x, v.y, v.w, v.h)
      love.graphics.setColor(255,0,0)
      love.graphics.rectangle("line", v.x, v.y, v.w, v.h)
    end
  end
  love.graphics.setColor(r, g, b, a)
end

function PhysicsSystem.queryRect(x1, y1, x2, y2, filter)
  return m_physics:queryRect(x1, y1, x2, y2, filter)
end

function PhysicsSystem.querySegment(x1, y1, x2, y2, filter)
  return m_physics:querySegment(x1, y1, x2, y2, filter)
end

Game.physics = PhysicsSystem

return PhysicsSystem