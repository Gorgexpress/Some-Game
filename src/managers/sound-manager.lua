local Assets = require 'src/managers/asset-manager'
local SoundManager = {}

function SoundManager.play(name)
  Assets.getSound(name):play()
end

function SoundManager.playSound(name)
  Assets.getSound(name):play()
end

return SoundManager

