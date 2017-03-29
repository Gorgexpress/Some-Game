local PhysicsSystem = require 'src/systems/physics-system'
local VelocitySystem = require 'src/systems/velocity-system'
local EntityManager = {}
local m_entities = {}
local m_size = 0
local m_capacity = 0


function EntityManager.add(entity, args)
  if type(entity) == 'string' then
    local name = 'src/entities/' .. entity
    local class = require(name)
    entity = class.new(args)
  end
  m_size = m_size + 1
  if m_size >  m_capacity then m_capacity = m_size end 
  m_entities[m_size] = entity
  PhysicsSystem.onAdd(entity)  
  return entity
end

function EntityManager.update(dt)
  local entities_to_destroy = {}
  local num_to_destroy = 0
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
  for i=1, num_to_destroy do
    local index = entities_to_destroy[i]
    PhysicsSystem.onDestroy(m_entities[index])
    m_entities[index] = m_entities[m_size]
    m_entities[m_size] = nil
    m_size = m_size - 1
  end
  --for the rest of the function, the entities we work on are guaranteed to not be nil or flagged for destruction
  --update physics
  VelocitySystem.update(m_entities, m_size, dt)
  PhysicsSystem.update(m_entities, m_size, dt)
  --update ai
  for i=1, m_size do
    if m_entities[i].update then m_entities[i]:update(dt) end 
  end
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