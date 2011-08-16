//
//  Timer.h
//  iRayTrace
//
//  Created by Aaron on 7/29/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#include <mach/mach_time.h>

@interface Timer : NSObject {
@private
    
    //timing stuff
    int ticks;
    uint64_t oldTime;
    double timingFactor;
}

@property(nonatomic, readonly) int ticks;

//timing
- (void)tick;
- (void)startTiming;
- (int)endTiming:(NSString*) message;
- (uint64_t) getTime;
@end
