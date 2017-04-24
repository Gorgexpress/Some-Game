local AssetManager = {}
local _assets = {}
local FileFinder = require 'lib/filefinder'
local _iff = FileFinder.new(5, 'assets/graphics/', {'png'})
local _sff = FileFinder.new(5, 'assets/sfx/', {'wav'})

function AssetManager.getAsset(name, extension)
  if not _assets[name] then 
    if extension == 'png' then
      _assets[name] = love.graphics.newImage('assets/' .. name .. '.' .. extension)
    elseif extension =='wav' then
      _assets[name] = love.audio.newSource('assets/' .. name .. '.' .. extension)
    end
  end
  return _assets[name]
end

function AssetManager.getSound(name)
  if not _assets[name] then
    local path = _sff:find(name)
    if not path then
      print("Could not find sound "..name) 
      return nil
    end
    _assets[name] = love.audio.newSource(path)
  end
  return _assets[name]
end

function AssetManager.getImage(name)
  if not _assets[name] then
    local path = _iff:find(name)
    if not path then
      print("Could not find image "..name) 
      return nil
    end
    _assets[name] = love.graphics.newImage(path)
  end
  return _assets[name]
end


function AssetManager.clear()
  assets = {}
end

return AssetManager