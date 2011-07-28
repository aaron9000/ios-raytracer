//
//  TouchController.h
//  iTumble
//
//  Created by John Doe on 5/20/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//
#ifndef TOUCHCONTROLLER
#define TOUCHCONTROLLER
#import <UIKit/UIKit.h>
#import <CoreFoundation/CoreFoundation.h>
#import <mach/mach_time.h>
#import "TouchObj.h"
#import "Touch.h"
#import "V3.h"
#import "MathHelper.h"


@interface TouchController : NSObject{
	Touch* touchArray;
	
	int activeTouchIndices[128];
	int activeTouchIndicesCount;
	
	double timingFactor;
	
	V3 currAccel,lastAccel;
	BOOL shaken;
}

//properties
@property V3 currAccel;
@property BOOL shaken;

//usable things
- (int) getTouchAtPoint:(V2*) point withinRadius:(float) radius;
- (Touch*) getTouchWithIndex:(int) index;
- (float) getTimeWithIndex:(int) index;
- (int) getDoubleTaps:(int*) touchIndexArray;
- (int) getTaps:(int*) touchIndexArray;
- (int) getDown:(int*) touchIndexArray;

//called from ViewController
- (void) accelUpdate:(V3*)accel;
- (void) recievedTaps;
- (void) startTouchWithObj:(TouchObj*) obj;
- (void) endTouchWithObj:(TouchObj*) obj;
- (void) moveTouchWithObj:(TouchObj*) obj;
- (int) getClosestToPos:(V2*) pos;
- (int) nextAvailable;
- (void) updateActive;

@end
#endif
