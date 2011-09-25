//
//  iPhotonViewController.m
//  iPhoton
//
//  Created by Aaron on 6/8/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#include <sys/types.h>
#include <sys/sysctl.h>

#import <QuartzCore/QuartzCore.h>
#import "iRayTraceViewController.h"
#import "EAGLView.h"
#import "TouchController.h"
#import "Texture2D.h"
#import "TouchObj.h"
#import "V3.h"

#define TextureSize  1024
#define InternalWidth 768
#define InternalHeight 1024
#define FramerateDivider 3
#define LightRotateSpeed 0.015f
#define PopUpWidth 260.0f
#define PopUpHeight 100.0f
#define MinScale 0.25f
#define MaxScale 1.0f

@implementation iRayTraceViewController

//display link
@synthesize animating;

//gl
@synthesize context;

//shaders
@synthesize renderUniformDict;
@synthesize renderAttributeDict;
@synthesize textureAttributeDict;
@synthesize textureUniformDict;

////////
//MAIN//
////////
- (void) lowQuality{
    renderDivider = 4;
    displayScaling = MaxScale;
}
- (void) highQuality{
    renderDivider = 2;
    displayScaling = MaxScale;
}
- (void)viewDidLoad
{
    //check what device the user has
    [self highQuality];
    if (![self checkDevice]){
        NSString* title = @"Unsupported Device";
        NSString* message = @"You need an iPad with iOS 4.0+ to run this app. Press home to exit the application.";
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title message:message delegate:self cancelButtonTitle:nil otherButtonTitles:nil, nil];
        [alert show];
        return;
        
    }
    
    if (!touchController){
        NSLog(@"touchController not linked");
        return;   
    }
    
    [self setupTiming];
    [self setupHud];
    [self setupScene];
    [self setupGL];
    [self setupCamera];
    [self setupDisplayLink];
    [self setupBuffers];
    [self loadShaders];
    [self loadTextures];
    
}

- (void)dealloc
{
    
    [self unloadTextures];
    [self unloadShaders];
    [self tearDownBuffers];
    [self tearDownCamera];
    [self tearDownGL];
    [self tearDownScene];
    [self tearDownHud];
    [self tearDownTiming];
    
    [super dealloc];
}

- (void) update{
    
    //input
    [self updateCamera];
    [self updateTiming];
    [self updateScene];
    [self drawFrame];
    
}
/////////////////
/* DEVICE META */
/////////////////

- (NSString *) getPlatform{
    size_t size;
    sysctlbyname("hw.machine", NULL, &size, NULL, 0);
    char* machine = (char*)malloc(size);
    sysctlbyname("hw.machine", machine, &size, NULL, 0);
    NSString *platform = [NSString stringWithUTF8String:machine];
    free(machine);
    return platform;
}
- (bool) checkDevice{

	//OS version
	NSString *currSysVer = [[UIDevice currentDevice] systemVersion];
	float osVersion = [currSysVer floatValue];
    
	//what kind of device
	NSString* model = [UIDevice currentDevice].model;
	NSString* deviceType = @"Uknown";
	if ([model rangeOfString:@"iPad"].location != NSNotFound)
        deviceType=@"iPad";
    
    //scale internal renderign for old ipads
    NSString *platform = [self getPlatform];
    if ([platform rangeOfString:@"1,"].location != NSNotFound)
        [self lowQuality];
    
    //old version of iOS
    if (osVersion < 4.0f)
        return false;
    
    //not an iPad2
    if (![deviceType isEqualToString:@"iPad"])
        return false;
    
    //default 
    return true;
}

////////////
/* TIMING */
////////////
@synthesize perfTimer;
- (BOOL) setupTiming {
    
    self.perfTimer = [[Timer alloc] init];
    srand((uint)[perfTimer getTime]);
    
    return true;
}
- (BOOL) tearDownTiming {
    
    [perfTimer release];
    return true;
}
- (void) updateTiming{
    
    [perfTimer endTiming:nil];
    [perfTimer startTiming];
    [perfTimer tick];
}

