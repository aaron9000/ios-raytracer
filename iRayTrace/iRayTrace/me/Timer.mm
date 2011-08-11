//
//  Timer.m
//  iRayTrace
//
//  Created by Aaron on 7/29/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#import "Timer.h"


@implementation Timer

- (id)init
{
    self = [super init];
    if (self) {
        // Initialization code here.
        ticks = 0;
        mach_timebase_info_data_t info;
        mach_timebase_info(&info);
        timingFactor = 1e-9 * ((double)info.numer) / ((double)info.denom);
        oldTime = mach_absolute_time();
    }
    
    return self;
}

- (void)dealloc
{
    [super dealloc];
}

- (void) tick{
    ticks++;
}

- (void)startTiming{
    //
	int64_t currTime = mach_absolute_time();
   	oldTime = currTime;
	
    
}
- (int)endTiming:(NSString*) message{
    //
    int64_t currTime = mach_absolute_time();
    int64_t dt = currTime - oldTime;
	int framerate = 60;
	if (dt > 0)
		framerate = ((1.0f / (dt * timingFactor)) + 0.5f);
    
    
    //if you pass in a non null message it will output text
    if (message)
        NSLog(@"%@ %i",message, (int)(dt * timingFactor * 1000));
    
    
    return framerate;
    
}


@end
