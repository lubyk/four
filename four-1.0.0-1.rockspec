package = "four"
version = "1.0.0-1"
source = {
  url = 'git://github.com/lubyk/four',
  tag = 'REL-1.0.0',
}
description = {
  summary = "",
  detailed = [[
  ]],
  homepage = "http://doc.lubyk.org/four.html",
  license = "MIT"
}

dependencies = {
  "lua >= 5.1, < 5.3",
  "lub >= 1.0.3, < 1.1",
  "lens >= 1.0.0, < 1.1",
  "lui >= 1.0.0, < 1.1",
}
build = {
  type = 'builtin',
  modules = {
    -- Plain Lua files
    ['four'           ] = 'four/init.lua',
    ['four.Buffer'    ] = 'four/Buffer.lua',
    ['four.Camera'    ] = 'four/Camera.lua',
    ['four.Color'     ] = 'four/Color.lua',
    ['four.Effect'    ] = 'four/Effect.lua',
    ['four.Framebuffer'] = 'four/Framebuffer.lua',
    ['four.Geometry'  ] = 'four/Geometry.lua',
    ['four.gl'        ] = 'four/gl.lua',
    ['four.M4'        ] = 'four/M4.lua',
    ['four.Quat'      ] = 'four/Quat.lua',
    ['four.Renderer'  ] = 'four/Renderer.lua',
    ['four.RendererGL32'] = 'four/RendererGL32.lua',
    ['four.Texture'   ] = 'four/Texture.lua',
    ['four.Transform' ] = 'four/Transform.lua',
    ['four.V2'        ] = 'four/V2.lua',
    ['four.V3'        ] = 'four/V3.lua',
    ['four.V4'        ] = 'four/V4.lua',
  },
}

