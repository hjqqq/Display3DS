#import "View.h"

@implementation View

@synthesize mesh, flyBy_Index, flyBy_Enabled, modelViewMatrix;

- (id) initWithFrame :(NSRect)frame {
	
	mesh			= nil;

	arcballEnabled	= false;
	
	flyBy_Enabled	= false;
	flyBy_Index		= 0;

	lastMouseX		= lastMouseY = currentMouseX = currentMouseY = 0.0;
	
	modelViewMatrix	= glm::lookAt (glm::vec3 (0.0,  0.0, 10.0),
								   glm::vec3 (0.0,  0.0, 0.0),
								   glm::vec3 (0.0,  1.0, 0.0));
	
	NSOpenGLPixelFormatAttribute pixelAttribs[] = { NSOpenGLPFADoubleBuffer,
													NSOpenGLPFAAccelerated,
													NSOpenGLPFAColorSize, 16,
													NSOpenGLPFADepthSize, 24,
													NSOpenGLPFAMultisample,			// The remaining attributes are for texture multisampling (full screen anti-aliasing)
													NSOpenGLPFASampleBuffers, 1,
													NSOpenGLPFASamples, 4,
													NSOpenGLPFANoRecovery,
													0 };
	NSOpenGLPixelFormat	*pixelFormat;
	
	pixelFormat	= [[NSOpenGLPixelFormat alloc] initWithAttributes:pixelAttribs];
	
	if	(pixelFormat != nil) {
		
		self = [super initWithFrame:frame pixelFormat:pixelFormat];
		
		[pixelFormat release];
		
		if	(self) {
			
			[[self openGLContext] makeCurrentContext];
			
			[self reshape];
			
			if	(![self initGL]) {
				
				[self clearGLContext];
				self = nil;
			}
		}
	}
	else self = nil;
	
	return self;
}

- (BOOL) initGL {
    
	GLfloat ambientLight[]  = { 0.25f, 0.25f, 0.25f, 1.0f };
    GLfloat diffuseLight[]  = { 1.0f,  1.0f,  1.0f,  1.0f };
    GLfloat specularLight[] = { 1.0f,  1.0f,  1.0f,  1.0f }; 
    GLfloat positionLight[] = { 0.0f,  0.0f,  1.0f,  0.0f };						// W = 0.0 means Directional Light and (0,0,1) is where infinite, parallel light rays are cast from; i.e. towards -Z axis
	
    glMatrixMode	(GL_TEXTURE);
    glLoadIdentity	();
	
    glMatrixMode	(GL_PROJECTION );
    glLoadIdentity	();
	
    glMatrixMode	(GL_MODELVIEW);
    glLoadIdentity	();
    
    glLightfv       (GL_LIGHT0, GL_POSITION, positionLight);
	glLightfv       (GL_LIGHT0, GL_AMBIENT,  ambientLight);
    glLightfv       (GL_LIGHT0, GL_DIFFUSE,  diffuseLight);
    glLightfv       (GL_LIGHT0, GL_SPECULAR, specularLight);
    
	glEnable		(GL_MULTISAMPLE);
    glEnable		(GL_DEPTH_TEST);
	
	mesh = [self loadMeshFromBundle];
	
	return TRUE;
}

- (id) loadMeshFromBundle {
	
	@try {
		
		if (mesh) [mesh release];
		
		mesh = [[Mesh3DS alloc] init :COSINE_THRESHOLD :false];
		
        NSBundle *bundle    = [NSBundle bundleForClass:[self class]];
        
        NSString *filename  = [bundle pathForResource:@"UFO" ofType:@"3ds"];

		[mesh Parse3DS :filename];
	}
	
	@catch	(NSException *e) {

		NSAlert *alert = [[NSAlert alloc] init];

		[alert addButtonWithTitle:@"OK"];
		[alert setAlertStyle:NSWarningAlertStyle];
        [alert setMessageText:@"Display3DS Mesh Decode Error"];
		[alert setInformativeText:@"Parsing error decoding the built-in (i.e. bundled) 3DS mesh resource.\n\nTry opening another 3DS file."];
		
		if ([alert runModal] == NSAlertFirstButtonReturn) [alert release];
		
		NSArray *backtrace = [e callStackSymbols];
		
		NSLog (@"Exception raised in loadMeshBundle e = %@.\n\n Backtrace:\n%@", e, backtrace);
		
		return nil;
	}

	return	mesh;
}

- (void) reshape {
	
    [[self openGLContext] update];
	
    sceneBounds		= [self bounds];
    
    glMatrixMode	(GL_PROJECTION );
    glLoadIdentity	();
	
    glViewport		(0, 0,  sceneBounds.size.width,  sceneBounds.size.height);
    gluPerspective	(18.0f, sceneBounds.size.width / sceneBounds.size.height, 1.0f, 1000.0f);
    
    glMatrixMode	(GL_MODELVIEW);
    glLoadIdentity	();
    
    glClearColor    (0.5, 0.5, 0.5, 1.0);
}

