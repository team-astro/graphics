/**
* Copyright 2015 Matt Rudder. All rights reserved.
*/

#include <mu/application.h>
using namespace mu;

TEST_CASE("App startup and shutdown", "[mu::application]")
{
  // TODO: Map to flux::reflect types for storage on disk.
  *pool = {};
  uintptr memorySize = megabytes(16);
  initialize_memory_pool(pool, memorySize, (uint8*)malloc(memorySize));

  application* app = create_application(&pool);
  REQUIRE(app != nullptr);

  dispose_application(app);
}
