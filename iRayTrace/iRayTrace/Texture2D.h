
#import <UIKit/UIKit.h>
#import <OpenGLES/ES1/gl.h>

//CONSTANTS:

typedef enum {
    kTexture2DPixelFormat_Automatic = 0,
    kTexture2DPixelFormat_RGBA8888,
    kTexture2DPixelFormat_RGB565,
    kTexture2DPixelFormat_A8,
} Texture2DPixelFormat;

//CLASS INTERFACES:

/*
 This class allows to easily create OpenGL 2D textures from images, text or raw data.
 The created Texture2D object will always have power-of-two dimensions.
 Depending on how you create the Texture2D object, the actual image area of the texture might be smaller than the texture dimensions i.e. "contentSize" != (pixelsWide, pixelsHigh) and (maxS, maxT) != (1.0, 1.0).
 Be aware that the content of the generated textures will be upside-down!
 */
@interface Texture2D : NSObject
{
@private
    GLuint                                          _name;
    CGSize                                          _size;
    NSUInteger                                      _width,
    _height;
    Texture2DPixelFormat            _format;
    GLfloat                                         _maxS,
    _maxT;
}
- (id) initWithData:(const void*)data pixelFormat:(Texture2DPixelFormat)pixelFormat pixelsWide:(NSUInteger)width pixelsHigh:(NSUInteger)height contentSize:(CGSize)size;

@property(readonly) Texture2DPixelFormat pixelFormat;
@property(readonly) NSUInteger pixelsWide;
@property(readonly) NSUInteger pixelsHigh;

@property(readonly) GLuint name;

@property(readonly, nonatomic) CGSize contentSize;
@property(readonly) GLfloat maxS;
@property(readonly) GLfloat maxT;
@end

/*
 Drawing extensions to make it easy to draw basic quads using a Texture2D object.
 These functions require GL_TEXTURE_2D and both GL_VERTEX_ARRAY and GL_TEXTURE_COORD_ARRAY client states to be enabled.
 */
@interface Texture2D (Drawing)
- (void) drawAtPoint:(CGPoint)point;
- (void) drawInRect:(CGRect)rect;
@end

/*
 Extensions to make it easy to create a Texture2D object from an image file.
 Note that RGBA type textures will have their alpha premultiplied - use the blending mode (GL_ONE, GL_ONE_MINUS_SRC_ALPHA).
 */
@interface Texture2D (Image)
- (id) initWithImage:(UIImage *)uiImage;
@end

/*
 Extensions to make it easy to create a Texture2D object from a string of text.
 Note that the generated textures are of type A8 - use the blending mode (GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA).
 */
@interface Texture2D (Text)
- (id) initWithString:(NSString*)string dimensions:(CGSize)dimensions alignment:(UITextAlignment)alignment fontName:(NSString*)name fontSize:(CGFloat)size;
@end