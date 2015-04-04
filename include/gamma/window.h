/**
* Copyright 2015 Matt Rudder. All rights reserved.
*/

#ifndef GAMMA_WINDOW
#define GAMMA_WINDOW

#include <mu/mu.h>
#include <gamma/application.h>

namespace gamma
{
  struct window_events
  {
    vec2 mouse_pos;
    real32 mouse_wheel;
    bool32 mouse_down[2];
  };

  struct key_state
  {
    bool32 key_pressed;
    bool32 repeat;
    uint16 code;
    char characters[4];
    char raw_characters[4];
  };

  struct mouse_state
  {
    bool32 button_pressed;
    vec2 position;
    vec3 wheel;
    uint8 button;
    real32 pressure;
    uint8 click_count;
  };

  enum touch_phase
  {
    TP_BEGAN,
    TP_MOVED,
    TP_STATIONARY,
    TP_ENDED,
    TP_CANCELLED,
    TP_TOUCHING = TP_BEGAN | TP_MOVED | TP_STATIONARY,
  };

  struct touch_info
  {
    uint8 index;
    vec2 position;
    touch_phase phase;
  };

  struct touch_state
  {
    touch_info touches[16];
    uint8 touch_count;
  };

  struct window
  {
    const char* title;
    real32 pixel_ratio;
    uint16 width;
    uint16 height;

    void (*on_render)(window* win, real32 dt);
    void (*on_key_change)(window* win, key_state state);
    void (*on_mouse_change)(window* win, mouse_state state);
    void (*on_touch_change)(window* win, touch_state state);
  };

  struct window_list
  {
    window* window;
    window_list* next;
  };

  window* create_window(application* app, const char* title, uint16 width, uint16 height);
  void draw_window(window* window, real32 delta_time, bool32 resize);
}

#if defined(GAMMA_IMPLEMENTATION)
# if MU_PLATFORM_OSX
#   include <gamma/osx/window.mm>
# endif
#endif

#endif
