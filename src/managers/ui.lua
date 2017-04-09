local UI = {}

local _width, _height = love.graphics.getDimensions()

function UI.draw(player)
  local r, g, b, a = love.graphics.getColor()
  love.graphics.setColor(255, 0, 0)
  love.graphics.rectangle('fill', 25, _height - 75, 200 * (player.health / player.max_health), 25)
  love.graphics.setColor(0, 0, 255)
  love.graphics.rectangle('fill', 25, _height - 50, 200 * (player.mp / player.max_mp), 25)
  love.graphics.setColor(r, g, b)
end

return UI