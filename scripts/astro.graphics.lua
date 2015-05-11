project "astro.graphics"
  uuid (os.uuid("astro.graphics"))
  kind "StaticLib"

  includedirs {
    path.join(ASTRO_GFX_DIR, "thirdparty"),
    path.join(ASTRO_DIR, "include"),
  }

  configuration { "ios*" }
    files {
      path.join(ASTRO_GFX_DIR, "include/**/ios/**")
    }

  configuration { "osx" }
    links {
      "Cocoa.framework"
    }
    files {
      path.join(ASTRO_GFX_DIR, "include/**/osx/**")
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
