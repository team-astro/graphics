/**
* Copyright 2015 Team Astro. All rights reserved.
*/

#include <stdio.h>

#define ASTRO_IMPLEMENTATION
#include <astro/astro.h>
#include <astro/memory.h>
#include <astro/logging.h>
#undef ASTRO_IMPLEMENTATION

#include <greatest/greatest.h>
GREATEST_MAIN_DEFS();

#include "application_tests.h"
#include "window_tests.h"

int main(int argc, char **argv)
{
  GREATEST_MAIN_BEGIN();      /* init & parse command-line args */
  RUN_SUITE(application_tests);
  RUN_SUITE(window_tests);
  GREATEST_MAIN_END();        /* display results */
}
