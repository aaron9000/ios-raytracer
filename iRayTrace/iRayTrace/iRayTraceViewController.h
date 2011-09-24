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

@interface iRayTraceViewController : UIViewController<UIPopoverControllerDelegate>{
    //gl stuff
    EAGLContext *context;
    
    //for legacy device scaling
    int renderDivider;
    float displayScaling;
    
    //Additional view for hud
    UIView* hudView;
    //quality menu
    UIViewController* qualityController;
    UIButton* qualityButton;
    UILabel* qualityLabel;
    UISegmentedControl* qualityControl;
    //size menu
    UIViewController* sizeController;
    UIButton* sizeButton;
    UISlider* sizeSlider;
    UILabel* sizeLabel;
    //path menu
    UIViewController* pathController;
    UIButton* pathButton;
    UIButton* pathResetButton;
    UILabel* pathLabel;
    //info menu
    UIViewController* infoController;
    UIButton* infoButton;
    UILabel* descriptionLabel;
    
    //shaders
    GLuint renderShader;
    NSMutableDictionary* renderUniformDict;
    NSMutableDictionary* renderAttributeDict;
    
    GLuint textureShader;
    NSMutableDictionary* textureUniformDict;
    NSMutableDictionary* textureAttributeDict;
    
    //textures
    Texture2D* internalTextureQuarter;
    Texture2D* internalTextureHalf;
    Texture2D* internalTextureFull;
    //Texture2D* testTexture;
    
    //scene
    V3 lightDir;
    float angle;
    
    //buffers
    GLuint frameBufferQuarter;
    GLuint frameBufferHalf;
    GLuint frameBufferFull;
    
    //display link
    BOOL animating;
    NSInteger animationFrameInterval;
    CADisplayLink *displayLink;
    
    //timing
    Timer* perfTimer;
    
    //touch and input
    UIAccelerometer *accelerometer;
    TouchController *touchController;
    
    //camera
    Camera cam;
}

//step method
- (void) update;

//device meta
- (NSString*) getPlatform;
- (bool) checkDevice;

//timing
@property (retain, nonatomic) Timer* perfTimer;
- (BOOL) setupTiming;
- (BOOL) tearDownTiming;
- (void) updateTiming;

//hud
@property (retain, nonatomic) UIView* hudView;
//quality menu
@property (retain, nonatomic) UIViewController* qualityController;
@property (retain, nonatomic) UIButton* qualityButton;
@property (retain, nonatomic) UILabel* qualityLabel;
@property (retain, nonatomic) UISegmentedControl* qualityControl;
//size menu
@property (retain, nonatomic) UIViewController* sizeController;
@property (retain, nonatomic) UIButton* sizeButton;
@property (retain, nonatomic) UILabel* sizeLabel;
@property (retain, nonatomic) UISlider* sizeSlider;
//path menu
@property (retain, nonatomic) UIViewController* pathController;
@property (retain, nonatomic) UIButton* pathButton;
@property (retain, nonatomic) UILabel* pathLabel;
@property (retain, nonatomic) UIButton* pathResetButton;
//info menu
@property (retain, nonatomic) UIViewController* infoController;
@property (retain, nonatomic) UIButton* infoButton;
@property (retain, nonatomic) UILabel* descriptionLabel;
- (void) syncInterfaceWithSettings;
- (BOOL) setupHud;
- (BOOL) tearDownHud;

//gl
@property (retain, nonatomic) EAGLContext *context;
- (BOOL)setupGL;
- (BOOL)tearDownGL;
- (void)drawFrame;

//textures
- (Texture2D*) internalTextureWithDivider:(int) divider andBuffer:(GLuint) buffer;
- (BOOL)loadTextures;
- (BOOL)unloadTextures;

//buffers
- (BOOL)setupBuffers;
- (BOOL)tearDownBuffers;

//scene
- (BOOL) setupScene;
- (BOOL) tearDownScene;
- (void) updateScene;

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

//touch and input
@property (readonly, nonatomic) UIAccelerometer* accelerometer;
- (void) linkTouchController:(TouchController*) controller;

//camera
- (void) updateCamera;
- (BOOL) setupCamera;
- (BOOL) tearDownCamera;

@end
