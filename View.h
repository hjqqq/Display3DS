#import <Cocoa/Cocoa.h>
#import <OpenGL/OpenGL.h>
#import <OpenGL/gl.h>
#import <OpenGL/glu.h>
#import <Mesh3DS/Mesh3DS.h>
#import <glm/glm.hpp>
#import <glm/gtc/matrix_transform.hpp>
#import <glm/gtc/type_ptr.hpp>

#define	MAX_FLYBY_DEPTH		500

#define COSINE_THRESHOLD	0.0			// Threshold angle at which vertices shared by surfaces are split. E.g. cosine(99¡) = 0.0

@interface View : NSOpenGLView
	{
	NSRect		sceneBounds;

	GLboolean	arcballEnabled;
		
	CGFloat		lastMouseX, lastMouseY, currentMouseX, currentMouseY;
}

- (id)		initWithFrame	:(NSRect)frame;
- (id)		loadMeshFromBundle;

- (BOOL)	initGL;

- (void)	reshape;
- (void)	drawRect		:(NSRect)rect;

glm::vec3	arcball_vector (float screenWidth, float screenHeight, float x, float y);

@property (assign)	Mesh3DS		*mesh;
@property (assign)	GLuint		flyBy_Index;
@property (assign)	BOOL		flyBy_Enabled;
@property (assign)	glm::mat4	modelViewMatrix;

@end
