/**
* Copyright 2015 Team Astro. All rights reserved.
*/

#include <astro/graphics/window.h>

using namespace astro;
using namespace astro::graphics;

void app_harness_create(void* env)
{
  application* app = create_application(ASTRO_MB(16));

  *((application**) env) = app;
}

void app_harness_destroy(void* env)
{
  application* app = *((application**) env);
  dispose_application(app);
}

void on_key_change(window* win, key_state state)
{
  printf("Got key change");
  application* app = win->app;
  if (state.code == key_code::Escape)
  {
    printf("Got esc!");
    app->is_running = false;
  }
}

TEST window_creation(void* env)
{
  application* app = (application*) env;

  window* win = create_window(app, "window_creation", 320, 240);
  win->on_key_change = on_key_change;

  while (app->is_running)
  {
    update_application(app);
  }

  PASS();
}

SUITE(window_tests)
{
  application* app = nullptr;
  SET_SETUP(app_harness_create, &app);
  SET_TEARDOWN(app_harness_destroy, &app);

  RUN_TEST1(window_creation, app);
}
