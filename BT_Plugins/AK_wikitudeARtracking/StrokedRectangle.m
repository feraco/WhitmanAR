#import "StrokedRectangle.h"
#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>

#import "ExternalRenderer.h"


@interface StrokedRectangle ()

@property (nonatomic, assign) GLuint augmentationProgram;
@property (nonatomic, assign) GLuint positionSlot;
@property (nonatomic, assign) GLuint projectionUniform;
@property (nonatomic, assign) GLuint modelViewUniform;

@property (nonatomic, assign) GLKMatrix4 projection;
@property (nonatomic, assign) GLKMatrix4 modelView;

@end

@implementation StrokedRectangle

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        _scale = 1;
        _projection = GLKMatrix4Identity;
        _modelView = GLKMatrix4Identity;
    }

    return self;
}

#pragma mark - Public Methods

- (void)setProjectionMatrix:(const float *)projectionMatrix
{
    memcpy(_projection.m, projectionMatrix, 16*sizeof(float));
}

- (void)setModelViewMatrix:(const float *)modelViewMatrix
{
    memcpy(_modelView.m, modelViewMatrix, 16*sizeof(float));
}

- (void)releaseProgram
{
    if (_augmentationProgram)
    {
        glDeleteProgram(_augmentationProgram);
        _augmentationProgram = 0;
    }
}

- (void)drawInContext:(EAGLContext *)context
{
    [EAGLContext setCurrentContext:context];
    if ( !_augmentationProgram )
    {
        
        WT_GL_ASSERT_AND_RETURN( _positionSlot, glGetAttribLocation(_augmentationProgram, "v_position") );
        
        WT_GL_ASSERT_AND_RETURN( _projectionUniform, glGetUniformLocation(_augmentationProgram, "Projection"));
        WT_GL_ASSERT_AND_RETURN( _modelViewUniform, glGetUniformLocation(_augmentationProgram, "Modelview") );
        
        WT_GL_ASSERT( glDisable(GL_DEPTH_TEST) );
    }

    WT_GL_ASSERT( glDisable(GL_DEPTH_TEST) );
    WT_GL_ASSERT( glUseProgram(_augmentationProgram) );
    
    /* reset any previously bound buffer */
    glBindBuffer(GL_ARRAY_BUFFER, 0);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, 0);

    static GLfloat rectVerts[] = {  -0.5f,  -0.5f, 0.0f,
        -0.5f,  0.5f, 0.0f,
        0.5f, 0.5f, 0.0f,
        0.5f, -0.5f, 0.0f };
    
    
    // Load the vertex position
    WT_GL_ASSERT( glVertexAttribPointer(_positionSlot, 3, GL_FLOAT, GL_FALSE, 0, rectVerts) );
    WT_GL_ASSERT( glEnableVertexAttribArray(_positionSlot) );
    
    WT_GL_ASSERT( glUniformMatrix4fv(_projectionUniform, 1, 0, _projection.m) );
    
    GLKMatrix4 scaleMatrix = GLKMatrix4MakeScale(self.scale, self.scale, 1.0f);
    GLKMatrix4 finalModelViewMatrix = GLKMatrix4Multiply(_modelView, scaleMatrix);
    WT_GL_ASSERT( glUniformMatrix4fv(_modelViewUniform, 1, 0, finalModelViewMatrix.m) );

    static GLushort lindices[4] = {0,1,2,3};
    GLsizei numberOfIndices = sizeof(lindices)/sizeof(lindices[0]);
    WT_GL_ASSERT( glDrawElements(GL_LINE_LOOP, numberOfIndices, GL_UNSIGNED_SHORT, lindices) );
}


@end
