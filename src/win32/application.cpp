/**
* Copyright 2015 Team Astro. All rights reserved.
*/

#include <astro/graphics/application.h>

#define WIN32_LEAN_AND_MEAN
#include <windows.h>

namespace astro
{
namespace graphics
{
  struct win32_application : application
  {
  };

  static void
  null_app_event(application* app) { }

  application* create_application(uintptr heap_size)
  {
    uint8* heap = (uint8*)malloc(heap_size);
    if (!heap)
    {
      exit(EXIT_FAILURE);
    }

    win32_application* app = (win32_application*) heap;
    app->on_startup = null_app_event;
    app->on_shutdown = null_app_event;

    heap += sizeof(win32_application);
    heap_size -= sizeof(win32_application);

    initialize_memory_stack(&app->stack, heap_size, heap);

    return app;
  }

  void update_application(application* app)
  {
    MSG msg = {};
    while (PeekMessage(&msg, nullptr, 0, 0, PM_REMOVE))
    {
      TranslateMessage(&msg);
      DispatchMessage(&msg);
    }
  }

  void quit_application(application* app)
  {
    app->is_running = false;
  }

  void dispose_application(application* app)
  {
    app->is_running = false;
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
