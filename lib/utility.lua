local floor = math.floor

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

function Utility.round(x)
  return floor(x + 0.5)
end

function Utility.setAnimation(self, name, frame)
  self.current = self.animations[name]
  if frame then
    self.current:gotoFrame(frame)
  else
    self.current:gotoFrame(1)
  end
end

function Utility.bbox(v)
  local ulx,uly = v[1], v[2]
	local lrx,lry = ulx,uly
	for i=3,#v, 2 do
    local x, y = v[i], v[i + 1]
		if ulx > x then ulx = x end
		if uly > y then uly = y end

		if lrx < x then lrx = x end
		if lry < y then lry = y end
	end
  return ulx, uly, lrx - ulx, lry - uly
end

return Utility