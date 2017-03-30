local Utility = {}

function Utility.vecToDir(v)
  if v.x < 0 then return 'l' end
  if v.x > 0 then return 'r' end
  if v.y > 0 then return 'd' end
  return 'u'
end

function Utility.getCenter(self)
  return self.transform.position + self.body.offset + self.body.size * 0.5
end

function Utility.setAnimation(self, name, frame)
  self.current = self.animations[name]
  if frame then
    self.current:gotoFrame(frame)
  else
    self.current:gotoFrame(1)
  end
end

return Utility