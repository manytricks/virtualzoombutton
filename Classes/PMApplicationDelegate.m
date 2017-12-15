#import "PMApplicationDelegate.h"
#import "PMVirtualZoomButtonWindow.h"


// PMApplicationDelegate sets up a demo window. All the interesting functionality-related stuff is in PMVirtualZoomButtonWindow.m.

@implementation PMApplicationDelegate

	- (void)applicationDidFinishLaunching: (NSNotification *)notification {
		NSWindow *window = [[PMVirtualZoomButtonWindow alloc] initWithContentRect: NSMakeRect(0, 0, 600, 400) styleMask: NSBorderlessWindowMask | NSResizableWindowMask backing: NSBackingStoreBuffered defer: YES];
		window.hasShadow = YES;
		window.movableByWindowBackground = YES;
		window.minSize = NSMakeSize(100, 100);
		window.title = @"Virtual Zoom Button Demo Window";
		[window center];
		[window makeKeyAndOrderFront: self];
	}

@end
