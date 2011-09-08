
#ifndef TOUCHOBJ
#define TOUCHOBJ

#import <Foundation/Foundation.h>

@interface TouchObj : NSObject {
	int taps;
	CGPoint point;
	
}

@property int taps;
@property CGPoint point;

@end

#endif