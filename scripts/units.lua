require "tundra.syntax.osx-bundle"
require "tundra.syntax.glob"
local platform = require "tundra.platform"
local native = require "tundra.native"

_G.ASTRO_GFX_ROOT = _G.ASTRO_GFX_ROOT or "./"

local astro_gfx_libs = {
    { "Gdi32.lib", "kernel32.lib", "user32.lib"; Config = { "win32-*-*", "win64-*-*" } },
}

local astro_gfx_frameworks = {
  { Config = "osx-*-*"; "Cocoa", "OpenGL", "CoreVideo" },
  { Config = "ios*-*-*"; "UIKit", "OpenGLES", "CoreVideo" },
}

local astro_gfx_defines = {
  { Config = { "win32-*-*", "win64-*-*" }; "ASTRO_GFX_CONFIG_RENDERER_OPENGL=32" }
}

local astroGfx = StaticLibrary {
  Name = "AstroGraphics",
  Depends = { "Astro" },
  Sources = {
    FGlob {
      Dir = _G.ASTRO_GFX_ROOT .. "src",
      Extensions = { ".h", ".cpp", ".mm" },
      Filters = {
        { Pattern = "/nacl/"; Config = "nacl-*-*" },
        { Pattern = "/asmjs/"; Config = "asmjs-*-*" },
        { Pattern = "/win32/"; Config = { "win32-*-*", "win64-*-*" } },
        { Pattern = "/osx/"; Config = "osx-*-*" },
      },
    },
  },
  Libs = astro_gfx_libs,
  Frameworks = astro_gfx_frameworks,
  Defines = astro_gfx_defines,
  Env = {
    CPPPATH = {
      _G.ASTRO_GFX_ROOT .. "src/",
      _G.ASTRO_GFX_ROOT .. "include/",
      _G.ASTRO_GFX_ROOT .. "lib/khronos/",
      _G.ASTRO_GFX_ROOT .. "lib/",
    },
  },
  Propagate = {
    Depends = { "Astro" },
    Frameworks = astro_gfx_frameworks,
    Libs = astro_gfx_libs,
    Defines = astro_gfx_defines,
    Env = {
      CPPPATH = {
        _G.ASTRO_GFX_ROOT .. "include/",
        _G.ASTRO_GFX_ROOT .. "lib/",
      },
      PROGOPTS = {
      }
    },
  },
}

-- TODO: Better check for "not building as dependency"
if _G.ASTRO_GFX_ROOT == "./" then
  local gfxTests = Program {
    Name = "AstroGraphicsTests",
    Sources = {
      _G.ASTRO_GFX_ROOT .. "test/main.cpp",
    },
    Depends = { astroGfx },
    Env = {
      CXXOPTS = {
        { "-s TOTAL_MEMORY=33554432"; Config = "asmjs-*-*" },
        { "-s ASSERTIONS=2 -s SAFE_HEAP=1"; Config = "asmjs-debug-*" },
      },
      PROGOPTS = {
        { "-s TOTAL_MEMORY=33554432"; Config = "asmjs-*-*" },
        { "-s ASSERTIONS=2 -s SAFE_HEAP=1"; Config = "asmjs-debug-*" },
      },
      CPPPATH = {
        "include/",
        "lib/",
        "../astro/include/",
        "../astro/lib/",
      },
    },
  }


  if platform.host_platform() == "macosx" then
    local gfxTestsBundle = OsxBundle {
      Depends = { gfxTests },
      Config = "osx-*-*",
      Target = "$(OBJECTDIR)/AstroGraphicsTests.app",
      InfoPList = "test/osx/Info.plist",
      Executable = "$(OBJECTDIR)/AstroGraphicsTests",
      Resources = {

      },
    }

    -- TODO: Only build bundle on OS X
    Default(gfxTestsBundle)
  else
    Default(gfxTests)
  end
end
