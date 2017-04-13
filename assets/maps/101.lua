return {
  version = "1.1",
  luaversion = "5.1",
  tiledversion = "0.18.0",
  orientation = "orthogonal",
  renderorder = "right-down",
  width = 20,
  height = 20,
  tilewidth = 32,
  tileheight = 32,
  nextobjectid = 6,
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
      name = "Tile Layer 1",
      x = 0,
      y = 0,
      width = 20,
      height = 20,
      visible = true,
      opacity = 1,
      offsetx = 0,
      offsety = 0,
      properties = {},
      encoding = "base64",
      compression = "zlib",
      data = "eJxjYWBgYCICM0IxPjUsUMxIJTxq3qh5A20etcyilXmDPfxGzRtc5hFT1pOCAbXOAiE="
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
          id = 1,
          name = "",
          type = "",
          shape = "rectangle",
          x = -32,
          y = 320,
          width = 32,
          height = 64,
          rotation = 0,
          visible = true,
          properties = {
            ["exitid"] = "east",
            ["exitmap"] = "102"
          }
        },
        {
          id = 2,
          name = "",
          type = "",
          shape = "rectangle",
          x = 0,
          y = 320,
          width = 32,
          height = 64,
          rotation = 0,
          visible = true,
          properties = {
            ["entrance"] = "west"
          }
        },
        {
          id = 3,
          name = "",
          type = "",
          shape = "rectangle",
          x = 320,
          y = 0,
          width = 64,
          height = 32,
          rotation = 0,
          visible = true,
          properties = {
            ["entrance"] = "north"
          }
        },
        {
          id = 4,
          name = "",
          type = "",
          shape = "rectangle",
          x = 320,
          y = -32,
          width = 64,
          height = 32,
          rotation = 0,
          visible = true,
          properties = {
            ["exitid"] = "south",
            ["exitmap"] = "103"
          }
        }
      }
    }
  }
}
