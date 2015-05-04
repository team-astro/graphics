/**
* Copyright 2015 Team Astro. All rights reserved.
*/

#include <astro/graphics/application.h>

using namespace astro;
using namespace astro::graphics;

TEST app_startup_and_shutdown()
{
  application* app = create_application(ASTRO_MB(16));
  ASSERT(app->stack.base);
  ASSERT(app->is_running);

  dispose_application(app);

  PASS();
}

SUITE(application_tests) { RUN_TEST(app_startup_and_shutdown); }
