/**
* Copyright 2015 Team Astro. All rights reserved.
*/

#include <astro/astro.h>
#include <astro/memory.h>
#include <astro/graphics/application.h>
#include <astro/graphics/renderer.h>
#include "osx_window.h"

using namespace astro;
using namespace astro::graphics;

#import <OpenGL/OpenGL.h>
#import <OpenGL/gl3.h>

// TODO: Move AstroRenderView here to complete context api.
@interface AstroRenderView : NSOpenGLView
{
  CVDisplayLinkRef displayLink;
  osx_window* m_ourWindow;
}
@property osx_window* ourWindow;
- (instancetype)initWithFrame:(NSRect)frameRect pixelFormat:(NSOpenGLPixelFormat *)format platformWindow:(osx_window*)window;
@end

namespace astro { namespace graphics
{
  struct osx_swap_chain : public swap_chain
  {
    NSOpenGLPixelFormat* pixelFormat;
    AstroRenderView* view;
  };

  static void
  gl_context_on_render(window*, real32)
  {
    glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT | GL_STENCIL_BUFFER_BIT);
  }

  swap_chain*
  create_swap_chain(window* window)
  {
    osx_window* win = (osx_window*)window;
    NSWindow* nswin = win->ns_window;
    osx_swap_chain* chain = push_struct<osx_swap_chain>(&win->app->stack);

    NSOpenGLPixelFormatAttribute attrs[] =
    {
      NSOpenGLPFAAccelerated,
      NSOpenGLPFANoRecovery,
      NSOpenGLPFADoubleBuffer,
      NSOpenGLPFAColorSize, 24,
      NSOpenGLPFAAlphaSize, 8,
      NSOpenGLPFADepthSize, 24,
      NSOpenGLPFAStencilSize, 8,
      NSOpenGLPFAAccumSize, 0,
      NSOpenGLPFAOpenGLProfile,
      NSOpenGLProfileVersion3_2Core,
      0
    };

    chain->pixelFormat =
        [[NSOpenGLPixelFormat alloc] initWithAttributes:attrs];

    NSRect frame = NSMakeRect(0, 0, nswin.frame.size.width, nswin.frame.size.height);
    chain->view =
        [[AstroRenderView alloc] initWithFrame:frame pixelFormat:chain->pixelFormat platformWindow:win];
    [chain->view setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
    [chain->view setWantsBestResolutionOpenGLSurface:YES];

    [nswin setContentView:chain->view];
    [nswin setInitialFirstResponder:chain->view];

    win->on_render = gl_context_on_render;

    return chain;
  }

  void
  swap_chain_make_current(swap_chain* chain, bool resize)
  {
    osx_swap_chain* ctx = (osx_swap_chain*)chain;

    // NOTE(matt): Need to lock the context to avoid access between
    // resize (main thread) and CVDisplayLink (background thread)
    CGLLockContext([[ctx->view openGLContext] CGLContextObj]);
    if (resize)
    {
      NSRect rect = [ctx->view bounds];
      rect = [ctx->view convertRectToBacking:rect];
      glViewport(0, 0, (GLsizei)rect.size.width, (GLsizei)rect.size.height);
    }

    [[ctx->view openGLContext] makeCurrentContext];
  }

  void
  swap_chain_flush(swap_chain* chain)
  {
    osx_swap_chain* ctx = (osx_swap_chain*)chain;
    CGLFlushDrawable([[ctx->view openGLContext] CGLContextObj]);
    CGLUnlockContext([[ctx->view openGLContext] CGLContextObj]);
  }
}}

inline void
handle_key_change(osx_window* window, NSEvent* e)
{
  key_state result = {};

  //log_debug("handle_key_change");

  auto newFlags = ~window->lastKeyFlags & e.modifierFlags;
  auto oldFlags = window->lastKeyFlags & ~e.modifierFlags;
  //auto changed = newFlags | oldFlags;
  window->lastKeyFlags = e.modifierFlags;

  bool32 flagsKeyDown = oldFlags == 0 && newFlags != 0;

  result.key_pressed = (e.type == NSFlagsChanged && flagsKeyDown) || e.type == NSKeyDown;
  result.code = (key_code) e.keyCode;

  if (e.type == NSKeyDown || e.type == NSKeyUp)
  {
    result.repeat = e.ARepeat;
    assert(e.characters.length < sizeof(result.characters));
    assert(e.charactersIgnoringModifiers.length < sizeof(result.raw_characters));
    strncpy(&result.characters[0], e.characters.UTF8String, min(sizeof(result.characters), (size_t)e.characters.length));
    strncpy(&result.raw_characters[0], e.charactersIgnoringModifiers.UTF8String, min(sizeof(result.raw_characters), (size_t)e.charactersIgnoringModifiers.length));
  }

  window->on_key_change(window, result);

  // printf("key event - pressed: %d, code: %d, repeat: %d, chars: \"%s\", raw_chars: \"%s\" \n", result.key_pressed, result.code, result.repeat, result.characters, result.raw_characters);
}

