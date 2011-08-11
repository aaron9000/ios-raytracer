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

#import "Texture2D.h"
#import "TouchController.h"
#import "Camera.h"
#import "Timer.h"
#import "mat4.h"


@interface iRayTraceViewController : UIViewController {
    //gl stuff
    EAGLContext *context;
    
    //Additional view for hud
    UIView* hudView;
    UILabel* controlsLabel;
    UILabel* emailLabel;
    
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
    
    //scene
    V3 lightDir;
    
    //buffers
    GLuint halfFrameBuffer;
    
    //display link
    BOOL animating;
    NSInteger animationFrameInterval;
    CADisplayLink *displayLink;
    
    //timing
    int ticks;
    Timer* perfTimer;
    
    //touch and input
    UIAccelerometer *accelerometer;
    TouchController *touchController;
    
    //camera
    Camera cam;

}

//step method
- (void) update;

//helpers
- (float)getScreenDistance;

//timing
- (BOOL) setupTiming;
- (BOOL) tearDownTiming;
- (void) updateTiming;

//hud
@property (retain, nonatomic) UIView* hudView;
@property (retain, nonatomic) UILabel* controlsLabel;
@property (retain, nonatomic) UILabel* emailLabel;
- (BOOL) setupHud;
- (BOOL) tearDownHud;

//gl
@property (retain, nonatomic) EAGLContext *context;
- (BOOL)setupGL;
- (BOOL)tearDownGL;
- (void)drawFrame;

//textures
- (BOOL)loadTextures;
- (BOOL)unloadTextures;

//buffers
- (BOOL)setupBuffers;
- (BOOL)tearDownBuffers;

//scene
- (BOOL) setupScene;
- (BOOL) tearDownScene;

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
- (void) updateInput;

//camera
- (void) updateCamera;
- (BOOL) setupCamera;
- (BOOL) tearDownCamera;





@end
