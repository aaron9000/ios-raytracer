//
//  TouchData.m
//  iTumble
//
//  Created by John Doe on 5/30/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "TouchObj.h"


@implementation TouchObj

///////////////////
/* SETTER/GETTER */
///////////////////
@synthesize taps;
@synthesize point;

///////////
/*GENERIC*/
///////////
- (id)init {
    if (self == [super init]) {
		taps=0;
		point = CGPointMake(0.0f,0.0f);
	}
    return self;
}

@end
