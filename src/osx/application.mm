/**
* Copyright 2015 Team Astro. All rights reserved.
*/

#include <astro/astro.h>
#include <astro/memory.h>

#import <Cocoa/Cocoa.h>

@interface AstroApplication : NSApplication<NSApplicationDelegate>
- (id)init;
- (void)runOnce;
@property astro::graphics::application* astroApplication;
@end

namespace astro
{
namespace graphics
{
  struct osx_application : application
  {
    AstroApplication* ns_app;
  };

  static void
  null_app_event(application* app) { }

  application*
  create_application(uintptr heap_size)
  {
    if (NSAppKitVersionNumber < NSAppKitVersionNumber10_7)
    {
      NSLog(@"OS X Lion (version 10.7) or later required");
      exit(EXIT_FAILURE);
    }

    uint8* heap = (uint8*)malloc(heap_size);
    if (!heap)
    {
      exit(EXIT_FAILURE);
    }

    osx_application* app = (osx_application*) heap;
    app->on_startup = null_app_event;
    app->on_shutdown = null_app_event;

    heap += sizeof(osx_application);
    heap_size -= sizeof(osx_application);

    initialize_memory_stack(&app->stack, heap_size, heap);

    // http://www.cocoawithlove.com/2009/01/demystifying-nsapplication-by.html
    NSDictionary *infoDictionary = [[NSBundle mainBundle] infoDictionary];
    Class principalClass =
      NSClassFromString([infoDictionary objectForKey:@"NSPrincipalClass"]);
    // NSAssert([principalClass respondsToSelector:@selector(sharedApplication)],
    //  @"Principal class astrost implement sharedApplication.");
    NSApplication *applicationObject = [principalClass sharedApplication];
    app->ns_app = (AstroApplication*) applicationObject;
    [app->ns_app setAstroApplication:app];

    NSString *mainNibName = [infoDictionary objectForKey:@"NSMainNibFile"];
    if (mainNibName)
    {
      NSNib *mainNib =
        [[NSNib alloc] initWithNibNamed:mainNibName bundle:[NSBundle mainBundle]];
      [mainNib instantiateWithOwner:applicationObject topLevelObjects:nil];
    }

    [[NSPasteboard generalPasteboard] declareTypes:[NSArray arrayWithObject:NSStringPboardType] owner:nil];

    app->is_running = true;

    @autoreleasepool
    {
      [app->ns_app finishLaunching];
    }

    return app;
  }

  void
  quit_application(application* app)
  {
    app->is_running = false;

    osx_application* osx_app = (osx_application*)app;
    [osx_app->ns_app terminate:osx_app->ns_app];
  }

  void
  dispose_application(application* app)
  {
    app->is_running = false;
  }

  void
  update_application(application* app)
  {
    osx_application* osx_app = (osx_application*)app;
    [osx_app->ns_app runOnce];
  }

  void
  set_clipboard_text(const char* text)
  {
    NSString* str = [NSString stringWithCString:text encoding:NSUTF8StringEncoding];
    [[NSPasteboard generalPasteboard] setString:str forType:NSStringPboardType];
  }

  const char*
  get_clipboard_text(memory_stack* stack)
  {
    NSString* str = [[NSPasteboard generalPasteboard] stringForType:NSStringPboardType];
    return push_string(stack, [str UTF8String]);
  }
}
}

@implementation AstroApplication
- (id)init
{
  self = [super init];
  if (!self) return nil;

  [self setDelegate:self];

  return self;
}

