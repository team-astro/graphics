/**
* Copyright 2015 Team Astro. All rights reserved.
*/

#include <astro/astro.h>
#include <astro/memory.h>
using namespace astro;

#import <Cocoa/Cocoa.h>

#include <astro/graphics/application.h>
#include <astro/graphics/renderer.h>
#include "osx_window.h"

using namespace astro;
using namespace astro::graphics;

@interface Window : NSObject<NSWindowDelegate>
{
@public
  osx_window* ourWindow;
}
+ (Window*)sharedDelegate;
- (id)init;
@end


@implementation Window
+ (Window*)sharedDelegate
{
  static id window = [Window new];
  return window;
}

- (id)init
{
  self = [super init];
  if (!self)
    return nil;

  ourWindow = nullptr;

  return self;
}

- (void)windowDidResize:(NSNotification *)__unused notification
{
  draw_window(self->ourWindow, 0, true);
}

- (void)windowDidChangeBackingProperties:(NSNotification *)__unused notification
{
  // NOTE(matt): This handles moving between screens with different backing scale factor (retina/non-retina)
  // TODO(matt): Pass this notification out to UI code to update scale? May be unnecessary.
  log_debug("windowDidChangeBackingProperties");
  draw_window(self->ourWindow, 0, true);
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
  void null_on_key_change(window*, key_state) { }
  void null_on_mouse_change(window*, mouse_state) { }
  void null_on_touch_change(window*, touch_state) { }

  window*
  create_window(application* app,
                const char* title,
                uint16 width,
                uint16 height)
  {
    osx_window* window = push_struct<osx_window>(&app->stack);
    *window = {};
    window->title = push_string(&app->stack, title);
    window->width = width;
    window->height = height;

    window->on_key_change = null_on_key_change;
    window->on_mouse_change = null_on_mouse_change;
    window->on_touch_change = null_on_touch_change;
    window->app = app;

    push_list(&app->stack, &app->windows);
    app->windows->window = window;

    Window* delegate = [[Window alloc] init];
    delegate->ourWindow = window;

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

    window->context = create_swap_chain(window);

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
    NSWindow* nswin = osx_win->ns_window;

    swap_chain_make_current(win->context, resize);
    if (resize)
    {
      NSRect rect = [[nswin contentView] bounds];
      rect = [nswin convertRectToBacking:rect];
      win->width = rect.size.width;
      win->height = rect.size.height;

      win->pixel_ratio = [nswin backingScaleFactor];
      log_debug("set window pixel ratio to %g", win->pixel_ratio);
      [nswin setTitle:[NSString stringWithFormat:@"%s (%dx%d @ %gx)", osx_win->title, win->width, win->height, win->pixel_ratio]];
    }

    assert(win->on_render);
    win->on_render(win, delta_time);

    swap_chain_flush(win->context);
  }
}
}
