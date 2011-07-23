//
//  TouchData.h
//  iTumble
//
//  Created by John Doe on 5/30/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface TouchObj : NSObject {
	int taps;
	CGPoint point;
	
}

@property int taps;
@property CGPoint point;

@end