inline void
handle_mouse_change(osx_window* window, NSEvent* e)
{
  mouse_state result = {};

  NSPoint loc = [window->ns_window mouseLocationOutsideOfEventStream];//[self convertPoint:theEvent.locationInWindow fromView:self];
  loc.y = (window->height / window->pixel_ratio) - loc.y;
  bool32 mouse_down = e.type == NSLeftMouseDown || e.type == NSRightMouseDown || e.type == NSOtherMouseDown;
  bool32 mouse_up = e.type == NSLeftMouseUp || e.type == NSRightMouseUp || e.type == NSOtherMouseUp;
  result.button_pressed = mouse_down;
  result.position = { (real32) loc.x, (real32) loc.y };
  result.wheel = { (real32) e.deltaX, (real32) e.deltaY, (real32) e.deltaZ };
  if (mouse_down || mouse_up)
  {
    result.button = e.buttonNumber;
    result.pressure = e.pressure;
    result.click_count = e.clickCount;
  }

  if (e.type == NSScrollWheel)
  {
    //log_debug("wheel - precise: %d, dX: %g, dY: %g\n", e.hasPreciseScrollingDeltas, (real32) e.scrollingDeltaX, (real32) e.scrollingDeltaY);
  }

  window->on_mouse_change(window, result);

  //log_debug("mouse event - pressed: %d, pos: (%g, %g), wheel: (%g, %g, %g), button: %d, pressure: %g, count: %d\n", result.button_pressed, result.position.x, result.position.y, result.wheel.x, result.wheel.y, result.wheel.z, result.button, result.pressure, result.click_count);
}

inline void
handle_touch_change(osx_window* window, NSEvent* e)
{
  touch_state result = {};
  window->on_touch_change(window, result);

  // switch (e.type)
  // {
  // case NSEventTypeMagnify:
  //   NSLog(@"magnify");
  //   break;
  // case NSEventTypeSwipe:
  //   NSLog(@"swipe");
  //   break;
  // case NSEventTypeRotate:
  //   NSLog(@"rotate");
  //   break;
  // default:
  //   NSLog(@"unknown touch event type: %lld", (uint64)e.type);
  //   break;
  // }

  NSSet* touch_match = [e touchesMatchingPhase:NSTouchPhaseAny inView:window->ns_window.contentView];
  NSArray* array = [touch_match allObjects];

  assert(touch_match.count < sizeof(result.touches));

  //log_debug("touch event -");
  touch_info* ti = result.touches;
  for (uint32 touch_index = 0; touch_index < touch_match.count; ++touch_index, ++ti)
  {
    NSTouch* touch = [array objectAtIndex:touch_index];
    ti->index = touch_index; // NOTE(matt): Might not be the same as finger?
    ti->position = { (real32) touch.normalizedPosition.x, (real32) touch.normalizedPosition.y };
    ti->phase = (touch_phase) touch.phase;
    //NSLog(@"  touch %d - identity %@, phase: %lld, pos: (%g, %g)", touch_index, touch.identity, (uint64)touch.phase, touch.normalizedPosition.x, touch.normalizedPosition.y);
  }

  window->on_touch_change(window, result);
}

static CVReturn
DisplayLinkCallback(CVDisplayLinkRef,
                    const CVTimeStamp*,
                    const CVTimeStamp* outputTime,
                    CVOptionFlags,
                    CVOptionFlags*,
                    void* context)
{
  osx_window* window = (osx_window*)context;
  real32 deltaTime = 1.0f / (outputTime->rateScalar * (real32)outputTime->videoTimeScale / (real32)outputTime->videoRefreshPeriod);
  draw_window(window, deltaTime, false);

  return kCVReturnSuccess;
}

@implementation AstroRenderView
@synthesize ourWindow = m_ourWindow;
- (instancetype)initWithFrame:(NSRect)frameRect pixelFormat:(NSOpenGLPixelFormat *)format platformWindow:(osx_window*)ourWindow
{
  self = [super initWithFrame:frameRect pixelFormat:format];
  if (self)
  {
    self.ourWindow = ourWindow;
    [self setAcceptsTouchEvents:YES];
    [self setWantsRestingTouches:YES];
  }

  return self;
}

