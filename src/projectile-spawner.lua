local EntityManager = require 'src/managers/entity-manager'

local ProjectileSpawner = {}


function ProjectileSpawner.fireAtPosition(self, target, type)
  local position = self.transform.position + self.body.offset + self.body.size * 0.5
  if not target.transform then
    local velocity = (target - position):normalize() * 50
    EntityManager.add('bullet', {position = position, velocity = velocity})
  end

end


return ProjectileSpawner