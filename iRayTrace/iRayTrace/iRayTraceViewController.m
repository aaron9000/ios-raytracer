//
//  iPhotonViewController.m
//  iPhoton
//
//  Created by Aaron on 6/8/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>

#import "iRayTraceViewController.h"
#import "EAGLView.h"


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

/////////////
//CONSTANTS//
/////////////
//must be less than 512 x 512
#define INTERNAL_WIDTH 384
#define INTERNAL_HEIGHT 512
//must be integer >= 1
#define FRAMERATE_DIVIDER 3

////////
//MAIN//
////////
- (void)viewDidLoad
{
    
    //
    [self setupTiming];
    
    //
    [self setupGL];
    
    //
    [self setupNotifications];
    
    
    //
    [self setupDisplayLink];
    
    
    //
    [self setupBuffers];
    
    
    //
    [self loadShaders];
    
    
    //
    [self loadTextures];
    
    
    
}
- (void)dealloc
{
    
    [self unloadShaders];
    
    [self unloadTextures];
    
    [self tearDownBuffers];
    
    [self tearDownGL];
    
    [self tearDownNotifications];
    
    [super dealloc];
}

////////////
//GL STUFF//
////////////
- (BOOL) setupGL{
    
    EAGLContext *aContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    
    if (!aContext) {
        aContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES1];
    }
    
    if (!aContext){
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


//////////////////
//EVENT HANDLING//
//////////////////
- (BOOL) tearDownNotifications{
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    return true;
}
- (BOOL) setupNotifications {
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillResignActive:) name:UIApplicationWillResignActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidBecomeActive:) name:UIApplicationDidBecomeActiveNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillTerminate:) name:UIApplicationWillTerminateNotification object:nil];
    
    return true;
}

- (void)applicationWillResignActive:(NSNotification *)notification  {
    if ([self isViewLoaded] && self.view.window) {
        [self stopAnimation];
    }
}

- (void)applicationDidBecomeActive:(NSNotification *)notification
{
    if ([self isViewLoaded] && self.view.window) {
        [self startAnimation];
    }
}

- (void)applicationWillTerminate:(NSNotification *)notification
{
    if ([self isViewLoaded] && self.view.window) {
        [self stopAnimation];
    }
}

- (void)didReceiveMemoryWarning {
    
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc. that aren't in use.
}

