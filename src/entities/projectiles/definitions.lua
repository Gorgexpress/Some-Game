local Vec2 = require 'lib/vec2'
local Laser = require 'src/entities/projectiles/laser'

local Definitions = {}

function Definitions.fastlaser(x, y, vx, vy)
  return Laser{position = Vec2(x, y), velocity = Vec2(vx, vy), iterations = 1}
end

return Definitions 
