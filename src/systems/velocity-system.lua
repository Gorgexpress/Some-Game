local Bump = require 'lib/bump'
local vec2 = require 'lib/vec2'


local VelocitySystem = {}



function VelocitySystem.update(entities, num_entities, dt)
  for i=1, num_entities do
    local entity = entities[i]
    if entity.velocity and entity.transform then 
      local entity = entities[i]
      local p, v = entity.transform.position, entity.velocity
      local dx, dy = v.x * dt, v.y * dt
      p.x, p.y = p.x + dx, p.y + dy
    end
  end
end



return VelocitySystem