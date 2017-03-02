return {
  version = "1.1",
  luaversion = "5.1",
  tiledversion = "0.18.0",
  orientation = "orthogonal",
  renderorder = "right-down",
  width = 100,
  height = 100,
  tilewidth = 32,
  tileheight = 32,
  nextobjectid = 8,
  properties = {},
  tilesets = {
    {
      name = "countryside",
      firstgid = 1,
      tilewidth = 32,
      tileheight = 32,
      spacing = 0,
      margin = 0,
      image = "../graphics/tilesets/countryside.png",
      imagewidth = 64,
      imageheight = 64,
      tileoffset = {
        x = 0,
        y = 0
      },
      properties = {},
      terrains = {},
      tilecount = 4,
      tiles = {
        {
          id = 1,
          properties = {
            ["collidable"] = true
          }
        },
        {
          id = 3,
          properties = {
            ["collidable"] = true
          }
        }
      }
    }
  },
  layers = {
    {
      type = "tilelayer",
      name = "Tile",
      x = 0,
      y = 0,
      width = 100,
      height = 100,
      visible = true,
      opacity = 1,
      offsetx = 0,
      offsety = 0,
      properties = {},
      encoding = "base64",
      compression = "zlib",
      data = "eJzt3NEKgjAAQFEL//+bI+ghxCwi9M7Ow0E2EWEXlL1snqbpSsL8cCFBjxY9WvRo0aNFjxY9WvRo0aNFjxY9WvRo0aNFjxY9WvRo0aNFjxY9WvRo0aNFjxY9WvRo0aNFjxY9WvRo0aNFjxY9WvRo0aNFjxY9WvRo0aNFjxY9WvRo0aNFjxY9WvRo0aNFjxY9WvRo0aNFjxY9Wvbs8e499/vLswS3nl8br51JePQaj9zjl+MR6dEyUo/lt2c51mPfHs9zr+6N/O84Y4+j1/PfelwXVz2O7fHN/Ej27PFub/Dp3mFr3v4DPc5LjxY9WvRo0aNFjxY9WvRo0aNFjxY9WvRo0aNFjxY9WvRo0aNFjxY9WvRo0aNFjxY9WvRo0aNFjxY9WvRo0aNFjxY9WvRo0aNFjxY9WvRo0aNl7YwJjnUDx/0qyw=="
    },
    {
      type = "objectgroup",
      name = "Sprite",
      visible = true,
      opacity = 1,
      offsetx = 0,
      offsety = 0,
      draworder = "topdown",
      properties = {},
      objects = {
        {
          id = 7,
          name = "Player",
          type = "",
          shape = "rectangle",
          x = 1376,
          y = 2240,
          width = 0,
          height = 0,
          rotation = 0,
          visible = true,
          properties = {}
        }
      }
    }
  }
}