- (void)runOnce
{
  @autoreleasepool
  {
    NSEvent *event = nil;
    do
    {
      event =
        [self
            nextEventMatchingMask:NSAnyEventMask
            untilDate:nil
            inMode:NSDefaultRunLoopMode
            dequeue:YES];

      if (event)
      {
        //NSLog(@"Event: %@", event);
        [self sendEvent:event];
        [self updateWindows];
      }
    }
    while (event);
  }
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender
{
  return NSTerminateNow;
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)app
{
  return YES;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
  [NSApp setActivationPolicy:NSApplicationActivationPolicyRegular];
  [NSFontManager sharedFontManager];

  // Because activation policy has just been set to behave like a real
  // application, that policy astrost be reset on exit to prevent, among other
  // things, the menubar created here from remaining on screen.
  // atexit_b(^ {
  //     [NSApp setActivationPolicy:NSApplicationActivationPolicyProhibited];
  // });

  id menubar = [[NSMenu alloc] init];
  id appMenuItem = [[NSMenuItem alloc] init];
  [menubar addItem:appMenuItem];

  id appMenu = [[NSMenu alloc] init];
  id appName = [[NSProcessInfo processInfo] processName];
  id quitTitle = [@"Quit " stringByAppendingString:appName];
  id quitMenuItem = [[NSMenuItem alloc] initWithTitle:quitTitle
                                               action:@selector(terminate:)
                                        keyEquivalent:@"q"];

  [appMenu addItem:quitMenuItem];
  [appMenuItem setSubmenu:appMenu];
  [NSApp setMainMenu:menubar];

  auto astro_app = [self astroApplication];
  astro_app->on_startup(astro_app);
}

- (void)applicationWillTerminate:(NSNotification *)aNotification
{
  auto astro_app = [self astroApplication];
  astro_app->on_shutdown(astro_app);
}

// - (void)applicationWillFinishLaunching:(NSNotification *)aNotification { }
// - (void)applicationWillBecomeActive:(NSNotification *)aNotification { }
// - (void)applicationDidBecomeActive:(NSNotification *)aNotification { }
// - (void)applicationWillResignActive:(NSNotification *)aNotification { }
// - (void)applicationDidResignActive:(NSNotification *)aNotification { }
// - (void)applicationWillHide:(NSNotification *)aNotification { }
// - (void)applicationDidHide:(NSNotification *)aNotification { }
// - (void)applicationWillUnhide:(NSNotification *)aNotification { }
// - (void)applicationDidUnhide:(NSNotification *)aNotification { }
// - (void)applicationWillUpdate:(NSNotification *)aNotification { }
// - (void)applicationDidUpdate:(NSNotification *)aNotification { }
// - (BOOL)applicationShouldHandleReopen:(NSApplication *)app hasVisibleWindows:(BOOL)flag { }
// - (NSMenu *)applicationDockMenu:(NSApplication *)sender { }
// - (NSError *)application:(NSApplication *)app willPresentError:(NSError *)error { }
// - (void)applicationDidChangeScreenParameters:(NSNotification *)aNotification { }
// - (BOOL)application:(NSApplication *)app openFile:(NSString *)filename { }
// - (BOOL)application:(id)sender openFileWithoutUI:(NSString *)filename { }
// - (BOOL)application:(NSApplication *)app openTempFile:(NSString *)filename { }
// - (void)application:(NSApplication *)sender openFiles:(NSArray *)filenames { }
// - (BOOL)applicationOpenUntitledFile:(NSApplication *)app { }
// - (BOOL)applicationShouldOpenUntitledFile:(NSApplication *)sender { }
// - (BOOL)application:(NSApplication *)app printFile:(NSString *)filename { }
// - (NSApplicationPrintReply)application:(NSApplication *)app printFiles:(NSArray *)fileNames withSettings:(NSDictionary *)printSettings showPrintPanels:(BOOL)showPrintPanels { }
// - (void)application:(NSApplication *)app didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken { }
// - (void)application:(NSApplication *)app didFailToRegisterForRemoteNotificationsWithError:(NSError *)error { }
// - (void)application:(NSApplication *)app didReceiveRemoteNotification:(NSDictionary *)userInfo { }
// - (void)application:(NSApplication *)app didDecodeRestorableState:(NSCoder *)coder { }
// - (void)application:(NSApplication *)app willEncodeRestorableState:(NSCoder *)coder { }
// - (BOOL)application:(NSApplication *)app willContinueUserActivityWithType:(NSString *)userActivityType { }
// - (BOOL)application:(NSApplication *)app continueUserActivity:(NSUserActivity *)userActivity restorationHandler:(void (^)(NSArray *restorableObjects))restorationHandler { }
// - (void)application:(NSApplication *)app didFailToContinueUserActivityWithType:(NSString *)userActivityType error:(NSError *)error { }
// - (void)application:(NSApplication *)app didFailToContinueUserActivityWithType:(NSString *)userActivityType error:(NSError *)error { }
// - (void)applicationDidChangeOcclusionState:(NSNotification *)notification { }
@end
