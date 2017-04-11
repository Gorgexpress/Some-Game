local PhysicsSystem = require 'src/systems/physics'
local VelocitySystem = require 'src/systems/velocity'
local Signal = require 'lib/signal'
local FileSystem = love.filesystem
local ENTITIES_PATH = 'src/entities/'
local EntityManager = {}
local m_entities = {}
local m_size = 0
local m_capacity = 0


function EntityManager.add(entity, args)
  if type(entity) == 'string' then
    local path = ENTITIES_PATH .. entity
    --if file not found in given path, search for it recursively in all directories in the entities folder
    if not FileSystem.exists(path..'.lua') then 
      path = EntityManager.findEntity(ENTITIES_PATH, entity, 0)
      if not path then
        return print("Could not find Entity "..entity)
      end
    end
    local class = require(path)
    entity = class.new(args)
  end
  m_size = m_size + 1
  if m_size >  m_capacity then m_capacity = m_size end 
  m_entities[m_size] = entity
  PhysicsSystem.onAdd(entity)  
  return entity
end

--Recursively search for entity in subdirectories. Return path to entity(minus the .lua) if it is found
--Otherwise, return nil. 
--Quits and return nil if subdirectory depth is greater than 4 relative to the original folder
function EntityManager.findEntity(path, entity, depth) 
  if FileSystem.exists(path..entity..'.lua') then
    return path..(entity:gsub('.lua', ''))
  end
  if depth > 4 then return nil end
  local file_table = FileSystem.getDirectoryItems(path)
  for i, v in ipairs(file_table) do
    local file = path .. v
    if FileSystem.isDirectory(file) then
      local path_of_entity = EntityManager.findEntity(path..v..'/', entity)
      if path_of_entity then 
        return path_of_entity
      end
    end
  end
  return nil
end

--[[TODO? I didn't think of this at first but I can just store entities in a table 
mapping the table reference to the table itself. Use pairs() to iterate, delete by
setting table values to nil. Not as efficient, but easier and cleaner]]
function EntityManager.update(dt)
  local entities_to_destroy = {}
  local num_to_destroy = 0
  --call update function
  for i=1, m_size do
    if m_entities[i].update then m_entities[i]:update(dt) end 
  end
  --if entity is flagged for destruction, add it to array of entities to destroy
  --otherwise update state
  for i=1, m_size do
    if m_entities[i].destroyed then 
      num_to_destroy = num_to_destroy + 1
      entities_to_destroy[num_to_destroy] = i
    else
      if m_entities[i].animator then m_entities[i].animator.current:update(dt) end
      --if entity.render then entity.render.animations[entity.state.frame.sprite][entity.render.dir]:update(dt) end
    end
  end
  --destroy entities if needed. We do this by swapping them with the last element in the array and setting their value to nil
  for i=num_to_destroy, 1, -1 do
    local index = entities_to_destroy[i]
    PhysicsSystem.onDestroy(m_entities[index])
    Signal.emit('destroyed', m_entities[index])
    m_entities[index] = m_entities[m_size]
    m_entities[m_size] = nil
    m_size = m_size - 1
  end
  --for the rest of the function, the entities we work on are guaranteed to not be nil or flagged for destruction
  --update physics
  VelocitySystem.update(m_entities, m_size, dt)
  PhysicsSystem.update(m_entities, m_size, dt)
end

function EntityManager.setWorld(world)
  PhysicsSystem.setWorld(world)
end

function EntityManager.registerBody(entity)
  PhysicsSystem.onAdd(entity)
end

function EntityManager.unregisterBody(entity)
  PhysicsSystem.onDestroy(entity)
end

function EntityManager.drawCollision()
  PhysicsSystem.drawCollision(m_entities, m_size)
end

EntityManager.entities = m_entities

return EntityManager