local abs, floor, ceil = math.abs, math.floor, math.ceil
local setShader, draw = love.graphics.setShader, love.graphics.draw
local Trail = {}
local Trail_mt = {}
local initv = {}
for i=1, 500 do
    initv[i] = {0, 0, 0,0}
end
local _mesh = love.graphics.newMesh(initv, 'strip', 'dynamic')

function Trail.new(texture, x, y, thickness, duration, dist_threshold)
  return setmetatable({
    head = 0,
    tail = 3,
    points = {duration, x, y},
    x = x,
    y = y,
    texture = texture,
    duration = duration,
    dist_threshold2 = dist_threshold == nil and 900 or dist_threshold * dist_threshold,
    seconds_elapsed = 0,
    thickness = thickness,
  }, Trail_mt)
end

function Trail.update(self, dt, x, y)
  self.x, self.y = x, y
  self.seconds_elapsed = self.seconds_elapsed + dt
  local tail, head = self.tail, self.head
  local points = self.points
  local prevx, prevy = points[tail-1], points[tail]
  if prevx == nil or math.abs((x * x + y * y) - (prevx * prevx + prevy * prevy)) >= self.dist_threshold2 then
    points[tail+1], points[tail+2], points[tail+3] = self.seconds_elapsed + self.duration, x, y
    tail = tail + 3
  end
  while head < tail and points[head+1] <= self.seconds_elapsed do
    points[head+1], points[head+2], points[head+3] = nil, nil, nil
    head = head + 3 
  end 
  self.tail, self.head = tail, head
  print(head, tail)
end

function Trail.draw(self)
  local vertices = {}
  local points = self.points
  local length = (self.tail - self.head) / 3
  if length < 1 then return end
  if points[self.tail-1] ~= self.x and points[self.tail] ~= self.y then length = length + 1 end
  _mesh:setTexture(self.texture)
  local texstep = 1 / length
  local uvx = 0
  local idx = 1
  local thickness = self.thickness
  local x1, y1 = points[self.head+2], points[self.head+3]
  local px, py
  for i=self.head + 3, self.tail-3, 3 do
    local x2, y2 = points[i+2], points[i+3]
    local dx, dy = x2 - x1, y2 - y1
    local n = 1 / math.sqrt(dx * dx + dy * dy)
    local nx, ny = dx * n, dy * n
    px, py = -ny, nx
    vertices[idx] = {x1 + px * thickness, y1 + py * thickness, uvx, 0}
    vertices[idx+1] = {x1 + px * -thickness, y1 + py * -thickness, uvx, 1}
    uvx = uvx + texstep
    x1, y1 = x2, y2
    idx = idx + 2
  end
  if x1 ~= self.x and y1 ~= self.y then
    local x2, y2 = self.x, self.y
    local dx, dy = x2 - x1, y2 - y1
    local n = 1 / math.sqrt(dx * dx + dy * dy)
    local nx, ny = dx * n, dy * n
    px, py = -ny, nx
    vertices[idx] = {x1 + px * thickness, y1 + py * thickness, uvx, 0}
    vertices[idx+1] = {x1 + px * -thickness, y1 + py * -thickness, uvx, 1}
    idx = idx + 2
  elseif length == 1 then return 
  end
  vertices[idx] = {self.x + px * thickness, self.y + py * thickness, 1, 0}
  vertices[idx+1] = {self.x + px * -thickness,self.y + py * -thickness, 1, 1}
  _mesh:setVertices(vertices)
  _mesh:setDrawRange(1, idx+1)
  love.graphics.draw(_mesh)
end

Trail_mt.__index = Trail

return Trail