local Draw = {}

function Draw.drawLaser(color)
  return 
    function(self)
      love.graphics.polygon('fill', unpack(self.body.polygon))  
    end
end

return Draw