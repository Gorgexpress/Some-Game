local Bump = require 'lib/bump'
local vec2 = require 'lib/vec2'
local FRICTION = 1500


local VelocitySystem = {}



function VelocitySystem.update(entities, num_entities, dt)
  for i=1, num_entities do
    local entity = entities[i]
    if entity.velocity and entity.transform then 
      local entity = entities[i]
      local p, v = entity.transform.position, entity.velocity
      local d = v.frictionless.direction * v.frictionless.magnitude * dt
      if v.magnitude then
        d = d + v.direction * v.magnitude * dt 
        v.magnitude = v.magnitude - FRICTION * dt
        if v.magnitude <= 0 then v.magnitude = nil end
      end
      entity.transform.position = p + d 
    end
  end
end



return VelocitySystem