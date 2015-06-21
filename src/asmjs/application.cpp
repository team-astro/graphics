/**
* Copyright 2015 Team Astro. All rights reserved.
*/

#include <astro/graphics/application.h>
#include <astro/os.h>

namespace astro
{
namespace graphics
{
  struct asmjs_application : application
  {
  };

  static void
  null_app_event(application* app) { }

  application* create_application(uintptr heap_size)
  {
    uint8* heap = (uint8*)ASTRO_ALLOC(default_allocator, heap_size);
    if (!heap)
    {
      exit(EXIT_FAILURE);
    }

    asmjs_application* app = (asmjs_application*) heap;
    app->on_startup = null_app_event;
    app->on_shutdown = null_app_event;

    heap += sizeof(asmjs_application);
    heap_size -= sizeof(asmjs_application);

    initialize_memory_stack(&app->stack, heap_size, heap);

    return app;
  }

  void update_application(application* app)
  {
    astro_assert(false);
  }

  void quit_application(application* app)
  {
    app->is_running = false;
  }

  void dispose_application(application* app)
  {
    app->is_running = false;
    void* heap = (void*) app;
    ASTRO_FREE(default_allocator, heap);
  }

  void set_clipboard_text(const char* text)
  {
    astro_assert(false);
  }

  const char* get_clipboard_text(memory_stack* stack)
  {
    astro_assert(false);
    return nullptr;
  }
}
}
