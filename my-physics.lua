local Physics = {}
local Physics_mt = {}

local floor, ceil, max, min, abs = math.floor, math.ceil, math.max, math.min, math.abs

function Physics.new(map, layer)
  return setmetatable({
    tiles = layer,
    tile_size = map.tilewidth,
    num_cols = map.width,
    num_rows = map.height,
  }, Physics_mt)
end


local function slide(tx1, ty1, tx2, ty2, ox1, oy1, ox2, oy2)
  local min_depth = abs(tx2 - ox1)
  local case = 1

  local depth = abs(ty2 - oy1)
  if depth < min_depth then
    case = 2
    min_depth = depth
  end
  depth = abs(tx1 - ox2)
  if depth < min_depth then
    case = 3
    min_depth = depth
  end
  depth = abs(ty1 - oy2)
  if depth < min_depth then
    case = 4
  end
  if case == 1 then
    return tx2 + 1, oy1
  elseif case == 2 then
    return ox1, ty2 + 1
  elseif case == 3 then
    return tx1 - 1 - (ox2 - ox1), oy1
  else
    return ox1, ty1 - 1 - (oy2 - oy1)
  end
end

function Physics.check(self, entity, x1, y1, x2, y2)
  local ox, oy = x2 - x1, y2 - y1
  local left = max(floor(x1 / self.tile_size) + 1, 1)
  local top = max(floor(y1 / self.tile_size) + 1, 1)
  local right = min(ceil(x2 / self.tile_size), self.num_cols)
  local bottom = min(ceil(y2 / self.tile_size), self.num_rows)
  
  for y=top, bottom do
    for x=left, right do
      if self.tiles[y][x].properties.collidable then
        local tx2, ty2 = x * self.tile_size, y * self.tile_size
        x1, _ = slide(tx2 - self.tile_size, ty2 - self.tile_size, tx2, ty2, x1, y1, x2, y2)
      end
    end
  end

  for y=top, bottom do
    for x=left, right do
      if self.tiles[y][x].properties.collidable then
        local tx2, ty2 = x * self.tile_size, y * self.tile_size
        _, y1 = slide(tx2 - self.tile_size, ty2 - self.tile_size, tx2, ty2, x1, y1, x2, y2)
      end
    end
  end
  return x1, y1
end



Physics_mt.__index = Physics

function Physics_mt.__call(_, map, layer)
  return Physics.new(map, layer)
end

return setmetatable({}, Physics_mt)