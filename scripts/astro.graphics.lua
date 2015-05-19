project "astro.graphics"
  uuid (os.uuid("astro.graphics"))
  kind "StaticLib"

  includedirs {
    ASTRO_GFX_THIRD_PARTY_DIR,
    path.join(ASTRO_GFX_THIRD_PARTY_DIR, "khronos"),
    path.join(ASTRO_DIR, "include"),
  }

  configuration { "ios*" }
    files {
      path.join(ASTRO_GFX_DIR, "src/ios/**")
    }

  configuration { "osx" }
    links {
      "Cocoa.framework",
      "CoreVideo.framework",
      "OpenGL.framework"
    }
    files {
      path.join(ASTRO_GFX_DIR, "src/osx/**")
    }

  configuration { "windows" }
    files {
      path.join(ASTRO_GFX_DIR, "src/win32/**")
    }

  configuration { "x64", "vs* or mingw*" }
    defines {
      "_WIN32_WINNT=0x601"
    }

  configuration {}

  includedirs {
    path.join(ASTRO_GFX_DIR, "include")
  }

  files {
    path.join(ASTRO_GFX_DIR, "include/**.h"),
  }

  defines {
    "ASTRO_IMPLEMENTATION=1"
  }

  configuration {}

  copyLib()