/**
* Copyright 2015 Team Astro. All rights reserved.
*/

#ifndef ASTRO_GFX_APPLICATION
#define ASTRO_GFX_APPLICATION

#include <astro/astro.h>
#include <astro/memory.h>

namespace astro { namespace graphics
{
  struct window_list;

  struct application
  {
    bool32 is_running;
    memory_stack stack;
    window_list* windows;
    void* context;

    void (*on_startup)(application* app);
    void (*on_shutdown)(application* app);
  };

  application* create_application(uintptr heap_size);
  void update_application(application* app);
  void quit_application(application* app);
  void dispose_application(application* app);

  void set_clipboard_text(const char* text);
  const char* get_clipboard_text(memory_stack* stack);
}
}

#endif
