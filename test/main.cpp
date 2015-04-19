/**
* Copyright 2015 Team Astro. All rights reserved.
*/

#include <stdio.h>

#include <greatest/greatest.h>
GREATEST_MAIN_DEFS();

#include "application_tests.h"

int main(int argc, char **argv)
{
  GREATEST_MAIN_BEGIN();      /* init & parse command-line args */
  RUN_SUITE(application_tests);
  GREATEST_MAIN_END();        /* display results */
}