/////////////
//HUD STUFF//
/////////////
@synthesize hudView;
@synthesize qualityController;
@synthesize qualityButton;
@synthesize qualityLabel;
@synthesize qualityControl;
@synthesize sizeController;
@synthesize sizeButton;
@synthesize sizeSlider;
@synthesize sizeLabel;
@synthesize pathController;
@synthesize pathResetButton;
@synthesize pathLabel;
@synthesize pathButton;
@synthesize infoController;
@synthesize infoButton;
@synthesize descriptionLabel;
- (void) syncInterfaceWithSettings{
    int index = 0; 
    switch (renderDivider){
        case 1:
            index = 2;
            break;
        case 2:
            index = 1;
            break;
        case 4:
            index = 0;
            break;
    }
    [qualityControl setSelectedSegmentIndex:index];
    [sizeSlider setValue:displayScaling];
}
- (void) sliderChange:(id) sender{
    displayScaling = [sizeSlider value];
}
- (void) qualityControlClick:(id) sender{
    switch ([qualityControl selectedSegmentIndex]) {
        case 0:
            renderDivider = 4;
            break;
        case 1:
            renderDivider = 2;
            break;            
        case 2:
            renderDivider = 1;
            break;
        default:
            break;
    }
}
- (void) pathResetClick:(id) sender {
    //new random camera path
    [self setupCamera];

}
- (BOOL) popoverControllerShouldDismissPopover:(UIPopoverController *) popoverController{
    [popoverController dismissPopoverAnimated:false];
    return false;   
}
- (void) qualityClick:(id) sender{
    UIPopoverController* controller = [[UIPopoverController alloc] initWithContentViewController:qualityController];
    [controller setPopoverContentSize:CGSizeMake(PopUpWidth, PopUpHeight) animated:false];
    [controller setDelegate:self];
    [controller presentPopoverFromRect:qualityButton.frame inView:hudView permittedArrowDirections:UIPopoverArrowDirectionAny animated:false];
}
- (void) sizeClick:(id) sender{
    UIPopoverController* controller = [[UIPopoverController alloc] initWithContentViewController:sizeController];
    [controller setPopoverContentSize:CGSizeMake(PopUpWidth, PopUpHeight) animated:false];
    [controller setDelegate:self];
    [controller presentPopoverFromRect:sizeButton.frame inView:hudView permittedArrowDirections:UIPopoverArrowDirectionAny animated:false];
}
- (void) pathClick:(id) sender{
    UIPopoverController* controller = [[UIPopoverController alloc] initWithContentViewController:pathController];
    [controller setPopoverContentSize:CGSizeMake(PopUpWidth, PopUpHeight) animated:false];
    [controller setDelegate:self];
    [controller presentPopoverFromRect:pathButton.frame inView:hudView permittedArrowDirections:UIPopoverArrowDirectionAny animated:false];
}

