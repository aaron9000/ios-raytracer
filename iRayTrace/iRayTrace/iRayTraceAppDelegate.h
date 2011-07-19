//
//  iRayTraceAppDelegate.h
//  iRayTrace
//
//  Created by Aaron on 7/18/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class iRayTraceViewController;

@interface iRayTraceAppDelegate : NSObject <UIApplicationDelegate> {

}

@property (nonatomic, retain) IBOutlet UIWindow *window;

@property (nonatomic, retain) IBOutlet iRayTraceViewController *viewController;

@end
