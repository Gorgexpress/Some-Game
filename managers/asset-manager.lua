local AssetManager = {}
local assets = {}

function AssetManager.getAsset(name, extension)
  if not assets[name] then 
    if extension == 'png' then
      assets[name] = love.graphics.newImage('assets/' .. name .. '.' .. extension)
    elseif extension =='wav' then
      assets[name] = love.audio.newSource('assets/' .. name .. '.' .. extension)
    end
  end
  return assets[name]
end

function AssetManager.getSound(name)
  if not assets[name] then
    assets[name] = love.audio.newSource('assets/' .. name .. '.wav')
  end
  return assets[name]
end

function AssetManager.getImage(name)
  if not assets[name] then
    assets[name] = love.graphics.newImage('assets/' .. name .. '.png')
  end
  return assets[name]
end


function AssetManager.clear()
  assets = {}
end

return AssetManager