- (void) infoClick:(id) sender{
    UIPopoverController* controller = [[UIPopoverController alloc] initWithContentViewController:infoController];
    [controller setPopoverContentSize:CGSizeMake(PopUpWidth, PopUpHeight) animated:false];
    [controller setDelegate:self];
    [controller presentPopoverFromRect:infoButton.frame inView:hudView permittedArrowDirections:UIPopoverArrowDirectionAny animated:false];
}
- (BOOL) setupHud{

    //hud consts
    float buttonWidth = 64.0f;
    float buttonHeight = 36.0f;
    float buttonAlpha = 0.5f;
    float padding = 8.0f;
    float adjustedWidth = PopUpWidth - (2 * padding);
    float adjustedHeight = (PopUpHeight / 2) - (2 * padding);
    CGRect rect = CGRectMake(0, 0, PopUpWidth, PopUpHeight);
    CGRect topHalfRect = CGRectMake(padding, padding, adjustedWidth, adjustedHeight);
    CGRect bottomHalfRect = CGRectMake(padding, PopUpHeight * 0.5f + padding, adjustedWidth, adjustedHeight);
    UIColor* color = [UIColor colorWithRed:0.15f green:0.15f blue:0.15f alpha:1.0f];
    UIColor* textColor = [UIColor colorWithRed:0.8f green:0.8f blue:0.8f alpha:1.0f];
    
    /////////////
    /* QUALITY */
    /////////////
    //view and controller
        UIView* qualityView = [[UIView alloc] initWithFrame:rect];
        [qualityView setBackgroundColor:color];
        self.qualityController = [[UIViewController alloc] init];
        [qualityController setView:qualityView];
        
    //segment control
        self.qualityControl = [[UISegmentedControl alloc] initWithFrame:bottomHalfRect];
        [qualityControl insertSegmentWithTitle:@"Low" atIndex:0 animated:true];
        [qualityControl insertSegmentWithTitle:@"Medium" atIndex:1 animated:true];
        [qualityControl insertSegmentWithTitle:@"High" atIndex:2 animated:true];
        [qualityControl setSegmentedControlStyle:UISegmentedControlStyleBar];
        [qualityControl addTarget:self action:@selector(qualityControlClick:) forControlEvents:UIControlEventValueChanged];
        [qualityView addSubview:qualityControl];
        
    //label
        self.qualityLabel = [[UILabel alloc] initWithFrame:topHalfRect];
        [qualityLabel setText:@"Rendering Quality"];
        [qualityLabel setTextColor:textColor];
        [qualityLabel setOpaque:false];
        [qualityLabel setBackgroundColor:[UIColor clearColor]];
        [qualityLabel setTextAlignment:UITextAlignmentCenter];
        [qualityView addSubview:qualityLabel];
        
    //quality button
        self.qualityButton = [[UIButton alloc] initWithFrame:CGRectMake(16, 16, buttonWidth, buttonHeight)];
        [qualityButton setTitle:@"Quality" forState:UIControlStateNormal];
        [qualityButton setAlpha:buttonAlpha];
        [qualityButton addTarget:self action:@selector(qualityClick:) forControlEvents:UIControlEventTouchUpInside];
    
    //////////
    /* SIZE */
    //////////
    //view and controller
        UIView* sizeView = [[UIView alloc] initWithFrame:rect];
        [sizeView setBackgroundColor:color];
        self.sizeController = [[UIViewController alloc] init];
        [sizeController setView:sizeView];
    
    //slider
        self.sizeSlider = [[UISlider alloc] initWithFrame:bottomHalfRect];
        [sizeSlider setMaximumValue:MaxScale];
        [sizeSlider setMinimumValue:MinScale];
        [sizeSlider setValue:displayScaling];
        [sizeSlider addTarget:self action:@selector(sliderChange:) forControlEvents:UIControlEventValueChanged];
        [sizeView addSubview:sizeSlider];
    
    //label
        self.sizeLabel = [[UILabel alloc] initWithFrame:topHalfRect];
        [sizeLabel setText:@"Screen Scaling"];
        [sizeLabel setTextColor:textColor];
        [sizeLabel setOpaque:false];
        [sizeLabel setTextAlignment:UITextAlignmentCenter];
        [sizeLabel setBackgroundColor:[UIColor clearColor]];
        [sizeView addSubview:sizeLabel];
    
    //size button
        self.sizeButton = [[UIButton alloc] initWithFrame:CGRectMake(240, 16, buttonWidth, buttonHeight)];
        [sizeButton setTitle:@"Screen" forState:UIControlStateNormal];
        [sizeButton setAlpha:buttonAlpha];
        [sizeButton addTarget:self action:@selector(sizeClick:) forControlEvents:UIControlEventTouchUpInside];
    
    //////////
    /* PATH */
    //////////
    //view and controller
        UIView* pathView = [[UIView alloc] initWithFrame:rect];
        [pathView setBackgroundColor:color];
        self.pathController = [[UIViewController alloc] init];
        [pathController setView:pathView];
    
    //reset button
        self.pathResetButton = [[UIButton alloc] initWithFrame:bottomHalfRect];
        [pathResetButton setTitle:@"Generate New" forState:UIControlStateNormal];
        [pathResetButton setTitleColor:[UIColor yellowColor] forState:UIControlStateNormal];
        [pathResetButton setBackgroundColor:[UIColor blackColor]];
        [pathResetButton addTarget:self action:@selector(pathResetClick:) forControlEvents:UIControlEventTouchUpInside];
        [pathView addSubview:pathResetButton];
    
    //label
        self.pathLabel = [[UILabel alloc] initWithFrame:topHalfRect];
        [pathLabel setText:@"Camera Path"];
        [pathLabel setTextColor:textColor];
        [pathLabel setTextAlignment:UITextAlignmentCenter];
        [pathLabel setOpaque:false];
        [pathLabel setBackgroundColor:[UIColor clearColor]];
        [pathView addSubview:pathLabel];
                
    //path button
        self.pathButton = [[UIButton alloc] initWithFrame:CGRectMake(464, 16, buttonWidth, buttonHeight)];
        [pathButton setTitle:@"Cam" forState:UIControlStateNormal];
        [pathButton setAlpha:buttonAlpha];
        [pathButton addTarget:self action:@selector(pathClick:) forControlEvents:UIControlEventTouchUpInside];
    
    //////////
    /* INFO */
    //////////
    //view and controller
        UIView* infoView = [[UIView alloc] initWithFrame:rect];
        [infoView setBackgroundColor:color];
        self.infoController = [[UIViewController alloc] init];
        [infoController setView:infoView];
    
    //information label
        self.descriptionLabel = [[UILabel alloc] initWithFrame:rect];
        [descriptionLabel setText:@" Spheres! 1.0 \n A realtime iOS ray tracer! \n aaron.geisler.sloth@gmail.com"];
        [descriptionLabel setTextAlignment:UITextAlignmentCenter];
        [descriptionLabel setLineBreakMode:UILineBreakModeWordWrap];
        [descriptionLabel setNumberOfLines:4];
        [descriptionLabel setTextColor:textColor];
        [descriptionLabel setOpaque:false];
        [descriptionLabel setBackgroundColor:[UIColor clearColor]];
        [infoView addSubview:descriptionLabel];
    
    //info button
        self.infoButton = [[UIButton alloc] initWithFrame:CGRectMake(688, 16, buttonWidth, buttonHeight)];
        [infoButton setTitle:@"Info" forState:UIControlStateNormal];
        [infoButton setAlpha:buttonAlpha];
        [infoButton addTarget:self action:@selector(infoClick:) forControlEvents:UIControlEventTouchUpInside];
    
    //init the UIView that we will add HUD controls to
    self.hudView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 768.0f, 1024.0f)];
    [hudView addSubview:qualityButton];
    [hudView addSubview:sizeButton];
    [hudView addSubview:pathButton];
    [hudView addSubview:infoButton];
    [hudView setMultipleTouchEnabled:true]; 
    [self.view addSubview:hudView];
    
    //sync controls with the settings
    [self syncInterfaceWithSettings];
    
    return true;
}
- (BOOL) tearDownHud{
    
    [qualityController release];
    [qualityButton release];
    [qualityLabel release];
    [qualityControl release];
    
    [sizeController release];
    [sizeButton release];
    [sizeLabel release];
    [sizeSlider release];
    
    [pathController release];
    [pathLabel release];
    [pathResetButton release];
    [pathButton release];
    
    [infoController release];
    [descriptionLabel release];
    [infoButton release];
    
     return true;
}

