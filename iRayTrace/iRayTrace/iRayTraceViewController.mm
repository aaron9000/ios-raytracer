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

#define InternalWidth 384
#define InternalHeight 512
#define FramerateDivider 3
#define LightRotateSpeed 0.015f

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
- (void)viewDidLoad
{
    //check what device the user has
    screenDivider = 1;
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
    
	//scaling and hi res support
	//UIScreen* screen = [UIScreen mainScreen];
	//bool retina = (BOOL)screen.scale == 2.0f;
    
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
        screenDivider = 2;
    
    //scale for simulator
    if ([model rangeOfString:@"Simulator"].location != NSNotFound)
        screenDivider = 2;
    
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
@synthesize controlsLabel;
@synthesize emailLabel;
@synthesize titleLabel;
- (BOOL) setupHud{
    
    //common
    float shade = 0.05f;
    UIFont* labelFont = [UIFont fontWithName:@"Arial" size:12.0f];
    UIColor* backColor = [UIColor colorWithRed:shade green:shade blue:shade alpha:1.0f];
    
    //init the UIView that we will add HUD controls to
    self.hudView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 768.0f, 1024.0f)];
    
    self.emailLabel = [[UILabel alloc] initWithFrame:CGRectMake(768.0f - 168.0f, 0.0f, 168.0f, 16.0f)];
    [emailLabel setTextColor:[UIColor yellowColor]];
    [emailLabel setTextAlignment:UITextAlignmentRight];
    [emailLabel setBackgroundColor:backColor];
    [emailLabel setText:@"aaron.geisler.sloth@gmail.com"];
    [emailLabel setFont:labelFont];
    
    self.titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 72.0f, 16.0f)];
    [titleLabel setTextColor:[UIColor yellowColor]];
    [titleLabel setTextAlignment:UITextAlignmentLeft];
    [titleLabel setBackgroundColor:backColor];
    [titleLabel setText:@"iSpheres 1.0"];
    [titleLabel setFont:labelFont];
    
    self.controlsLabel = [[UILabel alloc] initWithFrame:CGRectMake(384.0f - 134.0f, 1024.0f - 16.0f, 268.0f, 16.0f)];
    [controlsLabel setTextColor:[UIColor yellowColor]];
    [controlsLabel setTextAlignment:UITextAlignmentCenter];
    [controlsLabel setBackgroundColor:backColor];
    [controlsLabel setFont:labelFont];
    [controlsLabel setText:@"[ drag to pan - pinch to zoom - tap for new path ]"];
    
    //add controls to the view
    [hudView addSubview:controlsLabel];
    [hudView addSubview:emailLabel];
    [hudView addSubview:titleLabel];
    [hudView setMultipleTouchEnabled:true]; 
    
    //add as a subview over the rendered scene
    [self.view addSubview:hudView];
    
    return true;
}
- (BOOL) tearDownHud{
    [emailLabel release];
    [titleLabel release];
    [controlsLabel release];
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
    glGenFramebuffersOES(1, &halfFrameBuffer);
    return true;
}

- (BOOL) tearDownBuffers {
    //frame buffer
    glDeleteFramebuffersOES(1, &halfFrameBuffer);
    return false;
}


////////////
//TEXTURES//
////////////
- (BOOL) loadTextures {
    
    //init internal texture
    internalTexture = [[Texture2D alloc] initWithData:0 pixelFormat:kTexture2DPixelFormat_RGBA8888 pixelsWide:512 pixelsHigh:512 contentSize:CGSizeMake(InternalWidth / screenDivider , InternalHeight / screenDivider)];
    glBindFramebufferOES(GL_FRAMEBUFFER_OES, halfFrameBuffer);
    glFramebufferTexture2DOES(GL_FRAMEBUFFER_OES, GL_COLOR_ATTACHMENT0_OES, GL_TEXTURE_2D , internalTexture.name, 0);
    glBindFramebufferOES(GL_FRAMEBUFFER_OES, 1);
    
    //init test texture
    testTexture = [[Texture2D alloc] initWithImage:[UIImage imageNamed:@"Test.png"]];
    
    return true;
}
- (BOOL) unloadTextures {
    [internalTexture dealloc];
    /*
    [internalTextureHalf dealloc];
    [internalTextureFull dealloc];
    [internalTextureQuarter dealloc];
    */
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
    static const GLfloat squareVertices[] = {
        -1.0f, -1.0f,
        1.0f, -1.0f,
        -1.0f,  1.0f,
        1.0f,  1.0f,
    };
    
    float u = InternalWidth / (screenDivider * 512.0f);
    float v = InternalHeight / (screenDivider * 512.0f);
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
    glClearColor(0.5f, 0.5f, 0.5f, 1.0f);
    glClear(GL_COLOR_BUFFER_BIT);
    
    ////////////////////////////////
    //RENDER TO TEXTURE INTERNALLY//
    ////////////////////////////////
    //setup
    glUseProgram(renderShader);
    glBindFramebufferOES(GL_FRAMEBUFFER_OES, halfFrameBuffer);
    glViewport(0, 0, InternalWidth / screenDivider, InternalHeight / screenDivider);
    
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
    GLuint tex = internalTexture.name;
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
    
    //double tap path reset
    if ([touchController getDoubleTaps:nil] > 0)
        [self setupCamera];
    
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
