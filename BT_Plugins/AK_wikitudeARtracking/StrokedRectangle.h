#import <Foundation/Foundation.h>
#import <GLKit/GLKit.h>

@interface StrokedRectangle : NSObject

@property (nonatomic, assign) CGFloat scale;

- (void)setProjectionMatrix:(const float *)projectionMatrix;
- (void)setModelViewMatrix:(const float *)modelViewMatrix;
- (void)releaseProgram;
- (void)drawInContext:(EAGLContext *)context;

@end
