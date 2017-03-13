local Utility = {}

function Utility.vecToDir(v)
  if v.x < 0 then return 'l' end
  if v.x > 0 then return 'r' end
  if v.y > 0 then return 'd' end
  return 'u'
end

return Utility