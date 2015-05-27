ASTRO_GFX_DIR = path.getabsolute("..")
if BUILD_DIR == nil then
  BUILD_DIR = path.join(ASTRO_GFX_DIR, ".build")
  solution "astro.graphics"
end
ASTRO_GFX_THIRD_PARTY_DIR = path.join(ASTRO_GFX_DIR, "lib")
local ASTRO_DIR = path.getabsolute(path.join(ASTRO_GFX_DIR, "../astro"))

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

dofile (path.join(ASTRO_DIR, "scripts/genie.lua"))
dofile (path.join(ASTRO_DIR, "scripts/toolchain.lua"))
if not toolchain(BUILD_DIR, ASTRO_GFX_THIRD_PARTY_DIR) then
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
    path.join(ASTRO_GFX_DIR, "test"),
    ASTRO_GFX_THIRD_PARTY_DIR,
    ASTRO_THIRD_PARTY_DIR
  }

  files {
    path.join(ASTRO_GFX_DIR, "test/*.cpp"),
    path.join(ASTRO_GFX_DIR, "test/*.h"),
  }

  links {
    "astro",
    "astro.graphics"
  }

  configuration { "osx" }
    links {
      "Cocoa.framework",
      "CoreVideo.framework",
      "OpenGL.framework"
    }
    files {
      path.join(ASTRO_GFX_DIR, "test/osx/Shell.app/Contents/Info.plist")
    }
    buildoptions {
      "-std=c++11"
    }

  configuration { "ios*" }
    linkoptions {
      "-framework CoreFoundation",
      "-framework Foundation",
      "-framework OpenGLES",
      "-framework UIKit",
      "-framework QuartzCore",
    }

  configuration { "windows" }

  configuration {}

  strip()
