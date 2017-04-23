local PhysicsSystem = require 'src/systems/physics'
local VelocitySystem = require 'src/systems/velocity'
local ChildSystem = require 'src/systems/child'
local Signal = require 'lib/signal'
local ENTITIES_PATH = 'src/entities/'
local _ff = require('lib/FileFinder').new(5, ENTITIES_PATH, {'lua'})
local EntityManager = {}
local _entities = {}
local _size = 0
local _capacity = 0




function EntityManager.add(entity, ...)
  if type(entity) == 'string' then
    local path = ENTITIES_PATH .. entity
    --if file not found in given path, search for it recursively in all directories in the entities folder
    path = _ff:find(entity)
    if not path then return nil end
    local class = require(path)
    entity = class.new(...)
  end
  _size = _size + 1
  if _size >  _capacity then _capacity = _size end 
  _entities[_size] = entity
  PhysicsSystem.onAdd(entity)  
  return entity
end


--[[TODO? I didn't think of this at first but I can just store entities in a table 
mapping the table reference to the table itself. Use pairs() to iterate, delete by
setting table values to nil. Not as efficient, but easier and cleaner]]
function EntityManager.update(dt)

  local entities_to_destroy = {}
  local num_to_destroy = 0
  --call update function
  for i=1, _size do
    if _entities[i].update then _entities[i]:update(dt) end 
  end
  --if entity is flagged for destruction, add it to array of entities to destroy
  --otherwise update state
  for i=1, _size do
    if _entities[i].destroyed then 
      num_to_destroy = num_to_destroy + 1
      entities_to_destroy[num_to_destroy] = i
    else
      if _entities[i].animator then _entities[i].animator.current:update(dt) end
      --if entity.render then entity.render.animations[entity.state.frame.sprite][entity.render.dir]:update(dt) end
    end
  end
  --destroy entities if needed. We do this by swapping them with the last element in the array and setting their value to nil
  for i=num_to_destroy, 1, -1 do
    local index = entities_to_destroy[i]
    PhysicsSystem.onDestroy(_entities[index])
    Signal.emit('destroyed', _entities[index])
    _entities[index] = _entities[_size]
    _entities[_size] = nil
    _size = _size - 1
  end
  --for the rest of the function, the entities we work on are guaranteed to not be nil or flagged for destruction
  --Update systems. Order is important! 
  VelocitySystem.update(_entities, _size, dt)
  ChildSystem.update(_entities, _size, dt)
  PhysicsSystem.update(_entities, _size, dt)
end

function EntityManager.setWorld(world)
  for i=1, _capacity do 
    _entities[i] = nil
  end
  _size = 0
  PhysicsSystem.setWorld(world)
end

function EntityManager.registerBody(entity)
  PhysicsSystem.onAdd(entity)
end

function EntityManager.unregisterBody(entity)
  PhysicsSystem.onDestroy(entity)
end

function EntityManager.drawCollision()
  PhysicsSystem.drawCollision(_entities, _size)
end

--does not clear physics
function EntityManager.clear()
  for i=1, _capacity do 
    _entities[i] = nil
  end
  _size = 0
end

EntityManager.entities = _entities
return EntityManager