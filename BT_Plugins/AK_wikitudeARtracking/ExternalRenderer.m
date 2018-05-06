#import "ExternalRenderer.h"
#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>


@interface ExternalRenderer ()

@property (nonatomic, strong) CADisplayLink *displayLink;
@property (nonatomic, strong) EAGLContext *eaglContext;

@property (nonatomic, assign) GLuint colorRenderbuffer;
@property (nonatomic, assign) GLuint depthRenderbuffer;
@property (nonatomic, assign) GLuint framebuffer;
@property (nonatomic, assign) GLint framebufferWidht;
@property (nonatomic, assign) GLint framebufferHeight;

@property (nonatomic, copy) ExternalRenderBlock externalRenderBlock;

@end

@implementation ExternalRenderer

#pragma mark - Public Methods

- (void)setupRenderingWithLayer:(CAEAGLLayer *)eaglLayer
{
    if ( !_eaglContext )
    {
        self.eaglContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
        if ( _eaglContext )
        {
            [self assureCurrentContext];

            WT_GL_ASSERT( glGenFramebuffers(1, &_framebuffer) );
            WT_GL_ASSERT( glBindFramebuffer(GL_FRAMEBUFFER, _framebuffer) );

            WT_GL_ASSERT( glGenRenderbuffers(1, &_colorRenderbuffer) );
            WT_GL_ASSERT( glBindRenderbuffer(GL_RENDERBUFFER, _colorRenderbuffer) );

            BOOL renderbufferStorageSet = [self.eaglContext renderbufferStorage:GL_RENDERBUFFER fromDrawable:eaglLayer];
            if (!renderbufferStorageSet)
            {
                NSLog(@"unable to set renderbuffer storage from drawable");
                [self teardownRendering];
                return;
            }else
            {
                WT_GL_ASSERT( glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, _colorRenderbuffer) );

                WT_GL_ASSERT( glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &_framebufferWidht) );
                WT_GL_ASSERT( glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &_framebufferHeight) );

                WT_GL_ASSERT( glGenRenderbuffers(1, &_depthRenderbuffer) );
                WT_GL_ASSERT( glBindRenderbuffer(GL_RENDERBUFFER, _depthRenderbuffer) );
                WT_GL_ASSERT( glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT16, _framebufferWidht, _framebufferHeight) );
                WT_GL_ASSERT( glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, _depthRenderbuffer) );

                GLenum status = glCheckFramebufferStatus(GL_FRAMEBUFFER);
                if ( status != GL_FRAMEBUFFER_COMPLETE )
                {
                    NSLog(@"Incomple framebuffer after creation and setup: %x", status);
                    [self teardownRendering];
                    return;
                }

                WT_GL_ASSERT( glViewport(0, 0, _framebufferWidht, _framebufferHeight) );
            }
        }
    }
}

- (void)startRenderLoopWithRenderBlock:(ExternalRenderBlock)renderBlock
{
    NSParameterAssert(renderBlock);
    self.externalRenderBlock = renderBlock;

    self.displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(render:)];
	[self.displayLink setFrameInterval:2];
    [self.displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
}

- (void)render:(CADisplayLink *)displayLink
{
    WT_GL_ASSERT( glClearColor(0.0f, 0.0f, 0.0f, 1.0f) );
    WT_GL_ASSERT( glClear(GL_COLOR_BUFFER_BIT) );


    [EAGLContext setCurrentContext:self.eaglContext];

    self.externalRenderBlock(displayLink);

    WT_GL_ASSERT( glEnable(GL_DEPTH_TEST) );
    [self.eaglContext presentRenderbuffer:_colorRenderbuffer];
    [EAGLContext setCurrentContext:nil];
}

- (void)bindBuffer
{
    [EAGLContext setCurrentContext:self.eaglContext];
    
    WT_GL_ASSERT( glDisable(GL_DEPTH_TEST) );
    WT_GL_ASSERT( glBindFramebuffer(GL_FRAMEBUFFER, _framebuffer) );
    WT_GL_ASSERT( glBindRenderbuffer(GL_RENDERBUFFER, _colorRenderbuffer) );
}

- (void)stopRenderLoop
{
    [[self displayLink] invalidate];
    self.displayLink = nil;
}

- (void)teardownRendering
{
    self.externalRenderBlock = nil;

    if (_colorRenderbuffer)
    {
        WT_GL_ASSERT( glDeleteRenderbuffers(1, &_colorRenderbuffer) );
    }

    if (_framebuffer)
    {
        WT_GL_ASSERT( glDeleteFramebuffers(1, &_framebuffer) );
    }

    if (_eaglContext)
    {
        self.eaglContext = nil;
    }
}

- (EAGLContext *)internalContext
{
    return _eaglContext;
}

#pragma mark - Private Methods
- (void)assureCurrentContext
{
    if ( self.eaglContext != [EAGLContext currentContext] )
    {
        BOOL appliedCurrentContext = [EAGLContext setCurrentContext:self.eaglContext];
        if (!appliedCurrentContext)
        {
            NSLog(@"unable to set current context");
        }
    }
}

@end
