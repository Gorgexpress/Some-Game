g_player = {}

local sti = require "lib/sti"
local gamera = require 'lib/gamera'
local Entity = require 'src/managers/entity'
local Timer = require 'lib/timer'
local Vec2 = require 'lib/vec2'
local UI = require 'src/managers/ui'
local Game = require 'src/game'
local Player = require 'src/entities/player'
local addEntity = Entity.add
local debug = false
local pause = false


local INTERNAL_HEIGHT = 768
local scale

local player 
local map
local world = {}
local camera

function love.load()
  player = Player({position = Vec2(500, 500)})
  g_player = player
  Game.player = player
  scale = love.graphics.getHeight() / INTERNAL_HEIGHT
  loadMap('101')
  --Entity.add('enemies/bump', {position = Vec2(map.layers.Sprite.objects[1].x, map.layers.Sprite.objects[1].y + 400)})
  --Entity.add('enemies/ranged', {position = Vec2(map.layers.Sprite.objects[1].x + 500, map.layers.Sprite.objects[1].y)})
  --Entity.add('enemies/bosses/boss1', {position = Vec2(map.layers.Sprite.objects[1].x, map.layers.Sprite.objects[1].y - 250)})
  love.graphics.setDefaultFilter("nearest","nearest")
  scale = love.graphics.getHeight() / INTERNAL_HEIGHT
end

function loadMap(level, id)
  map = sti("assets/maps/"..level..".lua", {"bump"})
  world.width = map.width * map.tilewidth
  world.height = map.height * map.tileheight
  Entity.setWorld(map)
  --TODO make triggers a separate layer
  for k, v in ipairs(map.layers.Sprite.objects) do
    if v.properties.entity then
      addEntity(v.properties.entity, {position = Vec2(v.x, v.y)})
    end
    if v.properties.entrance and v.properties.entrance == id then
      player.Transform.position = Vec2(v.x, v.y)
    end
  end
  addEntity(player)
  for k, v in ipairs(map.layers.Sprite.objects) do
    if v.properties.exitmap then
      addEntity('triggers/exit', {position = Vec2(v.x, v.y), size = Vec2(v.width, v.height), exitmap = v.properties.exitmap, exitid = v.properties.exitid})
    end
  end
  map.layers.Sprite = nil
  camera = gamera.new(0, 0, world.width, world.height)
  camera:setScale(scale)
  camera:setPosition(player.Transform.position.x, player.Transform.position.y)
end
    
function love.update(dt)
  if pause then return end
  Entity.update(dt)
  Timer.update(dt)
end

local function cameraDraw(l, t, w, h)
  map:setDrawRange(l, t, w, h)
  map:draw()
  for _, entity in ipairs(Entity.entities) do
    entity:draw()
  end
  if debug then Entity.drawCollision() end
end

function love.draw()
  camera:setPosition(player.Transform.position.x, player.Transform.position.y) 
  camera:draw(cameraDraw)
  UI.draw(player)
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
  ['combo'] = function() player:action1() end,
  ['combo2'] = function() player:action2() end,
  ["debug"] = function() debug = not debug end,
  ["pause"] = function() pause = not pause end,
}

function movement()
  local uvx, uvy = 0, 0

  if input_state['up'] then uvy = uvy -1 end
  if input_state['right'] then uvx = uvx + 1 end 
  if input_state['down'] then uvy = uvy + 1 end
  if input_state['left'] then uvx = uvx - 1 end
  player:move(uvx, uvy)
end


function love.keypressed(key)
  local action = ''
  if key == "w" then action = 'up'
  elseif key == 's' then action = 'down'
  elseif key == 'a' then action = 'left'
  elseif key == 'd' then action = 'right'
  elseif key == 'space' then action = 'combo'
  elseif key == 'n' then action = 'debug'
  elseif key == 'p' then action = 'pause'
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

function love.gamepadpressed(joystick, button)
  local action = ''
  if button == "dpup" then action = 'up'
  elseif button == 'dpdown' then action = 'down'
  elseif button == 'dpright' then action = 'right'
  elseif button == 'dpleft' then action = 'left'
  elseif button == 'a' then action = 'combo'
  elseif button == 'back' then action = 'debug'
  elseif button == 'start' then action = 'pause'
  end
  if actions[action] then
    input_state[action] = not input_state[action]
    actions[action]()
  end
end

function love.gamepadreleased(joystick, button)
  local action = ''
  if button == "dpup" then action = 'up'
  elseif button == 'dpdown' then action = 'down'
  elseif button == 'dpright' then action = 'right'
  elseif button == 'dpleft' then action = 'left'
  elseif button == 'a' then action = 'combo2'
  end
  if actions[action] then
    input_state[action] = not input_state[action]
    actions[action]()
  end
end