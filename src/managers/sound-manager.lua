local Assets = require 'src/asset-manager'
local SoundManager = {}

function SoundManager.play(name)
  Assets.getSound(name):play()
end

return SoundManager

