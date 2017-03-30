g_player = {}

local sti = require "lib/sti"
local gamera = require 'lib/gamera'
local Entity = require 'src/managers/entity-manager'
local Timer = require 'lib/timer'
local Vec2 = require 'lib/vec2'

function love.load()
  map = sti("assets/maps/test.lua", {"bump"})
  local world = {}
  world.width = map.width * map.tilewidth
  world.height = map.height * map.tileheight
  Entity.setWorld(map)

  g_player = Entity.add('player', {position = Vec2(map.layers.Sprite.objects[1].x, map.layers.Sprite.objects[1].y)})
  Entity.add('bump-base', {position = Vec2(map.layers.Sprite.objects[1].x, map.layers.Sprite.objects[1].y + 400)})
  Entity.add('ranged-base', {position = Vec2(map.layers.Sprite.objects[1].x + 500, map.layers.Sprite.objects[1].y)})
  camera = gamera.new(0, 0, world.width, world.height)
  camera:setPosition(g_player.transform.position.x, g_player.transform.position.y)
end
    
function love.update(dt)
  Entity.update(dt)
  Timer.update(dt)
end

function love.draw()
  camera:setPosition(g_player.transform.position.x, g_player.transform.position.y) 
  camera:draw(function(l, t, w, h)
    map:setDrawRange(l, t, w, h)
    map:draw()
    for _, entity in ipairs(Entity.entities) do
      entity:draw()
    end
    Entity.drawCollision()
  end)
  love.graphics.print("Current FPS: "..tostring(love.timer.getFPS( )), 10, 10)
end


--input--

local input_state = {
  ['up'] = false,
  ['left'] = false,
  ['down'] = false,
  ['right'] = false,
  ['combo'] = false,
}
  
local actions = {
  ["up"] = function() movement() end,
  ["left"] = function() movement() end,
  ["down"] = function() movement() end,
  ["right"] = function() movement() end,
  ['combo'] = function() g_player:action1() end,
}

function movement()
  local uvx, uvy = 0, 0

  if input_state['up'] then uvy = uvy -1 end
  if input_state['right'] then uvx = uvx + 1 end 
  if input_state['down'] then uvy = uvy + 1 end
  if input_state['left'] then uvx = uvx - 1 end
  g_player:move(uvx, uvy)
end


function love.keypressed(key)
  local action = ''
  if key == "w" then action = 'up'
  elseif key == 's' then action = 'down'
  elseif key == 'a' then action = 'left'
  elseif key == 'd' then action = 'right'
  elseif key == 'space' then action = 'combo'
  end
  if actions[action] then
    input_state[action] = not input_state[action]
    actions[action]()
  end
end

function love.keyreleased(key)
  local action = ''
  if key == "w" then action = 'up'
  elseif key == 's' then action = 'down'
  elseif key == 'a' then action = 'left'
  elseif key == 'd' then action = 'right'
  elseif key == 'space' then action = 'combo2'
  end
  if actions[action] then
    input_state[action] = not input_state[action]
    actions[action]()
  end
end