solution "astro.graphics"
  configurations {
    "Debug",
    "Release"
  }

  if _ACTION == "xcode4" then
    platforms {
      "Universal"
    }
  else
    platforms {
      "x32",
      "x64",
      "Native"
    }
  end

  language "C++"
  startproject "astro.graphics.tests"

ASTRO_GFX_DIR = path.getabsolute("..")
local ASTRO_GFX_BUILD_DIR = path.join(ASTRO_GFX_DIR, ".build")
local ASTRO_GFX_THIRD_PARTY_DIR = path.join(ASTRO_GFX_DIR, "thirdparty")
ASTRO_DIR = path.getabsolute(path.join(ASTRO_GFX_DIR, "../astro"))

dofile (path.join(ASTRO_DIR, "scripts/toolchain.lua"))
if not toolchain(ASTRO_GFX_BUILD_DIR, ASTRO_GFX_THIRD_PARTY_DIR) then
  return
end

function copyLib()
end

group "libs"
dofile "astro.graphics.lua"

group "tests"
project ("astro.graphics.tests")
  uuid (os.uuid("astro.graphics.tests"))
  kind "WindowedApp"

  configuration {}

  includedirs {
    path.join(ASTRO_DIR, "include"),
    path.join(ASTRO_GFX_DIR, "include"),
    path.join(ASTRO_GFX_DIR, "thirdparty"),
    path.join(ASTRO_GFX_DIR, "test")
  }

  links {
    "astro.graphics",
  }

  configuration { "osx" }
    links {
      "Cocoa.framework",
      "OpenGL.framework"
    }
    files {
      path.join(ASTRO_GFX_DIR, "test/osx/Shell.app/Contents/Info.plist")
    }

  configuration { "ios*" }
    linkoptions {
      "-framework CoreFoundation",
      "-framework Foundation",
      "-framework OpenGLES",
      "-framework UIKit",
      "-framework QuartzCore",
    }

  configuration {}

  strip()
