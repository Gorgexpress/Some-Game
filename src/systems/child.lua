local ChildSystem = {}



function ChildSystem.update(entities, num_entities, dt)
  for i=1, num_entities do
    local entity = entities[i]
    if entity.Parent and entity.Transform.localp then 
      local entity = entities[i]
      local p, lp, pp = entity.Transform.position, entity.Transform.localp, entity.Parent.Transform.position
      p.x, p.y = pp.x + lp.x, pp.y + lp.y
    end
  end
end



return ChildSystem