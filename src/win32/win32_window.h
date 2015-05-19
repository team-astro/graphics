/**
* Copyright 2015 Team Astro. All rights reserved.
*/

#include <astro/graphics/window.h>

namespace astro { namespace graphics
{
  struct win32_window : public window
  {
    HWND handle;
  };
}}
