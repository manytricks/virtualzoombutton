#import "VZBWindow.h"


// VZBAccessibilityElement fakes a zoom button in terms of accessibility. It's not an actual button, and it's not on screen.

@interface VZBAccessibilityElement: NSAccessibilityElement <NSAccessibilityButton>

	@property (nonatomic, assign) NSWindow *window;

@end

@implementation VZBAccessibilityElement

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
		return NSMakeRect(frame.origin.x + frame.size.width - zoomButtonSize, frame.origin.y + frame.size.height - zoomButtonSize, zoomButtonSize, zoomButtonSize);	// arbitrary zoom button frame in global coordinates (in this case, the top right corner, which of course is a nod to Windows, but if the accessibility element were to actually match an emulated Windows system's zoom button, it would probably have to take themes into account)
	}

	- (BOOL)isAccessibilityEnabled {
		return YES;	// simulate a real button's enabled state (zoom buttons can exist, but be disabled for non-resizable windows, which is why Moom checks this)
	}

	- (BOOL)accessibilityPerformPress {
		[self.window zoom: self];
		return YES;
	}

@end


// VZBWindow manages a VZBAccessibilityElement as a private implementation detail and overrides some of a borderless window's default behavior. Also logs accessibility frame changes, unless you define DO_NOT_MONITOR_ACCESSIBILITY_FRAME.

@interface VZBWindow ()

	@property (nonatomic, retain) VZBAccessibilityElement *zoomButtonElement;

	#ifndef DO_NOT_MONITOR_ACCESSIBILITY_FRAME

		@property (nonatomic, assign) NSRect mostRecentAccessibilityFrame;

	#endif

@end

@implementation VZBWindow

	- (VZBAccessibilityElement *)zoomButtonElement {
		if (!_zoomButtonElement) {
			_zoomButtonElement = [[VZBAccessibilityElement alloc] init];
			_zoomButtonElement.window = self;
		}
		return _zoomButtonElement;
	}

	- (NSArray *)accessibilityChildren {
		NSArray *children = [super accessibilityChildren];
		return ((children) ? [children arrayByAddingObject: self.zoomButtonElement] : [NSArray arrayWithObject: self.zoomButtonElement]);
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

	#ifndef DO_NOT_MONITOR_ACCESSIBILITY_FRAME

		- (void)setAccessibilityFrame: (NSRect)frame {
			self.mostRecentAccessibilityFrame = frame;
			SEL logSelector = @selector(logAccessibilityFrame);
			[NSObject cancelPreviousPerformRequestsWithTarget: self selector: logSelector object: nil];
			[self performSelector: logSelector withObject: nil afterDelay: 0.1];	// -setAccessibilityFrame: is often sent several times when Moom repositions and/or resizes a window (because Moom can only set position xor size at a given time via accessibility, and because it has to correct for interfering macOS automatisms), so we filter out some of the noise by only logging the new accessibility frame after a delay
			[super setAccessibilityFrame: frame];
		}

		- (void)logAccessibilityFrame {
			NSRect frame = self.mostRecentAccessibilityFrame;
			NSLog(@"new accessibility frame: {{x: %ld, y: %ld}, {w: %ld, h: %ld}}", (long)frame.origin.x, (long)frame.origin.y, (long)frame.size.width, (long)frame.size.height);	// the frame's origin coordinates will sometimes be -0 even after rounding, so instead of using NSStringFromRect(), we convert to long to get prettier log messages
		}

	#endif

	- (BOOL)canBecomeKeyWindow {
		return YES;	// makes the app set its AXFocusedWindow attribute correctly, which is what Moom uses to find the frontmost window (if your windows shouldn't be key windows, you'll have to set your NSApplication's accessibilityFocusedWindow property manually)
	}

	#if !__has_feature(objc_arc)

		- (void)dealloc {
			[_zoomButtonElement release];
			[super dealloc];
		}

	#endif

@end
