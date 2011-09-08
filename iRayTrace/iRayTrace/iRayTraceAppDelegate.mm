//
//  iRayTraceAppDelegate.m
//  iRayTrace
//
//  Created by Aaron on 7/18/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "iRayTraceAppDelegate.h"

#import "EAGLView.h"

#import "iRayTraceViewController.h"

#import "TouchController.h"

@implementation iRayTraceAppDelegate


@synthesize window=_window;
@synthesize viewController=_viewController;
@synthesize touchController=_touchController;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    
    //set up touchController
    self.touchController = [[TouchController alloc] init];
    [_viewController linkTouchController:_touchController];

    // Override point for customization after application launch.
    self.window.rootViewController = self.viewController;
    return YES;
}

- (void)dealloc
{
    [_window release];
    [_viewController release];
    [_touchController release];
    [super dealloc];
}

@end
