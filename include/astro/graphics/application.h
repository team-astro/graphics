/**
* Copyright 2015 Team Astro. All rights reserved.
*/

#ifndef ASTRO_GFX_APPLICATION
#define ASTRO_GFX_APPLICATION

#include <astro/astro.h>
#include <astro/memory.h>

namespace astro
{
  // TODO: Define these types elsewhere.
  struct vec2
  {
    real32 x, y;
  };

  struct vec3
  {
    real32 x, y, z;
  };

namespace graphics
{
  struct window_list;

  struct application
  {
    bool32 is_running;
    astro::memory_stack* stack;
    window_list* windows;

    void (*on_startup)(application* app);
    void (*on_shutdown)(application* app);
  };

  application* create_application(astro::memory_stack* stack);
  void update_application(application* app);
  void quit_application(application* app);
  void dispose_application(application* app);

  void set_clipboard_text(const char* text);
  const char* get_clipboard_text(astro::memory_stack* stack);
}
}
#if defined(ASTRO_IMPLEMENTATION)
# if ASTRO_PLATFORM_OSX
#include <astro/graphics/osx/application.mm>
# endif
#endif

#endif
