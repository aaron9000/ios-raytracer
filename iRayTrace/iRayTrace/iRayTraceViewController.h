//
//  iPhotonViewController.h
//  iPhoton
//
//  Created by Aaron on 6/8/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES1/gl.h>
#import <OpenGLES/ES1/glext.h>
#import <OpenGLES/ES2/gl.h>
#import <OpenGLES/ES2/glext.h>

#include <mach/mach_time.h>

#import "Texture2D.h"
#import "TouchController.h"
#import "Camera.h"
#import "mat4.h"


@interface iRayTraceViewController : UIViewController {
    //gl stuff
    EAGLContext *context;
    
    
    //shaders
    GLuint renderShader;
    NSMutableDictionary* renderUniformDict;
    NSMutableDictionary* renderAttributeDict;
    
    GLuint textureShader;
    NSMutableDictionary* textureUniformDict;
    NSMutableDictionary* textureAttributeDict;
    
    //textures
    Texture2D* internalTexture;
    Texture2D* testTexture;
    
    //buffers
    GLuint halfFrameBuffer;
    //GLuint halfRenderBuffer;
    
    //display link
    BOOL animating;
    NSInteger animationFrameInterval;
    CADisplayLink *displayLink;
    
    
    //timing stuff
    int ticks;
    uint64_t oldTime;
    double timingFactor;
    
    //touch and input
    UIAccelerometer *accelerometer;
    TouchController *touchController;
    
    //camera
    Camera cam;
    /*
    Mat4 cameraMat;
    float cameraLatitude;
    float cameraLongitude;
     */
}


//step method
- (void) update;

//timing
- (void)startTiming;
- (void)endTiming:(NSString*) message;
- (void)setupTiming;

//helpers
- (float)getScreenDistance;

//gl
@property (retain, nonatomic) EAGLContext *context;
- (BOOL)setupGL;
- (BOOL)tearDownGL;
- (void) drawFrame;
//textures
- (BOOL)loadTextures;
- (BOOL)unloadTextures;

//buffers
- (BOOL)setupBuffers;
- (BOOL)tearDownBuffers;


//shaders
@property (retain, nonatomic) NSMutableDictionary* renderUniformDict;
@property (retain, nonatomic) NSMutableDictionary* renderAttributeDict;
@property (retain, nonatomic) NSMutableDictionary* textureUniformDict;
@property (retain, nonatomic) NSMutableDictionary* textureAttributeDict;
- (BOOL)loadShaders;
- (BOOL)unloadShaders;
- (BOOL)compileShader:(GLuint *)shader type:(GLenum)type file:(NSString *)file;
- (BOOL)linkProgram:(GLuint)prog;
- (BOOL)validateProgram:(GLuint)prog;
- (BOOL)loadShaderWithName:(NSString*) shaderName shaderId:(GLuint*) shader uniformDict:(NSMutableDictionary*) uDict attributeDict:(NSMutableDictionary*) aDict;

//display link
@property (readonly, nonatomic, getter=isAnimating) BOOL animating;
@property (nonatomic) NSInteger animationFrameInterval;
- (BOOL)setupDisplayLink;
- (void)startAnimation;
- (void)stopAnimation;

//event handlers
- (BOOL)setupNotifications;
- (BOOL)tearDownNotifications;
- (void)applicationWillResignActive:(NSNotification *)notification;
- (void)applicationDidBecomeActive:(NSNotification *)notification;
- (void)applicationWillTerminate:(NSNotification *)notification;

//touch and input
@property (readonly, nonatomic) UIAccelerometer* accelerometer;
- (void) linkTouchController:(TouchController*) controller;
- (BOOL)setupInput;
- (BOOL)tearDownInput;

//camera
- (void) updateCamera;
- (BOOL) setupCamera;
- (BOOL) tearDownCamera;





@end
