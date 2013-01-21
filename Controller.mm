#import "Controller.h"

@interface Controller (InternalMethods)

- (void) setupRenderTimer;
- (void) updateGLView		:(NSTimer *)timer;
- (void) createFailed;

@end

@implementation Controller

@synthesize glWindow;
@synthesize glView;
@synthesize renderTimer;

- (void) awakeFromNib {
	
	[NSApp setDelegate:self];
	
	renderTimer = nil;
	
	[glWindow makeFirstResponder:self];
	
	glView = [[View alloc] initWithFrame:[glWindow frame]];
	
	if	(glView != nil) {
		
		[glWindow setContentView:glView];
		[glWindow makeKeyAndOrderFront:self];
		[glWindow zoom:self];
		
		[self setupRenderTimer];
	}
	
	else [self createFailed];
}

- (void) setupRenderTimer {
	
	NSTimeInterval timeInterval = 0.025;
	
	renderTimer = [[NSTimer scheduledTimerWithTimeInterval :timeInterval target:self selector:@selector(updateGLView:) userInfo:nil repeats:YES] retain];
	
	[[NSRunLoop currentRunLoop] addTimer:renderTimer forMode:NSEventTrackingRunLoopMode];
	[[NSRunLoop currentRunLoop] addTimer:renderTimer forMode:NSModalPanelRunLoopMode];
}

- (IBAction)openFile:(id)sender {

	NSArray *fileTypes = [NSArray arrayWithObjects:@"3ds", @"3DS", @"3Ds", @"3dS", nil];
	
	NSOpenPanel *oPanel = [NSOpenPanel openPanel];							// Create the File Open Panel class.

	[oPanel setAlphaValue:0.95];											// Alpha value	
	[oPanel setCanChooseFiles:YES];											// Enable the selection of files in the dialog.
	[oPanel setCanChooseDirectories:NO];									// Disable the selection of directories in the dialog.
	[oPanel setCanCreateDirectories:NO];									// Enable the creation of directories in the dialog
	[oPanel setAllowsMultipleSelection:NO];									// Allow multiple files selection

	[oPanel setTitle:@"Select a .3ds mesh file"];

	if ( [oPanel runModalForDirectory:nil file:nil types:fileTypes] == NSOKButton )	{
		
		NSArray *files = [oPanel filenames];
		
		NSString *meshFileName = [files objectAtIndex:0];

		NSString *informativeText= [NSString stringWithFormat:@"Error opening 3DS mesh file: '%@'\n\nPlease try another file.", meshFileName];

		@try {

			[glView.mesh release];
			
			glView.mesh = [[Mesh3DS alloc] init:COSINE_THRESHOLD :false];	// Invoke the glView mesh object setter, replacing the old mesh with the new
			
			[glView.mesh Parse3DS:meshFileName];
		}
		
		@catch	(NSException *e) {
			
			NSAlert *alert = [[NSAlert alloc] init];
			
			[alert addButtonWithTitle:@"OK"];
			[alert setAlertStyle:NSWarningAlertStyle];
			[alert setInformativeText:informativeText];
			[alert setMessageText:@"3DS Mesh File Error"];
			
			if ([alert runModal] == NSAlertFirstButtonReturn) [alert release];
			
			NSArray *backtrace = [e callStackSymbols];
			
			NSLog (@"Exception raised in openFile e = %@.\n\n Backtrace:\n%@", e, backtrace);
		}
	}
}

- (void) updateGLView:(NSTimer*)timer {
	
	if (glView != nil) [glView drawRect:[glView frame]];
}  

- (void) keyDown:(NSEvent*)theEvent {
	
	unichar unicodeKey;
	
	unicodeKey = [[theEvent characters] characterAtIndex:0];
	
	switch (unicodeKey) {
			
		case 'd':
        case 'D':
			
			[glView.mesh Zoom:2.0];
			
			break;
			
		case 'f':
		case 'F':
			
			glView.flyBy_Enabled = !glView.flyBy_Enabled;
			
			break;
			
		case 'h':
        case 'H':
			
			[glView.mesh Zoom:0.5];
			
			break;
			
		case 'r':									// Reset to default viewpoint
		case 'R':
			
			glView.modelViewMatrix	= glm::lookAt (glm::vec3 (0.0,  0.0, 10.0),
												   glm::vec3 (0.0,  0.0, 0.0),
												   glm::vec3 (0.0,  1.0, 0.0));
			break;
            
        case 27:									// ESC key to exit at top of event loop
		case 'q':
		case 'Q':
		case 'x':
		case 'X':
            
            [NSApp performSelector:@selector(terminate:) withObject:nil afterDelay:0.0];
	}
}

- (void) createFailed {
	
	NSWindow	*infoWindow;
	
	infoWindow	= NSGetCriticalAlertPanel (@"Initialization failed", @"Failed to initialize OpenGL", @"OK", nil, nil);
	
	[NSApp runModalForWindow:infoWindow];
	
	[infoWindow close];
	
	[NSApp terminate:self];
}

- (void) dealloc {
	
	[glWindow release];
	[glView release];
	
	if (renderTimer != nil && [renderTimer isValid]) [renderTimer invalidate];
	
	[super dealloc];
}

@end
