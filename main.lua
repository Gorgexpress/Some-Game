g_player = {}

local sti = require "lib/sti"
local gamera = require 'lib/gamera'
local Entity = require 'src/managers/entity'
local Timer = require 'lib/timer'
local Vec2 = require 'lib/vec2'
local UI = require 'src/managers/ui'
local Game = require 'src/game'
local Player = require 'src/entities/player'
local ProFi = require 'lib/profi'
local addEntity = Entity.add
local debug = false
local pause = false

local INTERNAL_HEIGHT = 480
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
  --readd player to the entity system. The player's child entities need to be readded too.
  addEntity(player)
  addEntity(player.ps)
  --triggers need to be added last. They check if an entity has spawned on top of them, so they can deactive until the entity moves off.
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
    
local code =  [[
extern vec3 iResolution;
extern number iGlobalTime;


void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
	vec2 uv = fragCoord.xy / iResolution.xy;
    vec2 original = uv;
    vec2 old = uv;
    number n = 5.0;
    number off = uv.y * n;
    uv = fract(uv * n);
    if (mod(off, 2.0) < 1.0) 
    	uv.x = fract(uv.x - mod(iGlobalTime * 0.75, 10.0));
    else {
        uv.x = fract(uv.x + mod(iGlobalTime * 0.75, 10.0));
        old.x = 1.0 - old.x;
    }
    number scale = iResolution.x / iResolution.y;
    number resolution = 1000.0;
    number height = resolution;
    number width = resolution * scale;
    vec2 dim = vec2(width, height) / n;
    vec2 center = dim * 0.5;
    number radius = 0.45 * (resolution / n);
    if (distance(uv * dim, center) < radius)
		fragColor = vec4(uv, sin(old.x),1.0);
   	else
        fragColor = vec4(original, 0.5 + sin(iGlobalTime)* 0.5, 0.0);
}

vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 pixel_coords){
    vec2 fragCoord = texture_coords * iResolution.xy;
    mainImage( color, fragCoord );
    return color;
}]]

Game.time = 0

local shader = love.graphics.newShader(code)
function love.update(dt)
  Game.time = Game.time + dt
  if pause then return end
  Entity.update(dt)
  Timer.update(dt)
end
local canvas = love.graphics.newCanvas(love.graphics.getDimensions())
local function cameraDraw(l, t, w, h)
  map:setDrawRange(l, t, w, h)
    love.graphics.draw(canvas,0,0)
    map:draw()
  for _, entity in ipairs(Entity.entities) do
    entity:draw()
  end
  if debug then Entity.drawCollision() end
end

function love.draw()
  shader:send('iResolution', { love.graphics.getWidth(), love.graphics.getHeight(), 1 })
  shader:send('iGlobalTime', Game.time)
  love.graphics.setShader(shader)
  love.graphics.draw(canvas)
  love.graphics.setShader()
  love.graphics.setCanvas()
  love.graphics.draw(canvas,0,0)
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