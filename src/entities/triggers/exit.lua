local Game = require 'src/game'
local Vec2 = require 'lib/vec2'


local Entity = {}
local Entity_mt = {}


local function filter(self, other)
  if other ~= Game.player then return nil end
  return 'cross'
end

local function filterOnSpawn(other)
  if other ~= Game.player then return nil end
  return 'cross'
end

local function isPlayerColliding(self)
  local _, len = Game.physics.queryRect(self.Transform.position.x, self.Transform.position.y, self.Body.size.x, self.Body.size.y, filterOnSpawn)
  return len == 0 
end

function Entity.onCollision(self, other, type)
  if other ~= Game.player or not self.active then return nil end
  loadMap(self.exitmap, self.exitid)
  return true
end

local function update(self, dt)
  if not isPlayerColliding(self) then
    self.active = true
    self.update = nil
  end
end

function Entity.draw(self)
  
end

function Entity.new(args) 
  local transform = {
    position = args.position or Vec2(0, 0),
    forward = Vec2(0, -1),
  }
  local body = args.body or {
    size = args.size or Vec2(1, 1),
    offset = Vec2(0, 0),
    filter = filter,
    type = 'tile',
  }

  local entity = {
    Transform = transform,
    Body = body,
    exitid = args.exitid,
    exitmap = args.exitmap,
    active = true,
  }
  --
  if isPlayerColliding(entity) then
    entity.active = false
    entity.update = update
  end
  return setmetatable(entity, Entity_mt)
end

Entity_mt.__index = Entity

function Entity_mt.__call(_, args)
    return Entity.new(args)
end

return setmetatable({}, Entity_mt)