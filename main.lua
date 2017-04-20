g_player = {}

local STI = require "lib/sti"
local Gamera = require 'lib/gamera'
local Entity = require 'src/managers/entity'
local Timer = require 'lib/timer'
local Vec2 = require 'lib/vec2'
local UI = require 'src/managers/ui'
local Game = require 'src/game'
local Player = require 'src/entities/player'
local ProFi = require 'lib/profi'
local Gamestate = require 'lib/gamestate'
local InGameState = require 'src/gamestates/ingame'
local addEntity = Entity.add

local debug = false
local pause = false

local INTERNAL_HEIGHT = 480
local scale

local player 
local map
local world = {}
local camera


--https://love2d.org/forums/viewtopic.php?f=4&t=3673&start=20#p99678
function love.run()

  love.math.setRandomSeed( os.time() )
  
  if love.load then love.load(arg) end

  if love.timer then love.timer.step() end --ignore time taken by love.load
  
  local dt = 0
  local accumulator = 0
  
  -- Main loop
  while true do
  
    -- Process events.
    if love.event then
      love.event.pump()
      for e,a,b,c,d in love.event.poll() do
        if e == "quit" then
          if not love.quit or not love.quit() then
            if love.audio then love.audio.stop() end
            return
          end
        end
        love.handlers[e](a,b,c,d)
      end
    end
        
    -- Update dt for any uses during this timestep of love.timer.getDelta
    if love.timer then 
      love.timer.step()
      dt = love.timer.getDelta()
    end

    --local fixedTimestep = 1/60
    
    if fixedTimestep then       
      -- see http://gafferongames.com/game-physics/fix-your-timestep  
      
      if dt > 0.25 then      
        dt = 0.25 -- note: max frame time to avoid spiral of death
      end     
      
      accumulator = accumulator + dt
      --_logger:debug("love.run - acc=%f fts=%f", accumulator, fixedTimestep) 

      while accumulator >= fixedTimestep do
        if love.update then love.update(fixedTimestep) end
        accumulator = accumulator - fixedTimestep
      end
      
    else
      -- no fixed timestep in place, so just update
      -- will pass 0 if love.timer is disabled
      if love.update then love.update(dt) end 
    end
    
    -- draw
    if love.graphics then
      love.graphics.clear()
      if love.draw then love.draw() end
      if love.timer then love.timer.sleep(0.001) end
      love.graphics.present()
    end 
  end
end

function love.load()
  Game.INTERNAL_HEIGHT = 480
  love.graphics.setDefaultFilter("nearest","nearest")
  scale = love.graphics.getHeight() / INTERNAL_HEIGHT
  Game.scale = scale
  Gamestate.registerEvents()
  Gamestate.switch(InGameState)
  
end
    
local code =  [[
extern vec3 iResolution;
extern number iGlobalTime;
extern vec2 offset;

void mainImage( out vec4 fragColor, in vec2 fragCoord )
{
	  vec2 uv = fragCoord.xy / iResolution.xy;
    vec2 original = uv;
    vec2 old = uv;
    uv = fract(uv + offset);
    number n = 6.0;
    number off = uv.y * n;
    uv = fract(uv * n);
    if (mod(off, 2.0) < 1.0) 
    	uv.x = fract(uv.x - mod(iGlobalTime * 0.5, 10.0));
    else {
        uv.x = fract(uv.x + mod(iGlobalTime * 0.5, 10.0));
        old.x = 1.0 - old.x;
    }
    number scale = iResolution.x / iResolution.y;
    number resolution = 1000.0;
    number height = resolution;
    number width = resolution * scale;
    vec2 dim = vec2(width, height) / n;
    dim *= 1.2;
    vec2 center = dim * 0.5;
    number radius = 0.475 * (resolution / n);
    if (distance(uv * dim, center) < radius)
		    fragColor = vec4(uv, sin(old.x),1.0);
   	else
        fragColor = vec4(0.0, 0.0, 0.0 + sin(iGlobalTime)* 0.1, 1.0);
}

vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 pixel_coords){
    vec2 fragCoord = texture_coords * iResolution.xy;
    mainImage( color, fragCoord );
    return color;
}]]

function Game.loadMap(level, id)
  local player = Game.player
  local map = STI("assets/maps/"..level..".lua", {"bump"})
  Game.map = map
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
  local camera = Gamera.new(0, 0, map.width * map.tilewidth, map.height * map.tileheight)
  camera:setScale(Game.scale)
  camera:setPosition(player.Transform.position.x, player.Transform.position.y)
  Game.camera = camera
  return map, camera
end