-(void) otherMouseDown:(NSEvent *)pEvent {								// Use the 3rd mouse button for arcball movement, similar to Blender
	
	NSPoint pointInWindow		= [pEvent locationInWindow];
	NSPoint pointInView			= [self convertPoint:pointInWindow fromView:nil];
	
	lastMouseX = currentMouseX	= pointInView.x;
	lastMouseY = currentMouseY	= pointInView.y;
	
	arcballEnabled = true;
}

-(void) otherMouseDragged:(NSEvent*) pEvent {							// Derived from https://gitorious.org/wikibooks-opengl/modern-tutorials/blobs/master/obj-viewer/obj-viewer.cpp
	
	if (arcballEnabled) {
		
		NSPoint pointInWindow	= [pEvent locationInWindow];
		NSPoint pointInView		= [self convertPoint:pointInWindow fromView:nil];
		
		currentMouseX			= pointInView.x;
		currentMouseY			= pointInView.y;
		
		if	(currentMouseX != lastMouseX || currentMouseY != lastMouseY) {
			
			glm::vec3 va = arcball_vector (sceneBounds.size.width, sceneBounds.size.height, lastMouseX,		lastMouseY);		// |va| is from Origin to first ArcBall surface point
			glm::vec3 vb = arcball_vector (sceneBounds.size.width, sceneBounds.size.height, currentMouseX,	currentMouseY);		// |vb| is from Origin to current ArcBall surface point
			
			float angle = acos (glm::min (1.0f, glm::dot (va, vb)));															// Compute the rotation angle between those two vectors
			
			glm::vec3 axis_in_cameraSpace	= glm::cross (va, vb);																// Compute 3D rotation axis (unit perpendicular vector)
			
			glm::mat3 camera2modelSubMatrix	= glm::inverse (glm::mat3 (modelViewMatrix));										// Extract the camera-to-modelspace transform submatrix
			
			glm::vec3 axis_in_modelSpace	= camera2modelSubMatrix * axis_in_cameraSpace;										// Transform the axis vector from camera to modelspace

			modelViewMatrix					= glm::rotate (modelViewMatrix, glm::degrees (angle), axis_in_modelSpace);			// Rotate the ModelView matrix on the modelspace axis
																																// (using the modelspace axis gives a WYSIWYG feel)
			lastMouseX = currentMouseX;
			lastMouseY = currentMouseY;
		}

		[self setNeedsDisplay:YES]; 	
	}
}

-(void) otherMouseUp:(NSEvent*) pEvent {
	
	arcballEnabled = false;
	
	[self setNeedsDisplay:YES];
}

-(void) scrollWheel:(NSEvent*) pEvent {
	
	float scaleFactor = ([pEvent deltaY] > 0.0) ? 1.1 : 0.9;
	
	modelViewMatrix   = glm::scale (modelViewMatrix, glm::vec3 (scaleFactor));
	
	[self setNeedsDisplay:YES];
}

- (void) drawRect :(NSRect)rect {
	
    glClear (GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
	
	glPushMatrix ();

	if (flyBy_Enabled) {
		
		if (flyBy_Index == MAX_FLYBY_DEPTH) flyBy_Index = 0;
		
		else {
			
			GLfloat phi		= (GLfloat) (flyBy_Index * M_PI	  / MAX_FLYBY_DEPTH);	// Calculate Z-dimension (pole-to-pole)
			GLfloat theta	= (GLfloat) (flyBy_Index * M_PI*2 / MAX_FLYBY_DEPTH);	// Calculate X and Y position
			
			gluLookAt	((-200 * sin (phi)	* cos (theta)),
						 (-200 * sin (phi)	* sin (theta)),
						 (-MAX_FLYBY_DEPTH	* cos (phi)),
						 0,0,0,
						 0,1,0);
		}
		
		flyBy_Index++;
		
	} else glLoadMatrixf (glm::value_ptr (modelViewMatrix));

	if (mesh) [mesh Display];
	
	glPopMatrix ();
	
	[[self openGLContext] flushBuffer];
}

/*
 * Return a vector from the center of the virtual ball at origin O to point P on the virtual ball surface, such that P is mapped to the screen's (x, y) coordinates.
 *
 * If point P is too far away from the sphere (|OP| > 1), return the nearest point on the virtual ball surface.
 */

glm::vec3 arcball_vector (float screenWidth, float screenHeight, float x, float y) {
	
	glm::vec3 P = glm::vec3 (x/screenWidth  * 2 - 1.0,
							 y/screenHeight * 2 - 1.0,
							 0);
	P.y = -P.y;												// Flip Y-axis from screen orientation to cartesian
	
	float OP_squared = P.x * P.x + P.y * P.y;
	
	if	(OP_squared <= 1.0)	P.z = sqrt (1.0 - OP_squared);	// From Pythagoras
	else					P = glm::normalize (P);			// Nearest point on arcball surface
	
	return P;
}

@end
