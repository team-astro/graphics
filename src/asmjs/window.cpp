/**
* Copyright 2015 Team Astro. All rights reserved.
*/

#include <astro/astro.h>
#include <astro/memory.h>
using namespace astro;

#include <astro/graphics/context.h>
#include <astro/graphics/window.h>

using namespace astro;
using namespace astro::graphics;

namespace astro
{
namespace graphics
{
  struct asmjs_window : public window
  {
  };

  void null_on_key_change(window*, key_state) { }
  void null_on_mouse_change(window*, mouse_state) { }
  void null_on_touch_change(window*, touch_state) { }

  window*
  create_window(application* app,
                const char* title,
                uint16 width,
                uint16 height)
  {
    asmjs_window* window = push_struct<asmjs_window>(&app->stack);
    *window = {};
    window->title = push_string(&app->stack, title);
    window->width = width;
    window->height = height;

    window->on_key_change = null_on_key_change;
    window->on_mouse_change = null_on_mouse_change;
    window->on_touch_change = null_on_touch_change;
    window->app = app;

    push_list(&app->stack, &app->windows);
    app->windows->window = window;


    //window->context = create_context(window);

    //draw_window(window, 0, true);

    return window;
  }

  void
  draw_window(window* win, real32 delta_time, bool32 resize)
  {
    context_make_current(win->context, resize);
    if (resize)
    {
      log_debug("set window pixel ratio to %g", win->pixel_ratio);
    }

    astro_assert(win->on_render);
    win->on_render(win, delta_time);

    context_flush(win->context);
  }
}
}
