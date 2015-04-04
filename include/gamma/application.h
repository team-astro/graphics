/**
* Copyright 2015 Matt Rudder. All rights reserved.
*/

#ifndef MU_APPLICATION
#define MU_APPLICATION

#include <mu/mu.h>
#include <mu/memory.h>

namespace mu
{
  struct application
  {
    bool32 is_running;
    mu::memory_pool* pool;

    void (*on_startup)(application* app);
    void (*on_shutdown)(application* app);
  };

  application* create_application(mu::memory_pool* pool);
  void update_application(application* app);
  void quit_application(application* app);
  void dispose_application(application* app);

  void set_clipboard_text(const char* text);
  const char* get_clipboard_text(mu::memory_pool* pool);
}

#if defined(MU_IMPLEMENTATION)
# if MU_PLATFORM_OSX
#   include <mu/osx/application.mm>
# endif
#endif

#endif
