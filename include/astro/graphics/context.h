/**
* Copyright 2015 Team Astro. All rights reserved.
*/

#ifndef ASTRO_GFX_GL
#define ASTRO_GFX_GL

#include <astro/astro.h>

namespace astro
{
namespace graphics
{
  struct window;
  struct context {};

  context*
  create_context(window* window);

  void
  context_make_current(context* context, bool resize);

  void
  context_flush(context* context);
}
}


#endif
