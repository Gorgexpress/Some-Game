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
  nextobjectid = 12,
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
      data = "eJxjYWBgYKISZoFiRirhUfNGzRs1b9S8UfOoZx4x5ThMPTFqAdN2Aic="
    },
    {
      type = "objectgroup",
      name = "Sprite",
      visible = false,
      opacity = 1,
      offsetx = 0,
      offsety = 0,
      draworder = "topdown",
      properties = {},
      objects = {
        {
          id = 6,
          name = "",
          type = "",
          shape = "rectangle",
          x = 288,
          y = 608,
          width = 64,
          height = 32,
          rotation = 0,
          visible = true,
          properties = {
            ["entrance"] = "south"
          }
        },
        {
          id = 7,
          name = "",
          type = "",
          shape = "rectangle",
          x = 288,
          y = 640,
          width = 64,
          height = 32,
          rotation = 0,
          visible = true,
          properties = {
            ["exitid"] = "north",
            ["exitmap"] = "101"
          }
        },
        {
          id = 10,
          name = "",
          type = "",
          shape = "rectangle",
          x = 320,
          y = 128,
          width = 0,
          height = 0,
          rotation = 0,
          visible = true,
          properties = {
            ["entity"] = "enemies/bosses/boss1"
          }
        }
      }
    }
  }
}
