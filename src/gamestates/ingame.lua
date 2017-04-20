local Game = require 'src/game'
local Entity = require 'src/managers/entity'
local UI = require 'src/managers/ui'
local Player = require 'src/entities/player'
local Timer = require 'lib/timer'
local Vec2 = require 'lib/vec2'
local State = {}

local _pause = false
local _debug = false

local _player
local _camera
local _scale
local _map


local _input_state = {
  ['up'] = false,
  ['left'] = false,
  ['down'] = false,
  ['right'] = false,
  ['action1'] = false,
}

function State:enter()
  _player = Player({position = Vec2(500, 500)})
  g_player = _player
  Game.player = _player
  _scale = love.graphics.getHeight() / Game.INTERNAL_HEIGHT
  Game.scale = _scale
  _map, _camera = Game.loadMap('101')
  love.graphics.setDefaultFilter("nearest","nearest")
  Game.time = 0
  Game.input_state = _input_state
end

function State:update(dt)
  Game.time = Game.time + dt
  if _pause then return end
  Entity.update(dt)
  Timer.update(dt)
end

--local canvas = love.graphics.newCanvas(love.graphics.getDimensions())
local function cameraDraw(l, t, w, h)
  Game.map:setDrawRange(l, t, w, h)
  Game.map:draw()
  for _, entity in ipairs(Entity.entities) do
    entity:draw()
  end
  if _debug then Entity.drawCollision() end
end

function State:draw()
 --[[shader:send('iResolution', { love.graphics.getWidth(), love.graphics.getHeight(), 1 })
  shader:send('iGlobalTime', Game.time)
  local x, y = camera:getPosition()
  shader:send('offset', {x / 3000, y / 3000})
  love.graphics.setShader(shader)
  love.graphics.draw(canvas)
  love.graphics.setShader()
  love.graphics.setCanvas()
  love.graphics.draw(canvas,0,0)]]
  Game.camera:setPosition(_player.Transform.position.x, _player.Transform.position.y) 
  Game.camera:draw(cameraDraw)
  UI.draw(_player)
  love.graphics.print("Current FPS: "..tostring(love.timer.getFPS( )), 10, 10)
end


--input--
  
local _actions = {
  ["up"] = function() _player:move() end,
  ["left"] = function() _player:move() end,
  ["down"] = function() _player:move() end,
  ["right"] = function() _player:move() end,
  ['action1'] = function() _player:action1() end,
  ['action2'] = function() _player:action2() end,
  ["debug"] = function() _debug = not _debug end,
  ["pause"] = function() _pause = not _pause end,
}

function State:keypressed(key)
  local action = ''
  if key == "w" then action = 'up'
  elseif key == 's' then action = 'down'
  elseif key == 'a' then action = 'left'
  elseif key == 'd' then action = 'right'
  elseif key == 'space' then action = 'action1'
  elseif key == 'n' then action = 'debug'
  elseif key == 'p' then action = 'pause'
  end
  if _actions[action] then
    _input_state[action] = true
    _actions[action]()
  end
end

function State:keyreleased(key)
  local action = ''
  if key == "w" then action = 'up'
  elseif key == 's' then action = 'down'
  elseif key == 'a' then action = 'left'
  elseif key == 'd' then action = 'right'
  elseif key == 'space' then action = 'action2'
  end
  if _actions[action] then
    _input_state[action] = false
    _actions[action]()
  end
end

function State:gamepadpressed(joystick, button)
  local action = ''
  if button == "dpup" then action = 'up'
  elseif button == 'dpdown' then action = 'down'
  elseif button == 'dpright' then action = 'right'
  elseif button == 'dpleft' then action = 'left'
  elseif button == 'a' then action = 'action1'
  elseif button == 'back' then action = 'debug'
  elseif button == 'start' then action = 'pause'
  end
  if _actions[action] then
    _input_state[action] = true
    _actions[action]()
  end
end

function State:gamepadreleased(joystick, button)
  local action = ''
  if button == "dpup" then action = 'up'
  elseif button == 'dpdown' then action = 'down'
  elseif button == 'dpright' then action = 'right'
  elseif button == 'dpleft' then action = 'left'
  elseif button == 'a' then action = 'action2'
  end
  if _actions[action] then
    _input_state[action] = false
    _actions[action]()
  end
end

return State