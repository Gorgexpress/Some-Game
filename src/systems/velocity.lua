local VelocitySystem = {}



function VelocitySystem.update(entities, num_entities, dt)
  for i=1, num_entities do
    local entity = entities[i]
    if entity.Velocity and entity.Transform then 
      local entity = entities[i]
      local p, v = entity.Transform.position, entity.Velocity
      local dx, dy = v.x * dt, v.y * dt
      p.x, p.y = p.x + dx, p.y + dy
    end
  end
end



return VelocitySystem