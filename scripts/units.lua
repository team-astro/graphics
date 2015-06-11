require "tundra.syntax.osx-bundle"
require "tundra.syntax.glob"

local astroGfx = StaticLibrary {
  Name = "AstroGraphics",
  Sources = {
    FGlob {
      Dir = "src",
      Extensions = { ".cpp", ".mm" },
      Filters = {
        { Pattern = "/win32/"; Config = "win*-*-*" },
        { Pattern = "/osx/"; Config = "macosx-*-*" },
      },
    },
  },
  Frameworks = {
    { "Cocoa", "OpenGL", "CoreVideo"; Config = "macosx-*-*" },
  },
  Env = {
    CPPPATH = {
      "include/",
      "lib/",
      "../astro/include/",
      "../astro/lib/",
    },
  },
  Propagate = {
    Frameworks = {
      { "Cocoa", "OpenGL", "CoreVideo"; Config = "macosx-*-*" },
    },
    Env = {
      CPPPATH = {
        "include/",
        "lib/",
      },
      PROGOPTS = {
        --"-stdlib="
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
  Frameworks = { "Cocoa" },
  Env = {
    CPPPATH = {
      "include/",
      "lib/",
      "../astro/include/",
      "../astro/lib/",
    },
  },
}

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
