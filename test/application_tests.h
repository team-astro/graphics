/**
* Copyright 2015 Team Astro. All rights reserved.
*/

#include <astro/graphics/application.h>

using namespace astro;
using namespace astro::graphics;

TEST app_startup_and_shutdown() {
  // TODO: Map to flux::reflect types for storage on disk.
  memory_pool pool = {};
  uintptr memorySize = astro_megabytes(16);
  initialize_memory_pool(&pool, memorySize, (uint8*)malloc(memorySize));

  application* app = create_application(&pool);
  ASSERT(app != nullptr);

  dispose_application(app);

  PASS();
}

SUITE(application_tests) { RUN_TEST(app_startup_and_shutdown); }
