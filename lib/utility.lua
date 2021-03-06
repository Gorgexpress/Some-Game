local floor = math.floor
local Vec2 = require 'lib/vec2'
local Utility = {}

function Utility.vecToDir(v)
  if v.x < 0 then return 'l' end
  if v.x > 0 then return 'r' end
  if v.y > 0 then return 'd' end
  return 'u'
end

function Utility.center(position, size, offset)
  position.x, position.y = position.x - offset.x - size.x * 0.5, position.y - offset.y - size.y * 0.5
end

function Utility.centerEntity(x, y, w, h, ox, oy)
  return x - ox - w * 0.5, y - oy - h * 0.5
end

function Utility.getCenter(self)
  return self.Transform.position + self.Body.offset + self.Body.size * 0.5
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

--[[
--TODO clean up and refractor hard coded situations
function Utility.bezierToMesh(curve, width)
  width = width / 2
  local x, y = curve:getControlPoint(1)
  local trilist = {}
  local right = true
  local uvr = false
  local uvl = true
  for t=0, 0.9, 0.1 do
    local x1, y1 = curve:evaluate(t)
    local x2, y2 = curve:evaluate(t + 0.1)
    local dir = Vec2(x2 - x1, y2 - y1):normalize()
    local perp = dir:perpendicular()
    if t == 0 then
      local dx, dy = (perp * -width):unpack()
      trilist[#trilist + 1] = {x1 + dx, y1 + dy, 0, 0}
    end
    if right then
      local dx, dy = (perp * width):unpack()
      if uvr then
        trilist[#trilist + 1] = {x1 + dx, y1 + dy, 1, 0}
      else
        trilist[#trilist + 1] = {x1 + dx, y1 + dy, 0, 1}
      end
      uvr = not uvr
    else
      local dx, dy = (perp * -width):unpack()
      if uvl then
        trilist[#trilist + 1] = {x1 + dx, y1 + dy, 0, 0}
      else
        trilist[#trilist + 1] = {x1 + dx, y1 + dy, 1, 1}
      end
      uvl = not uvl
    end
    right = not right
    if t > 0.85 then
        --1,0 then 1,1
      local dx, dy = (perp * width):unpack()
      trilist[#trilist + 1] = {x2 + dx, y2 + dy, 1, 0}
      dx, dy = (perp * -width):unpack()
      trilist[#trilist + 1] = {x2 + dx, y2 + dy, 1, 1}
    end
  end

  return trilist
end]]

--TODO this can be moved into a vertex and fragment shader, where the vertex shader gets the position and normal at sampled points
--but getting the main game working takes priority. 
--Vertex shader would be difficult since Love does not support geometry shaders currently. Would need to send two vertices for each point we want to sample,
--and have a vertex attribute specify which way the vertex expands.
function Utility.bezierToMesh(curve, width, resolution)
  local step = resolution == nil and 0.2 or (1 / resolution) --1 / step == resolution == how many points on curve to sample for vertices
  width = width / 2
  local x, y = curve:getControlPoint(1)
  local derivative = curve:getDerivative()
  --derivative:evaluate(t) is the change in direction at curve:evaluate(t)
  --we follow the direction of the vector perpendicular to derivative:evaluate(t) to get the normal
  local d = Vec2(derivative:evaluate(0)):normalize():perpendicular()
  local trilist = {}
  local t = 0
  for t=0, 1, step do
    x, y = curve:evaluate(t)
    d = Vec2(derivative:evaluate(t)):normalize():perpendicular()
    --only differences between the 2 branches are uvs
    trilist[#trilist + 1] = {x + d.x * width, y + d.y * width, t, 0}
    trilist[#trilist + 1] = {x - d.x * width, y - d.y * width, t, 1}
  end
  --last quad. Again, we want different uvs for the endpoints. uvs are reversed compared to the first quad
  return trilist
end

function Utility.AABB(x1, y1, w1, h1, x2, y2, w2, h2)
   return x1 < x2+w2 and x2 < x1+w1 and
         y1 < y2+h2 and y2 < y1+h1
end
return Utility