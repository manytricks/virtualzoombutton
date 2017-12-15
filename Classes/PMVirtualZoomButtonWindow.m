#import "PMVirtualZoomButtonWindow.h"


// PMVirtualZoomButtonElement fakes a zoom button in terms of accessibility. It's not an actual button, and it's not on screen.

@interface PMVirtualZoomButtonElement: NSAccessibilityElement <NSAccessibilityButton>

	@property (nonatomic, assign) NSWindow *window;

@end

@implementation PMVirtualZoomButtonElement

	- (id)accessibilityParent {
		return self.window;
	}

	- (id)accessibilityWindow {
		return self.window;
	}

	- (NSString *)accessibilitySubrole {
		return NSAccessibilityFullScreenButtonSubrole;
	}

	- (NSString *)accessibilityLabel {
		return self.accessibilityRoleDescription;	// the label isn't actually used anywhere, but implementing it is required for NSAccessibilityButtons, so let's just borrow the role description instead of burdening ourselves with something we have to localize
	}

	- (NSRect)accessibilityFrame {
		NSRect frame = self.window.frame;
		CGFloat zoomButtonSize = 20;
		return NSMakeRect(frame.origin.x + frame.size.width - zoomButtonSize, frame.origin.y + frame.size.height - zoomButtonSize, zoomButtonSize, zoomButtonSize);	// arbitrary zoom button frame in global coordinates (if this were to match a Windows zoom button, it would probably have to take themes into account)
	}

	- (BOOL)isAccessibilityEnabled {
		return YES;	// simulate a real button's enabled state (zoom buttons can exist, but be disabled for non-resizable windows, which is why Moom checks this)
	}

	- (BOOL)accessibilityPerformPress {
		[self.window performZoom: self];	// you might want to replace with something that mirrors your window's intended zooming behavior more closely
		return YES;
	}

@end


// PMVirtualZoomButtonWindow manages a PMVirtualZoomButtonElement as a private implementation detail and overrides some of a borderless window's default behavior.

@interface PMVirtualZoomButtonWindow ()

	@property (nonatomic, retain) PMVirtualZoomButtonElement *zoomButtonElement;

@end

@implementation PMVirtualZoomButtonWindow

	- (PMVirtualZoomButtonElement *)zoomButtonElement {
		if (_zoomButtonElement==nil) {
			_zoomButtonElement = [[PMVirtualZoomButtonElement alloc] init];
			_zoomButtonElement.window = self;
		}
		return _zoomButtonElement;
	}

	- (NSArray *)accessibilityChildren {
		NSArray *children = [super accessibilityChildren];
		return ((children==nil) ? [NSArray arrayWithObject: self.zoomButtonElement] : [children arrayByAddingObject: self.zoomButtonElement]);
	}

	- (id)accessibilityFullScreenButton {
		return self.zoomButtonElement;
	}

	- (id)accessibilityZoomButton {
		return self.zoomButtonElement;
	}

	- (NSString *)accessibilitySubrole {
		return NSAccessibilityStandardWindowSubrole;	// not strictly necessary, but borderless windows are AXDialogs by default, and that might not be the best match for what your windows actually represent
	}

	- (BOOL)canBecomeKeyWindow {
		return YES;	// makes the app set its AXFocusedWindow attribute correctly, which is what Moom uses to find the frontmost window (if your windows shouldn't be key windows, you'll have to make the app's accessibility element return a suitable focused window manually via a NSApplication subclass)
	}

	- (void)dealloc {
		[_zoomButtonElement release];
		[super dealloc];
	}

@end
