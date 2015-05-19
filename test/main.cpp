/**
* Copyright 2015 Team Astro. All rights reserved.
*/

#include <stdio.h>

#define __STDC_VERSION__ 199901L
#include <greatest/greatest.h>
GREATEST_MAIN_DEFS();
#undef __STDC_VERSION__

#include <astro/logging.h>
astro::log_level astro_log_verbosity = astro::log_level::none;

#include "application_tests.h"
#include "window_tests.h"

int main(int argc, char **argv)
{
  GREATEST_MAIN_BEGIN();      /* init & parse command-line args */

  if (greatest_info.flags & GREATEST_FLAG_VERBOSE)
    astro_log_verbosity = astro::log_level::debug;

  RUN_SUITE(application_tests);
  RUN_SUITE(window_tests);
  GREATEST_MAIN_END();        /* display results */
}