- (BOOL)acceptsFirstResponder
{
  NSLog(@"AstroRenderView: acceptsFirstResponder");
  return YES;
}

- (BOOL)becomeFirstResponder
{
  NSLog(@"AstroRenderView: becomeFirstResponder");
  return YES;
}

- (BOOL)resignFirstResponder
{
  NSLog(@"AstroRenderView: resignFirstResponder");
  return YES;
}

- (BOOL)acceptsFirstMouse:(NSEvent*)__unused theEvent
{
  NSLog(@"AstroRenderView: acceptsFirstMouse");
  return YES;
}

- (void)mouseDown:(NSEvent *)theEvent
{
  handle_mouse_change(self.ourWindow, theEvent);
}

- (void)mouseUp:(NSEvent *)theEvent
{
  handle_mouse_change(self.ourWindow, theEvent);
}

- (void)mouseMoved:(NSEvent *)theEvent
{
  handle_mouse_change(self.ourWindow, theEvent);
}

- (void)mouseDragged:(NSEvent *)theEvent
{
  handle_mouse_change(self.ourWindow, theEvent);
}

- (void)scrollWheel:(NSEvent *)theEvent {
  handle_mouse_change(self.ourWindow, theEvent);
}

- (void)rightMouseDown:(NSEvent *)theEvent
{
  handle_mouse_change(self.ourWindow, theEvent);
}

- (void)rightMouseUp:(NSEvent *)theEvent
{
  handle_mouse_change(self.ourWindow, theEvent);
}

- (void)rightMouseDragged:(NSEvent *)theEvent
{
  handle_mouse_change(self.ourWindow, theEvent);
}

- (void)otherMouseDown:(NSEvent *)theEvent
{
  handle_mouse_change(self.ourWindow, theEvent);
}

- (void)otherMouseUp:(NSEvent *)theEvent
{
  handle_mouse_change(self.ourWindow, theEvent);
}

- (void)otherMouseDragged:(NSEvent *)theEvent
{
  handle_mouse_change(self.ourWindow, theEvent);
}

- (void)keyDown:(NSEvent *)theEvent
{
  handle_key_change(self.ourWindow, theEvent);
}

- (void)keyUp:(NSEvent *)theEvent
{
  handle_key_change(self.ourWindow, theEvent);
}

- (void)flagsChanged:(NSEvent *)theEvent
{
  handle_key_change(self.ourWindow, theEvent);
}

- (void)touchesBeganWithEvent:(NSEvent *)theEvent
{
  handle_touch_change(self.ourWindow, theEvent);
}

- (void)touchesMovedWithEvent:(NSEvent *)theEvent
{
  handle_touch_change(self.ourWindow, theEvent);
}

- (void)touchesEndedWithEvent:(NSEvent *)theEvent
{
  handle_touch_change(self.ourWindow, theEvent);
}

- (void)touchesCancelledWithEvent:(NSEvent *)theEvent
{
  handle_touch_change(self.ourWindow, theEvent);
}

- (void)rotateWithEvent:(NSEvent *)theEvent
{
  handle_touch_change(self.ourWindow, theEvent);
}

- (void)magnifyWithEvent:(NSEvent *)theEvent
{
  handle_touch_change(self.ourWindow, theEvent);
}

- (void)swipeWithEvent:(NSEvent *)theEvent
{
  handle_touch_change(self.ourWindow, theEvent);
}

- (void)prepareOpenGL
{
  GLint swapInterval = 0;
  [[self openGLContext] setValues:&swapInterval
                     forParameter:NSOpenGLCPSwapInterval];

  //AstroWindowDelegate* windowDelegate = (AstroWindowDelegate*)self.window.delegate;

  CVDisplayLinkCreateWithActiveCGDisplays(&displayLink);
  CVDisplayLinkSetOutputCallback(
      displayLink, DisplayLinkCallback, (void *)m_ourWindow);

  CGLContextObj context = [[self openGLContext] CGLContextObj];
  CGLPixelFormatObj pixelFormat = [[self pixelFormat] CGLPixelFormatObj];
  CGLSetParameter(context, kCGLCPSwapInterval, &swapInterval);
  CVDisplayLinkSetCurrentCGDisplayFromOpenGLContext(
      displayLink, context, pixelFormat);

  CVDisplayLinkStart(displayLink);
}
@end
