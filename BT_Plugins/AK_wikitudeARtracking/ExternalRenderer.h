#import <Foundation/Foundation.h>
#import <QuartzCore/QuartzCore.h>

#ifdef ASSERT_OPENGL
    #define WT_GL_ASSERT( __gl_code__ ) { \
        __gl_code__; \
        GLenum __wt_gl_error_code__ = glGetError(); \
        if ( __wt_gl_error_code__ != GL_NO_ERROR ) { \
            printf("OpenGL error '%x' occured at line %d inside function %s\n", __wt_gl_error_code__, __LINE__, __PRETTY_FUNCTION__); \
        } \
    }
    #define WT_GL_ASSERT_AND_RETURN( __assign_to__, __gl_code__ ) { \
        __assign_to__ = __gl_code__; \
        GLenum __wt_gl_error_code__ = glGetError(); \
        if ( __wt_gl_error_code__ != GL_NO_ERROR ) { \
            printf("OpenGL error '%x' occured at line %d inside function %s\n", __wt_gl_error_code__, __LINE__, __PRETTY_FUNCTION__); \
        } \
    }
#else
    #define WT_GL_ASSERT( __gl_code__ ) __gl_code__
    #define WT_GL_ASSERT_AND_RETURN( __assign_to__, __gl_code__ ) __assign_to__ = __gl_code__
#endif


@class StrokedRectangle;

typedef void(^ExternalRenderBlock)(CADisplayLink *displayLink);

@interface ExternalRenderer : NSObject

- (void)setupRenderingWithLayer:(CAEAGLLayer *)eaglLayer;

- (void)startRenderLoopWithRenderBlock:(ExternalRenderBlock)renderBlock;
- (void)stopRenderLoop;

- (void)bindBuffer;

- (void)teardownRendering;

- (EAGLContext *)internalContext;

@end
