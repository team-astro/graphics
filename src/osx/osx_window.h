/**
* Copyright 2015 Team Astro. All rights reserved.
*/

#include <astro/astro.h>
#include <astro/graphics/window.h>
#include <astro/graphics/context.h>
using namespace astro;

#import <Cocoa/Cocoa.h>

@class AstroRenderView;

namespace astro
{
namespace graphics
{
  struct osx_window : public window
  {
    NSWindow* ns_window;
    AstroRenderView* view;
    NSEventModifierFlags lastKeyFlags;
  };
}
}
