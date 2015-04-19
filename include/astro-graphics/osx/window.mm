#include <astro/astro.h>
#include <astro/memory.h>
using namespace astro;

#import <OpenGL/OpenGL.h>
#import <OpenGL/gl3.h>

@class GammaRenderView;

namespace astro
{
namespace graphics
{
  struct osx_window : public window
  {
    NSWindow* ns_window;
    GammaRenderView* view;
    NSEventModifierFlags lastKeyFlags;
  };
}
}

using namespace astro::graphics;

inline void
handle_key_change(osx_window* window, NSEvent* e)
{
  key_state result = {};

  auto newFlags = ~window->lastKeyFlags & e.modifierFlags;
  auto oldFlags = window->lastKeyFlags & ~e.modifierFlags;
  auto changed = newFlags | oldFlags;
  window->lastKeyFlags = e.modifierFlags;

  bool32 flagsKeyDown = oldFlags == 0 && newFlags != 0;

  result.key_pressed = (e.type == NSFlagsChanged && flagsKeyDown) || e.type == NSKeyDown;
  result.code = e.keyCode;

  if (e.type == NSKeyDown || e.type == NSKeyUp)
  {
    result.repeat = e.ARepeat;
    assert(e.characters.length < sizeof(result.characters));
    assert(e.charactersIgnoringModifiers.length < sizeof(result.raw_characters));
    strncpy(&result.characters[0], e.characters.UTF8String, min(sizeof(result.characters), e.characters.length));
    strncpy(&result.raw_characters[0], e.charactersIgnoringModifiers.UTF8String, min(sizeof(result.raw_characters), e.charactersIgnoringModifiers.length));
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

  // if (e.type == NSScrollWheel)
  // {
  //   printf("wheel - precise: %d, dX: %g, dY: %g\n", e.hasPreciseScrollingDeltas, (real32) e.scrollingDeltaX, (real32) e.scrollingDeltaY);
  // }

  window->on_mouse_change(window, result);

  // printf("mouse event - pressed: %d, pos: (%g, %g), wheel: (%g, %g, %g), button: %d, pressure: %g, count: %d\n", result.button_pressed, result.position.x, result.position.y, result.wheel.x, result.wheel.y, result.wheel.z, result.button, result.pressure, result.click_count);
}

inline void
handle_touch_change(osx_window* window, NSEvent* e)
{
  touch_state result = {};
  window->on_touch_change(window, result);

  switch (e.type)
  {
  case NSEventTypeMagnify:
    NSLog(@"magnify");
    break;
  case NSEventTypeSwipe:
    NSLog(@"swipe");
    break;
  case NSEventTypeRotate:
    NSLog(@"rotate");
    break;
  default:
    NSLog(@"unknown touch event type: %ld", e.type);
    break;
  }

  NSSet* touch_match = [e touchesMatchingPhase:NSTouchPhaseAny inView:window->ns_window.contentView];
  NSArray* array = [touch_match allObjects];

  assert(touch_match.count < sizeof(result.touches));

  printf("touch event - \n");
  touch_info* ti = result.touches;
  for (int touch_index = 0; touch_index < touch_match.count; ++touch_index, ++ti)
  {
    NSTouch* touch = [array objectAtIndex:touch_index];
    ti->index = touch_index; // NOTE(matt): Might not be the same as finger?
    ti->position = { (real32) touch.normalizedPosition.x, (real32) touch.normalizedPosition.y };
    ti->phase = (touch_phase) touch.phase;
    NSLog(@"  touch %d - identity %@, phase: %ld, pos: (%g, %g)", touch_index, touch.identity, touch.phase, touch.normalizedPosition.x, touch.normalizedPosition.y);
  }

  window->on_touch_change(window, result);
}

@interface GammaRenderView : NSOpenGLView
{
@public
  CVDisplayLinkRef displayLink;
}
@property osx_window* gammaWindow;
- (instancetype)initWithFrame:(NSRect)frameRect pixelFormat:(NSOpenGLPixelFormat *)format platformWindow:(osx_window*)window;
@end

@interface GammaWindowDelegate : NSObject <NSWindowDelegate>
@property osx_window* gammaWindow;
@end

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

@implementation GammaRenderView
- (instancetype)initWithFrame:(NSRect)frameRect pixelFormat:(NSOpenGLPixelFormat *)format platformWindow:(osx_window*)gammaWindow
{
  self = [super initWithFrame:frameRect pixelFormat:format];
  if (self)
  {
    self.gammaWindow = gammaWindow;
    [self setAcceptsTouchEvents:YES];
    [self setWantsRestingTouches:YES];
  }

  return self;
}

- (BOOL)acceptsFirstResponder
{
  NSLog(@"GammaRenderView: acceptsFirstResponder");
  return YES;
}

- (BOOL)becomeFirstResponder
{
  NSLog(@"GammaRenderView: becomeFirstResponder");
  return YES;
}

- (BOOL)resignFirstResponder
{
  NSLog(@"GammaRenderView: resignFirstResponder");
  return YES;
}

- (BOOL)acceptsFirstMouse:(NSEvent*)theEvent
{
  NSLog(@"GammaRenderView: acceptsFirstMouse");
  return YES;
}

- (void)mouseDown:(NSEvent *)theEvent
{
  handle_mouse_change(self.gammaWindow, theEvent);
}

- (void)mouseUp:(NSEvent *)theEvent
{
  handle_mouse_change(self.gammaWindow, theEvent);
}

- (void)mouseMoved:(NSEvent *)theEvent
{
  handle_mouse_change(self.gammaWindow, theEvent);
}

- (void)mouseDragged:(NSEvent *)theEvent
{
  handle_mouse_change(self.gammaWindow, theEvent);
}

- (void)scrollWheel:(NSEvent *)theEvent {
  handle_mouse_change(self.gammaWindow, theEvent);
}

- (void)rightMouseDown:(NSEvent *)theEvent
{
  handle_mouse_change(self.gammaWindow, theEvent);
}

- (void)rightMouseUp:(NSEvent *)theEvent
{
  handle_mouse_change(self.gammaWindow, theEvent);
}

- (void)rightMouseDragged:(NSEvent *)theEvent
{
  handle_mouse_change(self.gammaWindow, theEvent);
}

- (void)otherMouseDown:(NSEvent *)theEvent
{
  handle_mouse_change(self.gammaWindow, theEvent);
}

- (void)otherMouseUp:(NSEvent *)theEvent
{
  handle_mouse_change(self.gammaWindow, theEvent);
}

- (void)otherMouseDragged:(NSEvent *)theEvent
{
  handle_mouse_change(self.gammaWindow, theEvent);
}

- (void)keyDown:(NSEvent *)theEvent
{
  handle_key_change(self.gammaWindow, theEvent);
}

- (void)keyUp:(NSEvent *)theEvent
{
  handle_key_change(self.gammaWindow, theEvent);
}

- (void)flagsChanged:(NSEvent *)theEvent
{
  handle_key_change(self.gammaWindow, theEvent);
}

- (void)touchesBeganWithEvent:(NSEvent *)theEvent
{
  handle_touch_change(self.gammaWindow, theEvent);
}

- (void)touchesMovedWithEvent:(NSEvent *)theEvent
{
  handle_touch_change(self.gammaWindow, theEvent);
}

- (void)touchesEndedWithEvent:(NSEvent *)theEvent
{
  handle_touch_change(self.gammaWindow, theEvent);
}

- (void)touchesCancelledWithEvent:(NSEvent *)theEvent
{
  handle_touch_change(self.gammaWindow, theEvent);
}

- (void)rotateWithEvent:(NSEvent *)theEvent
{
  handle_touch_change(self.gammaWindow, theEvent);
}

- (void)magnifyWithEvent:(NSEvent *)theEvent
{
  handle_touch_change(self.gammaWindow, theEvent);
}

- (void)swipeWithEvent:(NSEvent *)theEvent
{
  handle_touch_change(self.gammaWindow, theEvent);
}

- (void)prepareOpenGL
{
  GLint swapInterval = 0;
  [[self openGLContext] setValues:&swapInterval
                     forParameter:NSOpenGLCPSwapInterval];

  GammaWindowDelegate* windowDelegate = (GammaWindowDelegate*)self.window.delegate;

  CVDisplayLinkCreateWithActiveCGDisplays(&displayLink);
  CVDisplayLinkSetOutputCallback(
      displayLink, DisplayLinkCallback, (__bridge void *)windowDelegate.gammaWindow);

  CGLContextObj context = [[self openGLContext] CGLContextObj];
  CGLPixelFormatObj pixelFormat = [[self pixelFormat] CGLPixelFormatObj];
  CGLSetParameter(context, kCGLCPSwapInterval, &swapInterval);
  CVDisplayLinkSetCurrentCGDisplayFromOpenGLContext(
      displayLink, context, pixelFormat);

  CVDisplayLinkStart(displayLink);
}
@end

@implementation GammaWindowDelegate
@synthesize gammaWindow;

- (void)windowDidResize:(NSNotification *)notification
{
  draw_window(gammaWindow, 0, true);
}

- (void)windowDidChangeBackingProperties:(NSNotification *)notification
{
  // NOTE(matt): This handles moving between screens with different backing scale factor (retina/non-retina)
  // TODO(matt): Pass this notification out to UI code to update scale? May be unnecessary.
  draw_window(gammaWindow, 0, true);
}

// - (NSRect)window:(NSWindow *)window willPositionSheet:(NSWindow *)sheet
// usingRect:(NSRect)rect { }
// - (void)windowWillBeginSheet:(NSNotification *)notification { }
// - (void)windowDidEndSheet:(NSNotification *)notification { }
// - (NSSize)windowWillResize:(NSWindow *)sender toSize:(NSSize)frameSize { }
// - (void)windowDidResize:(NSNotification *)notification { }
// - (void)windowWillStartLiveResize:(NSNotification *)notification { }
// - (void)windowDidEndLiveResize:(NSNotification *)notification { }
// - (void)windowWillMiniaturize:(NSNotification *)notification { }
// - (void)windowDidMiniaturize:(NSNotification *)notification { }
// - (void)windowDidDeminiaturize:(NSNotification *)notification { }
// - (NSRect)windowWillUseStandardFrame:(NSWindow *)window
// defaultFrame:(NSRect)newFrame { }
// - (BOOL)windowShouldZoom:(NSWindow *)window toFrame:(NSRect)newFrame { }
// - (NSSize)window:(NSWindow *)window
// willUseFullScreenContentSize:(NSSize)proposedSize { }
// - (NSApplicationPresentationOptions)window:(NSWindow *)window
// willUseFullScreenPresentationOptions:(NSApplicationPresentationOptions)proposedOptions
// { }
// - (void)windowWillEnterFullScreen:(NSNotification *)notification { }
// - (void)windowDidEnterFullScreen:(NSNotification *)notification { }
// - (void)windowWillExitFullScreen:(NSNotification *)notification { }
// - (void)windowDidExitFullScreen:(NSNotification *)notification { }
// - (NSArray *)customWindowsToEnterFullScreenForWindow:(NSWindow *)window { }
// - (NSArray *)customWindowsToEnterFullScreenForWindow:(NSWindow *)window
// onScreen:(NSScreen *)screen { }
// - (void)window:(NSWindow *)window
// startCustomAnimationToEnterFullScreenWithDuration:(NSTimeInterval)duration {
// }
// - (void)window:(NSWindow *)window
// startCustomAnimationToEnterFullScreenOnScreen:(NSScreen *)screen
// withDuration:(NSTimeInterval)duration { }
// - (void)windowDidFailToEnterFullScreen:(NSWindow *)window { }
// - (NSArray *)customWindowsToExitFullScreenForWindow:(NSWindow *)window { }
// - (void)window:(NSWindow *)window
// startCustomAnimationToExitFullScreenWithDuration:(NSTimeInterval)duration { }
// - (void)windowDidFailToExitFullScreen:(NSWindow *)window { }
// - (void)windowWillMove:(NSNotification *)notification { }
// - (void)windowDidMove:(NSNotification *)notification { }
// - (void)windowDidChangeScreen:(NSNotification *)notification { }
// - (void)windowDidChangeScreenProfile:(NSNotification *)notification { }
// - (void)windowDidChangeBackingProperties:(NSNotification *)notification { }
// - (BOOL)windowShouldClose:(id)sender { }
// - (void)windowWillClose:(NSNotification *)notification { }
// - (void)windowDidBecomeKey:(NSNotification *)notification { }
// - (void)windowDidResignKey:(NSNotification *)notification { }
// - (void)windowDidBecomeMain:(NSNotification *)notification { }
// - (void)windowDidResignMain:(NSNotification *)notification { }
// - (id)windowWillReturnFieldEditor:(NSWindow *)sender toObject:(id)client { }
// - (void)windowDidUpdate:(NSNotification *)notification { }
// - (void)windowDidExpose:(NSNotification *)notification { }
// - (void)windowDidChangeOcclusionState:(NSNotification *)notification { }
// - (BOOL)window:(NSWindow *)window shouldDragDocumentWithEvent:(NSEvent
// *)event from:(NSPoint)dragImageLocation withPasteboard:(NSPasteboard
// *)pasteboard { }
// - (NSUndoManager *)windowWillReturnUndoManager:(NSWindow *)window { }
// - (BOOL)window:(NSWindow *)window shouldPopUpDocumentPathMenu:(NSMenu *)menu
// { }
// - (void)window:(NSWindow *)window willEncodeRestorableState:(NSCoder *)state
// { }
// - (void)window:(NSWindow *)window didDecodeRestorableState:(NSCoder *)state {
// }
// - (NSSize)window:(NSWindow *)window
// willResizeForVersionBrowserWithMaxPreferredSize:(NSSize)maxPreferredSize
// maxAllowedSize:(NSSize)maxAllowedSize { }
// - (void)windowWillEnterVersionBrowser:(NSNotification *)notification { }
// - (void)windowDidEnterVersionBrowser:(NSNotification *)notification { }
// - (void)windowWillExitVersionBrowser:(NSNotification *)notification { }
// - (void)windowDidExitVersionBrowser:(NSNotification *)notification { }
@end

namespace astro
{
namespace graphics
{
  void
  null_on_render(window*, real32)
  {
    glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT | GL_STENCIL_BUFFER_BIT);
  }

  void null_on_key_change(window*, key_state) { }
  void null_on_mouse_change(window*, mouse_state) { }
  void null_on_touch_change(window*, touch_state) { }

  window*
  create_window(application* app,
                const char* title,
                uint16 width,
                uint16 height)
  {
    osx_window* window = push_struct<osx_window>(app->pool);
    *window = {};
    window->title = push_string(app->pool, title);
    window->width = width;
    window->height = height;
    window->on_render = null_on_render;
    window->on_key_change = null_on_key_change;
    window->on_mouse_change = null_on_mouse_change;
    window->on_touch_change = null_on_touch_change;

    push_list(app->pool, &app->windows);
    app->windows->window = window;

    GammaWindowDelegate* delegate = [[GammaWindowDelegate alloc] init];
    delegate.gammaWindow = window;

    NSRect frame = NSMakeRect(0, 0, width, height);
    NSUInteger windowMask = NSTitledWindowMask | NSClosableWindowMask |
                            NSMiniaturizableWindowMask | NSResizableWindowMask;

    window->ns_window =
        [[NSWindow alloc] initWithContentRect:frame
                                    styleMask:windowMask
                                      backing:NSBackingStoreBuffered
                                        defer:NO];

    [window->ns_window
        setTitle:[NSString stringWithCString:title
                                    encoding:NSUTF8StringEncoding]];
    [window->ns_window setDelegate:delegate];
    [window->ns_window setAcceptsMouseMovedEvents:YES];

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

    NSOpenGLPixelFormat* pixelFormat =
        [[NSOpenGLPixelFormat alloc] initWithAttributes:attrs];

    window->view =
        [[GammaRenderView alloc] initWithFrame:frame pixelFormat:pixelFormat platformWindow:window];
    [window->view setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
    [window->view setWantsBestResolutionOpenGLSurface:YES];

    [window->ns_window setContentView:window->view];
    [window->ns_window setInitialFirstResponder:window->view];

    [window->ns_window setPreservesContentDuringLiveResize:NO];
    [window->ns_window makeKeyAndOrderFront:nil];

    [window->ns_window center];

    draw_window(window, 0, true);

    return window;
  }

  void
  draw_window(window* win, real32 delta_time, bool32 resize)
  {
    osx_window* osx_win = (osx_window*) win;

    // NOTE(matt): Need to lock the context to avoid siastroltaneous access between
    // resize (main thread) and CVDisplayLink (background thread)
    CGLLockContext([[osx_win->view openGLContext] CGLContextObj]);
    if (resize)
    {
      NSRect rect = [osx_win->view bounds];
      rect = [osx_win->view convertRectToBacking:rect];
      win->width = rect.size.width;
      win->height = rect.size.height;

      win->pixel_ratio = [osx_win->ns_window backingScaleFactor];
      [osx_win->ns_window setTitle:[NSString stringWithFormat:@"%s (%dx%d @ %gx)", osx_win->title, win->width, win->height, win->pixel_ratio]];
      glViewport(0, 0, (GLsizei)rect.size.width, (GLsizei)rect.size.height);
    }

    [[osx_win->view openGLContext] makeCurrentContext];

    assert(win->on_render);
    win->on_render(win, delta_time);

    CGLFlushDrawable([[osx_win->view openGLContext] CGLContextObj]);
    CGLUnlockContext([[osx_win->view openGLContext] CGLContextObj]);
  }
}
}