////////////
//GL STUFF//
////////////
- (BOOL) setupGL {
    
    EAGLContext *aContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    
    if (!aContext) {
        aContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES1];
    }
    
    if (!aContext) {
        NSLog(@"Failed to create ES context");
        return false;
    }else if (![EAGLContext setCurrentContext:aContext]){
        NSLog(@"Failed to set ES context current");
        return false;
    }
    
    self.context = aContext;
    [(EAGLView *)self.view setContext:context];
    [(EAGLView *)self.view setFramebuffer];
    
    return true;
}

- (BOOL) tearDownGL{
    if ([EAGLContext currentContext] == context)
        [EAGLContext setCurrentContext:nil];
	self.context = nil;	
    
    return true;
}

///////////
//BUFFERS//
///////////
- (BOOL) setupBuffers {
    //half resolution internal frame buffer
    glGenFramebuffersOES(1, &frameBufferQuarter);
    glGenFramebuffersOES(1, &frameBufferHalf);
    glGenFramebuffersOES(1, &frameBufferFull);
    return true;
}

- (BOOL) tearDownBuffers {
    //frame buffer
    glDeleteFramebuffersOES(1, &frameBufferQuarter);
    glDeleteFramebuffersOES(1, &frameBufferHalf);
    glDeleteFramebuffersOES(1, &frameBufferFull);
    return false;
}


////////////
//TEXTURES//
////////////
- (Texture2D*) internalTextureWithDivider:(int) divider andBuffer:(GLuint) buffer{
    
    if (divider <= 0 || buffer == 0)
        return nil;
    
    glBindFramebufferOES(GL_FRAMEBUFFER_OES, buffer);
    
    int texSize = TextureSize / divider;
    Texture2D* ret = [[Texture2D alloc] initWithData:0 pixelFormat:kTexture2DPixelFormat_RGBA8888 pixelsWide:texSize pixelsHigh:texSize contentSize:CGSizeMake(InternalWidth / divider , InternalHeight / divider)];

    glFramebufferTexture2DOES(GL_FRAMEBUFFER_OES, GL_COLOR_ATTACHMENT0_OES, GL_TEXTURE_2D , ret.name, 0);
    
    return ret;
}
- (BOOL) loadTextures {

    //quarter res
    internalTextureQuarter = [self internalTextureWithDivider:4 andBuffer:frameBufferQuarter];
   
    //half res
    internalTextureHalf = [self internalTextureWithDivider:2 andBuffer:frameBufferHalf];
    
    //full res
    internalTextureFull = [self internalTextureWithDivider:1 andBuffer:frameBufferFull];    
    
    //reset to default
    glBindFramebufferOES(GL_FRAMEBUFFER_OES, 1);
    
    //init test texture
    //testTexture = [[Texture2D alloc] initWithImage:[UIImage imageNamed:@"Test.png"]];
    
    return true;
}
- (BOOL) unloadTextures {
   
    [internalTextureQuarter dealloc];
    [internalTextureHalf dealloc];
    [internalTextureFull dealloc];

    return true;
}

