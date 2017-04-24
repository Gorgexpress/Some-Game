local FileSystem = love.filesystem
local FileFinder = {}
local FileFinder_mt = {}
FileFinder_mt.__index = FileFinder

function FileFinder.new(maxdepth, basepath, types)
  if type(types) == 'string' then types = {types} end
  return setmetatable({
    maxdepth = maxdepth,
    basepath = basepath,
    types = types,
    cache = {},
  }, FileFinder_mt)
end

local function find(path, name, types, depth, maxdepth)
  for i=1, #types do
    if FileSystem.exists(path..name..'.'..types[i]) then
      if types[i] == 'lua' then
        return path..name --remove .lua affix. require statements don't allow them.
      else
        return path..name..'.'..types[i]
      end
    end
  end
  if depth > maxdepth then return nil end
  local file_table = FileSystem.getDirectoryItems(path)
  for i, v in ipairs(file_table) do
    local file = path .. v
    if FileSystem.isDirectory(file) then
      local path_of_name = find(path..v..'/', name, types, depth + 1, maxdepth)
      if path_of_name then 
        return path_of_name
      end
    end
  end
  return nil
end

function FileFinder.find(self, name)
  if self.cache[name] then return self.cache[name] end
  local file = find(self.basepath, name, self.types, 0, self.maxdepth)
  if not file then
    print('Could not find file'..name)
    return nil
  end
  self.cache[name] = file
  return file
end

return setmetatable({}, FileFinder_mt)


