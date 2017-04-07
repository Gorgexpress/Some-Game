local graphics = love.graphics
local setColor, polygon, circle = graphics.setColor, graphics.polygon, graphics.circle

local Draw = {}

function Draw.drawLaser(color) return
  function(self)
    polygon('fill', unpack(self.body.polygon))  
  end
end

function Draw.drawCircle(mode, radius, r, g, b, a) return
  function(self)
    setColor(r, g, b, a)
    circle(mode, self.transform.position.x, self.transform.position.y, radius)  
  end
end

return Draw