- (void)viewWillAppear:(BOOL)animated   {
    
    [self startAnimation];
    
    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated    {
    
    [self stopAnimation];
    
    [super viewWillDisappear:animated];
}

- (void)viewDidUnload   {
	
    [self unloadShaders];
    
    [self unloadTextures];
    
    [self tearDownGL];
    
    [super viewDidUnload];
    
    
}

///////////
//BUFFERS//
///////////
- (BOOL) setupBuffers {
    
    //half resolution internal frame buffer
    glGenFramebuffersOES(1, &halfFrameBuffer);
    
    
    //half resolution render buffer
    /*
     glGenRenderbuffersOES(1, &halfRenderBuffer);
     glBindRenderbufferOES(GL_RENDERBUFFER_OES, halfRenderBuffer);
     
     //change bounds of layer
     glRenderbufferStorage(GL_RENDERBUFFER_OES, GL_RGBA8_OES, 128, 128);
     
     GLint w = 0;
     GLint h = 0;
     glGetRenderbufferParameteriv(GL_RENDERBUFFER_OES, GL_RENDERBUFFER_WIDTH, &w);
     glGetRenderbufferParameteriv(GL_RENDERBUFFER_OES, GL_RENDERBUFFER_HEIGHT, &h);
     glBindRenderbufferOES(GL_RENDERBUFFER_OES, 1);
     */
    
    return true;
}

- (BOOL) tearDownBuffers {
    
    //frame buffer
    glDeleteFramebuffersOES(1, &halfFrameBuffer);
    
    
    //render buffer
    //glDeleteRenderbuffers(1, &halfRenderBuffer);
    
    return false;
}


////////////
//TEXTURES//
////////////
- (BOOL) loadTextures {
    
    //init internal texture
    internalTexture = [[Texture2D alloc] initWithData:0 pixelFormat:kTexture2DPixelFormat_RGBA8888 pixelsWide:512 pixelsHigh:512 contentSize:CGSizeMake(INTERNAL_WIDTH , INTERNAL_HEIGHT)];
    glBindFramebufferOES(GL_FRAMEBUFFER_OES, halfFrameBuffer);
    glFramebufferTexture2DOES(GL_FRAMEBUFFER_OES, GL_COLOR_ATTACHMENT0_OES, GL_TEXTURE_2D , internalTexture.name, 0);
    glBindFramebufferOES(GL_FRAMEBUFFER_OES, 1);
    
    //init test texture
    testTexture = [[Texture2D alloc] initWithImage:[UIImage imageNamed:@"Test.png"]];
    
    
    
    return true;
}
- (BOOL) unloadTextures {
    
    //halfFrameBuffer
    glDeleteFramebuffersOES(1, &halfFrameBuffer);
    
    
    //[internalTexture dealloc];
    
    
    return true;
}



////////////////
//DISPLAY LINK//
////////////////
- (BOOL) setupDisplayLink{
    
    animating = NO;
    animationFrameInterval = FRAMERATE_DIVIDER;
    displayLink = nil;
    
    return true;   
}
- (NSInteger)animationFrameInterval {
    return animationFrameInterval;
}
- (void)setAnimationFrameInterval:(NSInteger)frameInterval {
    if (frameInterval >= 1) {
        animationFrameInterval = frameInterval;
        
        if (animating) {
            [self stopAnimation];
            [self startAnimation];
        }
    }
}
- (void)startAnimation {
    if (!animating) {
        CADisplayLink *aDisplayLink = [[UIScreen mainScreen] displayLinkWithTarget:self selector:@selector(drawFrame)];
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
    
    GLfloat texCoords[] = {
        0.0f, 0.0f,
        INTERNAL_WIDTH/512.0f, 0.0f,
        0.0f, INTERNAL_HEIGHT/512.0f,
        INTERNAL_WIDTH/512.0f, INTERNAL_HEIGHT/512.0f,
        
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
    glViewport(0, 0, INTERNAL_WIDTH, INTERNAL_HEIGHT);
    
    
    //vertex attribute
    vertex = [[renderAttributeDict valueForKey:@"vertex"] unsignedIntValue];
    glEnableVertexAttribArray(vertex);
    glVertexAttribPointer(vertex, 3, GL_FLOAT, 0, 0, screenVertices);
    
    
    //set neg light dir uniform
    x = 0.624f;
    y = 0.78f;
    z = 0.06f;
    GLuint negLightDir = [[renderUniformDict valueForKey:@"negLightDir"] unsignedIntValue];
    glUniform3f(negLightDir, x, y, z);
    
    //camera position uniform
    x = 6.0f * sinf(ticks*0.015+ 0.7);
    y = 2.0f * sinf(ticks*0.01+ 0.27);
    z = 4.0f * sinf(ticks*0.025);
    GLuint cameraPos = [[renderUniformDict valueForKey:@"cameraPos"] unsignedIntValue];
    glUniform3f(cameraPos, x, y, z);
    
    //view rotation matrix uniform
    //rotates [1, 0 , 0] 
    GLfloat rot[] = {
        1.0f,   0,      0,      
        0,   1.0f,      0,      
        0,      0,   1.0f,      
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
    glActiveTexture(GL_TEXTURE0);
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
    glActiveTexture(0);
    glBindTexture(0, 0);
    glDisableVertexAttribArray(vertex);
    glDisableVertexAttribArray(uvCoord);
    glUseProgram(0);
    
    //draw
    [(EAGLView *)self.view presentFramebuffer];
    
    //do timing
    ticks++;
    [self endTiming:@"render MS = "];
    [self startTiming];
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
    
    *shader = glCreateShader(type);
    glShaderSource(*shader, 1, &source, NULL);
    [self startTiming];
    glCompileShader(*shader);
    [self endTiming:@"Compile shader MS = "];
    
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
    
    NSMutableDictionary* uniformDict = [[NSMutableDictionary alloc] initWithDictionary:uDict copyItems:true];
    for (id key in uniformDict){
        uniformId = glGetUniformLocation(*shader, [key UTF8String]);
        [uDict setValue:[NSNumber numberWithUnsignedInt:uniformId] forKey:key];
    }
    //[uDict removeAllObjects];
    //[uDict addEntriesFromDictionary:uniformDict];
    
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

///////////
//HELPERS//
///////////
- (float) getScreenDistance{
    float fov = 3.14f * 0.5f;
    float dist = cosf(fov * 0.5f)/sinf(fov * 0.5f);
    return dist;
}

////////////////
//TIMING STUFF//
////////////////
- (void) setupTiming{
    //
    ticks = 0;
    mach_timebase_info_data_t info;
    mach_timebase_info(&info);
    timingFactor=1e-9 *((double)info.numer)/((double)info.denom);
    oldTime=mach_absolute_time();
}
- (void)startTiming{
    //
	int64_t currTime = mach_absolute_time();
   	oldTime = currTime;
	
    
}
- (void)endTiming:(NSString*) message{
    //
    int64_t currTime = mach_absolute_time();
    int64_t dt = currTime - oldTime;
	int framerate = 60;
	if (dt > 0)
		framerate = ((1.0f / (dt * timingFactor)) + 0.5f);
    //NSLog(@"FPS = %i", (int)framerate);
    NSLog(@"%@ %i",message, (int)(dt * timingFactor * 1000));
}
@end