////////////////
//DISPLAY LINK//
////////////////
- (BOOL) setupDisplayLink{
    
    animating = NO;
    displayLink = nil;
    [self setAnimationFrameInterval:FramerateDivider];
    
    return true;   
}
- (NSInteger)animationFrameInterval {
    return animationFrameInterval;
}
- (void)setAnimationFrameInterval:(NSInteger)frameInterval {
    if (frameInterval >= 1) {
        animationFrameInterval = frameInterval;
        
        if (animating) 
            [self stopAnimation];
        
        [self startAnimation];
        
    }
}
- (void)startAnimation {
    if (!animating) {
        
        CADisplayLink *aDisplayLink = [[UIScreen mainScreen] displayLinkWithTarget:self selector:@selector(update)];
        [aDisplayLink setFrameInterval:animationFrameInterval];
        [aDisplayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
        
        displayLink = aDisplayLink;
        
        animating = YES;
    }
}

- (void)stopAnimation
{
    if (animating) {
        [displayLink invalidate];
        displayLink = nil;
        animating = NO;
    }
}

- (void)drawFrame   {
    //error checks
    if ([context API] != kEAGLRenderingAPIOpenGLES2){
        NSLog(@"OpenGLES 2.0 not supported");
        return;
    }
    
    /*
     if (![self validateProgram:renderShader]) {
     NSLog(@"Failed to validate program: %d", renderShader);
     return;
     }
     if (![self validateProgram:textureShader]) {
     NSLog(@"Failed to validate program: %d", textureShader);
     return;
     }
     */
    
    //temp vars
    GLuint vertex = 0;
    GLuint uvCoord = 0;
    
    //geom defs
    static const GLfloat screenVertices[] = {
        -1.0f, -1.0f, 0.45f,
        1.0f, -1.0f, 0.45f,
        -1.0f,  1.0f, 0.45f,
        1.0f,  1.0f, 0.45f,
    };
    GLfloat squareVertices[] = {
        -displayScaling, -displayScaling,
        displayScaling, -displayScaling,
        -displayScaling,  displayScaling,
        displayScaling,  displayScaling,
    };
    
    float u = (float)InternalWidth / (float)TextureSize;
    float v = (float)InternalHeight / (float)TextureSize;
    GLfloat texCoords[] = {
        0.0f, 0.0f,
        u,    0.0f,
        0.0f, v,
        u,    v,
        
    };
    GLfloat x = 0.0f;
    GLfloat y = 0.0f;
    GLfloat z = 0.0f;
    
    //clear buffer
    [(EAGLView *)self.view setFramebuffer];
    glClearColor(0.1f, 0.1f, 0.1f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT);
    
    ///////////////
    /* SWITCHING */
    ///////////////
    GLuint tex = 0;
    int frameBuffer = 1;
    switch (renderDivider){
        case 1:
            frameBuffer = frameBufferFull;
            tex = internalTextureFull.name;
            break;
        case 2:
            frameBuffer = frameBufferHalf;
            tex = internalTextureHalf.name;
            break;
        case 4:
            frameBuffer = frameBufferQuarter;
            tex = internalTextureQuarter.name;
            break;
    }
    
    ////////////////////////////////
    //RENDER TO TEXTURE INTERNALLY//
    ////////////////////////////////
    //setup
    glUseProgram(renderShader);
    glBindFramebufferOES(GL_FRAMEBUFFER_OES, frameBuffer);
    glViewport(0, 0, InternalWidth / renderDivider, InternalHeight / renderDivider);
    
    //vertex attribute
    vertex = [[renderAttributeDict valueForKey:@"vertex"] unsignedIntValue];
    glEnableVertexAttribArray(vertex);
    glVertexAttribPointer(vertex, 3, GL_FLOAT, 0, 0, screenVertices);
    
    //set neg light dir uniform
    x = lightDir.x;
    y = lightDir.y;
    z = lightDir.z;
    GLuint negLightDir = [[renderUniformDict valueForKey:@"negLightDir"] unsignedIntValue];
    glUniform3f(negLightDir, x, y, z);
    
    //zoom uniform
    GLuint zoom = [[renderUniformDict   valueForKey:@"zoom"] unsignedIntValue];
    glUniform1f(zoom, cam.getZoom());
    
    //camera position uniform
    V3 cameraPosition = cam.getPos();
    GLuint cameraPos = [[renderUniformDict valueForKey:@"cameraPos"] unsignedIntValue];
    glUniform3f(cameraPos, cameraPosition.x, cameraPosition.y, cameraPosition.z);
    
    //view rotation matrix uniform
    //rotates [1, 0 , 0] 
    Mat4 cameraMat = cam.getRotationMat();
    GLfloat rot[] = {
        cameraMat[0][0],   cameraMat[1][0],   cameraMat[2][0],      
        cameraMat[0][1],   cameraMat[1][1],   cameraMat[2][1],      
        cameraMat[0][2],   cameraMat[1][2],   cameraMat[2][2],      
    };
    
    GLuint matrix = [[renderUniformDict valueForKey:@"matrix"] unsignedIntValue];
    glUniformMatrix3fv(matrix, 3, false, rot);
    
    //action
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    
    //teardown
    glDisableVertexAttribArray(vertex);
    glBindFramebufferOES(GL_FRAMEBUFFER_OES, 1);
    glUseProgram(0);
    
    /////////////////////////
    //DRAW ONTO SCREEN QUAD//
    /////////////////////////
    //setup
    glUseProgram(textureShader);
    glBindTexture(GL_TEXTURE_2D, tex);
    glViewport(0, 0, 768, 1024);
    
    //texture uniform
    GLuint texture = [[textureUniformDict valueForKey:@"textureSample"] unsignedIntValue];
    glUniform1i(texture, 0);
    
    //vertex attribute
    vertex = [[textureAttributeDict valueForKey:@"vertex"] unsignedIntValue];
    glVertexAttribPointer(vertex, 2, GL_FLOAT, 0, 0, squareVertices);
    glEnableVertexAttribArray(vertex);
    
    //uv coord attribute
    uvCoord = [[textureAttributeDict valueForKey:@"uvCoord"] unsignedIntValue];
    glVertexAttribPointer(uvCoord, 2, GL_FLOAT, 0, 0, texCoords);
    glEnableVertexAttribArray(uvCoord);
    
    //action
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
    
    //teardown 
    glBindTexture(GL_TEXTURE_2D, 0);
    glDisableVertexAttribArray(vertex);
    glDisableVertexAttribArray(uvCoord);
    glUseProgram(0);
    
    //draw
    [(EAGLView *)self.view presentFramebuffer];
    
}

//////////////////
//SHADER HELPERS//
//////////////////
- (BOOL) unloadShaders{
    if (renderShader) {
        glDeleteProgram(renderShader);
        renderShader = 0;
    }
    if (textureShader) {
        glDeleteProgram(textureShader);
        textureShader = 0;
    }
    
    return true;
}
- (BOOL) loadShaders{
    
    //error check
    if ([context API] != kEAGLRenderingAPIOpenGLES2)
        return false;
    
    //temp vars
    NSNumber* zero = [NSNumber numberWithUnsignedInt:0];
    NSNumber* one = [NSNumber numberWithUnsignedInt:1];
    NSNumber* two = [NSNumber numberWithUnsignedInt:2];
    
    /////////////////
    //render shader//
    /////////////////
    self.renderUniformDict = [[NSMutableDictionary alloc] init];
    [renderUniformDict setValue:zero forKey:@"negLightDir"];
    [renderUniformDict setValue:zero forKey:@"cameraPos"];
    [renderUniformDict setValue:zero forKey:@"matrix"];
    [renderUniformDict setValue:zero forKey:@"zoom"];
    
    self.renderAttributeDict = [[NSMutableDictionary alloc] init];
    [renderAttributeDict setValue:one forKey:@"vertex"];
    
    [self loadShaderWithName:@"Shader" shaderId:&renderShader uniformDict:renderUniformDict attributeDict:renderAttributeDict];
    
    //////////////////
    //texture shader//
    //////////////////
    self.textureUniformDict = [[NSMutableDictionary alloc] init];
    [textureUniformDict setValue:zero forKey:@"textureSample"];
    
    self.textureAttributeDict = [[NSMutableDictionary alloc] init];
    [textureAttributeDict setValue:one forKey:@"vertex"];
    [textureAttributeDict setValue:two forKey:@"uvCoord"];
    
    [self loadShaderWithName:@"Texture" shaderId:&textureShader uniformDict:textureUniformDict attributeDict:textureAttributeDict];
    
    return true;
}
- (BOOL)compileShader:(GLuint *)shader type:(GLenum)type file:(NSString *)file {
    GLint status;
    const GLchar *source;
    
    source = (GLchar *)[[NSString stringWithContentsOfFile:file encoding:NSUTF8StringEncoding error:nil] UTF8String];
    if (!source) {
        NSLog(@"Failed to load shader");
        return NO;
    }
    
    //create gl shader
    *shader = glCreateShader(type);
    glShaderSource(*shader, 1, &source, NULL);
    glCompileShader(*shader);
    
    //error check
    GLint logLength;
    glGetShaderiv(*shader, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetShaderInfoLog(*shader, logLength, &logLength, log);
        NSLog(@"Shader compile log:\n%s", log);
        free(log);
    }
    
    glGetShaderiv(*shader, GL_COMPILE_STATUS, &status);
    if (status == 0)    {
        glDeleteShader(*shader);
        return NO;
    }
    
    return YES;
}

- (BOOL)linkProgram:(GLuint)prog
{
    GLint status;
    
    glLinkProgram(prog);
    
    //error check
    GLint logLength;
    glGetProgramiv(prog, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0)
    {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetProgramInfoLog(prog, logLength, &logLength, log);
        NSLog(@"Program link log:\n%s", log);
        free(log);
    }
    
    glGetProgramiv(prog, GL_LINK_STATUS, &status);
    if (status == 0)
        return NO;
    
    return YES;
}

- (BOOL)validateProgram:(GLuint)prog
{
    GLint logLength, status;
    
    glValidateProgram(prog);
    glGetProgramiv(prog, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0)  {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetProgramInfoLog(prog, logLength, &logLength, log);
        NSLog(@"Program validate log:\n%s", log);
        free(log);
    }
    
    glGetProgramiv(prog, GL_VALIDATE_STATUS, &status);
    if (status == 0)
        return NO;
    
    return YES;
}


- (BOOL)loadShaderWithName:(NSString*) shaderName shaderId:(GLuint*) shader uniformDict:(NSMutableDictionary*) uDict attributeDict:(NSMutableDictionary*) aDict
{
    NSString *vertShaderPathname, *fragShaderPathname;
    GLuint vertShader, fragShader;
    // Create shader program.
    *shader = glCreateProgram();
    
    // Create and compile vertex shader.
    vertShaderPathname = [[NSBundle mainBundle] pathForResource:shaderName ofType:@"vsh"];
    if (![self compileShader:&vertShader type:GL_VERTEX_SHADER file:vertShaderPathname]) {
        NSLog(@"Failed to compile vertex shader");
        return NO;
    }
    
    // Create and compile fragment shader.
    fragShaderPathname = [[NSBundle mainBundle] pathForResource:shaderName ofType:@"fsh"];
    if (![self compileShader:&fragShader type:GL_FRAGMENT_SHADER file:fragShaderPathname]) {
        NSLog(@"Failed to compile fragment shader");
        return NO;
    }
    
    // Attach vertex shader to program.
    glAttachShader(*shader, vertShader);
    
    // Attach fragment shader to program.
    glAttachShader(*shader, fragShader);
    
    // Bind attribute locations.
    GLuint attributeId = 0;
    for (id key in aDict){
        attributeId = [[aDict valueForKey:key] unsignedIntValue];
        glBindAttribLocation(*shader, attributeId, [key UTF8String]);
    }
    
    
    // Link program.
    if (![self linkProgram:*shader]) {
        NSLog(@"Failed to link program: %d", *shader);
        
        if (vertShader) {
            glDeleteShader(vertShader);
            vertShader = 0;
        }
        if (fragShader) {
            glDeleteShader(fragShader);
            fragShader = 0;
        }
        if (*shader) {
            glDeleteProgram(*shader);
            *shader = 0;
        }
        
        return NO;
    }
    
    // Get uniform locations.
    GLuint uniformId = 0;
    NSMutableDictionary* uniformDict = [[NSMutableDictionary alloc] initWithDictionary:uDict copyItems:false];
    for (id key in uniformDict){
        uniformId = glGetUniformLocation(*shader, [key UTF8String]);
        [uDict setValue:[NSNumber numberWithUnsignedInt:uniformId] forKey:key];
    }
    [uniformDict release];
    
    // Release vertex and fragment shaders.
    if (vertShader){
        glDetachShader(*shader, vertShader);
        glDeleteShader(vertShader);
    }
    if (fragShader){
        glDetachShader(*shader, fragShader);
        glDeleteShader(fragShader);
    }
    
    return YES;
}

/////////////////////////////////
/*TouchController communication*/
/////////////////////////////////
- (void)linkTouchController:(TouchController*) linkedController{
	touchController = linkedController;
}

- (void) touchHelper:(NSSet *)touches{
    
	int i, len;
	SEL selector;
	UITouch *touch; 
	CGPoint touchPoint;	
	TouchObj* passObj = [[TouchObj alloc] init];
	len = [touches count];
	
	//bound max touches
	if (len > HWMaxTouches)
		len = HWMaxTouches;
	
	//for each touch 
	for (i = 0; i < len; i++){
		
		//get the touch out of set
		touch = [[touches allObjects] objectAtIndex:i];
		
		//what state is this touch in
		UITouchPhase state=[touch phase];
		switch (state){
			case UITouchPhaseBegan:
				selector=@selector(startTouchWithObj:);
				break;
			case UITouchPhaseEnded:
				selector=@selector(endTouchWithObj:);
				break;
			case UITouchPhaseCancelled:
				selector=@selector(endTouchWithObj:);
				break;
			case  UITouchPhaseStationary:
				selector=@selector(moveTouchWithObj:);
				break;
			case UITouchPhaseMoved:
				selector=@selector(moveTouchWithObj:);
				break;
		}
		
		//set properties of passObj
		[passObj setTaps:[touch tapCount]];
		touchPoint = [touch locationInView:self.view];
		touchPoint.y = -(touchPoint.y-1024.0f);
		[passObj setPoint:touchPoint];
		
		//let touch controller do the rest
		[touchController performSelector:selector withObject:passObj];
	}
	
	//release that obj
	[passObj release];
}
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
	[self touchHelper:touches];
}
- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
	[self touchHelper:touches];
}
- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
	[self touchHelper:touches];
}
- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
	[self touchHelper:touches];
}
/////////
/*ACCEL*/
/////////
@synthesize accelerometer;
- (void)accelerometer:(UIAccelerometer *)accelerometer didAccelerate:(UIAcceleration *)acceleration {
	V3 accel=V3(acceleration.x,acceleration.y,acceleration.z);
	[touchController accelUpdate:&accel];
}

