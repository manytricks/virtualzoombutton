#import "VZBWindow.h"


@interface VZBTemporarilyNonResizableContentWindow: VZBWindow

	- (void)setFrame: (NSRect)frame display: (BOOL)display makeContentNonResizableTemporarily: (BOOL)makeContentNonResizableTemporarily;

@end
