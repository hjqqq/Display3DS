#import <Cocoa/Cocoa.h>
#import "View.h"

@interface Controller : NSResponder	{
	
	IBOutlet NSWindow	*glWindow;
	NSTimer				*renderTimer;
	View				*glView;
}

- (IBAction)openFile	:(id)sender;

- (void) awakeFromNib;
- (void) keyDown		:(NSEvent*)theEvent;
- (void) dealloc;

@property (retain) NSWindow	*glWindow;
@property (retain) NSTimer	*renderTimer;
@property (retain) View		*glView;

@end
