local Assets = require 'src/managers/asset'
local SoundManager = {}

function SoundManager.play(name)
  Assets.getSound(name):play()
end

function SoundManager.playSound(name)
  local sound = Assets.getSound(name)
  if sound:isPlaying() then sound:rewind()
  else sound:play()
  end
end

return SoundManager