///////////
/* SCENE */
///////////
- (BOOL) setupScene {
    angle = fRand() * twoPi;
    lightDir = V3(1.0f, 0.0f, 0.0f);
    return true;
}
- (void) updateScene {
    angle += LightRotateSpeed;
    lightDir = V3(0.0f, cosf(angle), sinf(angle));
    lightDir = unit3(&lightDir);
}

- (BOOL) tearDownScene{
    return true;
}

//////////
/*CAMERA*/
//////////
- (void) updateCamera{
    
    [touchController update];
    
    //local
    bool pan = true;
    float deltaX = 0.0f;
    float deltaY = 0.0f;
    int touches[5];
    int count = [touchController getDown:touches];
    
    //single finger panning
    if (count == 1){
        Touch* touch = [touchController getTouchWithIndex:touches[0]];
        
        //early return if its not an active touch
        if (touch->down){
            deltaX = touch->currVelocity.x;
            deltaY = touch->currVelocity.y;
            pan = false;
        }
    }
    
    deltaX *= renderDivider;
    deltaY *= renderDivider;
    
    //update camera object with input
    cam.control(deltaX, deltaY, pan, touchController.pinchValue);
    
    [touchController recievedTaps];
    
}
- (BOOL) setupCamera{
    
    V3 p3 = randUnit3();
    p3 = mult3(&p3, fRand() * 4.0f + 4.0f);
    V2 p2 = V2(p3.x, p3.y);
    V2 o2 = V2();
    float dir = dir2(&p2, &o2);
    
    //init camera
    cam = Camera(&p3, dir);
    
    return true;
    
}
- (BOOL) tearDownCamera{
    //nothing
    return true;
}
@end
