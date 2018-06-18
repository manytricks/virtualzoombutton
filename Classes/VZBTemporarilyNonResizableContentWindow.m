#import "VZBTemporarilyNonResizableContentWindow.h"


typedef NS_ENUM(NSUInteger, VZBWindowContentResizePolicy) {
	VZBWindowContentResizePolicyNoDelay = 0,
	VZBWindowContentResizePolicyAlwaysDelayByDefault,
	VZBWindowContentResizePolicyDelayDuringAccessibilitySizeChange_Undocumented
};

static const VZBWindowContentResizePolicy VZBWindowContentResizeDefaultPolicy = VZBWindowContentResizePolicyDelayDuringAccessibilitySizeChange_Undocumented;

static const NSTimeInterval VZBWindowFrameChangeResponseDelay = 1.0;	// in production, a value along the lines of 0.1 will probably make more sense


@interface NSWindow (VZBTemporarilyNonResizableContentWindowAccessibility_Undocumented)

	- (void)accessibilitySetSizeAttribute: (id)attribute;

@end


// VZBTemporarilyNonResizableContentWindow makes its content non-resizable temporarily as it changes its frame, depending on which values you choose for VZBWindowFrameChangeResponseDelay and VZBWindowContentResizeDefaultPolicy above.

@interface VZBTemporarilyNonResizableContentWindow ()

	@property (nonatomic, retain) NSView *originalContentView;
	@property (nonatomic, assign) BOOL accessibilitySizeIsChanging;

@end

@implementation VZBTemporarilyNonResizableContentWindow

	- (void)setFrame: (NSRect)frame display: (BOOL)display makeContentNonResizableTemporarily: (BOOL)makeContentNonResizableTemporarily {
		SEL restoreOriginalContentViewSelector = @selector(restoreOriginalContentView);
		[NSObject cancelPreviousPerformRequestsWithTarget: self selector: restoreOriginalContentViewSelector object: nil];
		if (makeContentNonResizableTemporarily && (VZBWindowFrameChangeResponseDelay>0)) {
			if (!self.originalContentView) {
				NSView *originalContentView = self.contentView;
				self.originalContentView = originalContentView;
				NSView *containerView = [[NSView alloc] initWithFrame: originalContentView.frame];
				containerView.autoresizesSubviews = NO;
				self.contentView = containerView;
				[containerView addSubview: originalContentView];
				#if !__has_feature(objc_arc)
					[containerView release];
				#endif
			}
			[self performSelector: restoreOriginalContentViewSelector withObject: nil afterDelay: VZBWindowFrameChangeResponseDelay];	// -setFrame:display: is often sent several times when Moom repositions and/or resizes a window (because Moom can only set position xor size at a given time via accessibility, and because it has to correct for interfering macOS automatisms), so we filter out some of the noise by keeping the window's contents from resizing temporarily
			[super setFrame: frame display: display];
		} else {
			[super setFrame: frame display: display];
			[self restoreOriginalContentView];
		}
	}

	- (void)setFrame: (NSRect)frame display: (BOOL)display {
		BOOL makeContentNonResizableTemporarily = NO;
		switch (VZBWindowContentResizeDefaultPolicy) {
			case VZBWindowContentResizePolicyAlwaysDelayByDefault:
				makeContentNonResizableTemporarily = YES;
				break;
			case VZBWindowContentResizePolicyDelayDuringAccessibilitySizeChange_Undocumented:
				makeContentNonResizableTemporarily = (self.accessibilitySizeIsChanging || (self.originalContentView));
				break;
			default:
				break;
		}
		[self setFrame: frame display: display makeContentNonResizableTemporarily: makeContentNonResizableTemporarily];
	}

	- (void)accessibilitySetSizeAttribute: (id)attribute {
		if ([self.superclass instancesRespondToSelector: _cmd]) {
			self.accessibilitySizeIsChanging = YES;
			[super accessibilitySetSizeAttribute: attribute];
			self.accessibilitySizeIsChanging = NO;
		}
	}

	- (void)restoreOriginalContentView {
		NSView *originalContentView = self.originalContentView;
		if (originalContentView) {
			NSView *contentView = self.contentView;
			if (originalContentView!=contentView) {
				[originalContentView removeFromSuperview];
				originalContentView.frame = contentView.frame;
				self.contentView = originalContentView;
			}
			self.originalContentView = nil;
		}
	}

	#if !__has_feature(objc_arc)

		- (void)dealloc {
			[_originalContentView release];
			[super dealloc];
		}

	#endif

@end
