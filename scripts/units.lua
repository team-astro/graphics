require "tundra.syntax.osx-bundle"
require "tundra.syntax.glob"
local platform = require "tundra.platform"
local native = require "tundra.native"

local astroGfx = StaticLibrary {
  Name = "AstroGraphics",
  Depends = { "Astro" },
  Sources = {
    FGlob {
      Dir = "src",
      Extensions = { ".cpp", ".mm" },
      Filters = {
        { Pattern = "/nacl/"; Config = "nacl-*-*" },
        { Pattern = "/asmjs/"; Config = "asmjs-*-*" },
        { Pattern = "/win32/"; Config = "win*-*-*" },
        { Pattern = "/osx/"; Config = "osx-*-*" },
      },
    },
  },
  Frameworks = {
    { "Cocoa", "OpenGL", "CoreVideo"; Config = "osx-*-*" },
    { "UIKit", "OpenGLES", "CoreVideo"; Config = "ios*-*-*" },
  },
  Env = {
    CPPPATH = {
      "include/",
      "lib/",
    },
  },
  Propagate = {
    Depends = { "Astro" },
    Frameworks = {
      { "Cocoa", "OpenGL", "CoreVideo"; Config = "osx-*-*" },
      { "UIKit", "OpenGLES", "CoreVideo"; Config = "ios*-*-*" },
    },
    Env = {
      CPPPATH = {
        "include/",
        "lib/",
      },
      PROGOPTS = {
      }
    },
  },
}

local gfxTests = Program {
  Name = "AstroGraphicsTests",
  Sources = {
    "test/main.cpp",
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
