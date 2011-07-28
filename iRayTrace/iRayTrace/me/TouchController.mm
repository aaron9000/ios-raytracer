//
//  TouchController.m
//  iTumble
//
//  Created by John Doe on 5/20/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//


#import "TouchController.h"

#define HWMaxTouches 5
#define ShakeGs 2
#define ShakeDeltaG 2


@implementation TouchController

//////////////////////////
/* GET TOUCHES AND INFO */
//////////////////////////
- (int) getDown:(int*) touchIndexArray{
	int index;
	int count=0;
	int i;
	int len=activeTouchIndicesCount;
	for (i=0;i<len;i++){
		index=activeTouchIndices[i];
		if (touchArray[index].down){
				touchIndexArray[count]=index;
				count++;
		}
	}	

	return count;
}
- (int) getTaps:(int*) touchIndexArray{
int index;
	int count=0;
	int i;
	int len=activeTouchIndicesCount;
	for (i=0;i<len;i++){
		index=activeTouchIndices[i];
		if (touchArray[index].tapping && !touchArray[index].doubleTapped){
				touchIndexArray[count]=index;
				count++;
		}
	}	
	
	return count;
}
- (int) getDoubleTaps:(int*) touchIndexArray{
	int index;
	int count=0;
	int i;
	int len=activeTouchIndicesCount;
	for (i=0;i<len;i++){
		index=activeTouchIndices[i];
		if (touchArray[index].tapping && touchArray[index].doubleTapped){
			touchIndexArray[count]=index;
			count++;
		}
	}	
	
	return count;
}
- (int) getTouchAtPoint:(V2*) point withinRadius:(float) radius{
	//see if the user is touching near this point and return its touch index
	int index=[self getClosestToPos:point];
	if (index!=-1){
		if (dist2(&touchArray[index].pos,point)>radius)
			index=-1;
	}
	
	return index;
}
- (Touch*) getTouchWithIndex:(int) index{
	//get pointer to the touch with index
	if (index>=HWMaxTouches || index<0){
		NSLog(@"TouchController:getTouchWithIndex: index out of range");
		return nil;
	}else{
		return (&touchArray[index]);
	}
}

- (float)getTimeWithIndex:(int) index{
	
	//attempt to calculate touch time if possible
	float ret=0.0f;
	//check bounds
	if (index<0 || index>=HWMaxTouches){
		return ret;
		NSLog(@"TouchController:getTimeWithIndex: index out of range");
	}
	//calculate time
	Touch* t=&touchArray[index];
	if (t->initialTime!=0){
		if (t->down){
			uint64_t curTime=mach_absolute_time();
			ret=timingFactor*(curTime-t->initialTime);
		}else if (t->endTime!=0) {
			ret=timingFactor*(t->endTime-t->initialTime);
		}
	}
	return ret;
}



/////////
/*ACCEL*/
/////////
@synthesize shaken;
@synthesize currAccel;

- (void) accelUpdate:(V3*)accel{
	//update
	lastAccel=currAccel;
	currAccel=*accel;
	
	//see if shaking
	float lastMag=mag3(&currAccel);
	float mag=mag3(&lastAccel);
	shaken=BOOL(fabs(mag)>ShakeGs || fabs(lastMag-mag)>ShakeDeltaG);

}
///////////
/*HANDLERS*/
///////////
- (void) recievedTaps{
	int i;
	for (i=0;i<HWMaxTouches;i++)
		touchArray[i].tapping=false;
		
}

- (void) startTouchWithObj:(TouchObj*) obj{
	//extract info
	CGPoint point=[obj point];
	V2 loc=V2(point.x,point.y);
	int taps=[obj taps];
	
	//find next availble touch
	int index=[self nextAvailable];
	
	//check bounds
	if (index<0 || index>=HWMaxTouches){
		return;
		NSLog(@"TouchController:startTouchAtPoint: index out of range");
	}
	
	Touch* t=&touchArray[index];
	
	//tapping
	t->tapping=TRUE;
	
	//double tapping
	t->doubleTapped=BOOL(taps == 2);
	
	//is down
	t->down=TRUE;
	
	//get position
	t->initialPos=t->pos=loc;
	
	//get time somehow
	t->initialTime=mach_absolute_time();
	t->endTime=0;
	
	//no travel
	t->travel=0.0f;
	
	//velocity
	t->currVelocity=V2();
	
	//update displacement
	t->lastDisplacement=t->totalDisplacement=0.0f;
	
	//no owner at start
	t->hasOwner=false;
	
	//must redo active vec
	[self updateActive];

}

- (void)endTouchWithObj:(TouchObj*) obj{
	//extract info
	CGPoint point=[obj point];
	V2 loc=V2(point.x,point.y);
	int taps=[obj taps];
	
	//guess which one ended
	int index=[self getClosestToPos:&loc];
	
	//check bounds
	if (index<0 || index>=HWMaxTouches){
		return;
		NSLog(@"TouchController:endTouchAtPoint: index out of range");
	}
	
	Touch* t=&touchArray[index];
	
	//double tapping
	t->doubleTapped=BOOL(taps == 2);
	
	//no longer down
	t->down=FALSE;
	
	//determine when click ended
	t->endTime=mach_absolute_time();
	
	//calculate travel dist
	t->travel=dist2(&loc,&t->initialPos);
	
	//velocity
	t->currVelocity=sub2(&loc,&t->pos);
	
	//update displacement
	t->lastDisplacement=dist2(&loc,&t->pos);
	t->totalDisplacement+=t->lastDisplacement;
	
	//get position
	t->pos=loc;
	
	//must redo active vec
	[self updateActive];
}

- (void)moveTouchWithObj:(TouchObj*) obj{
	//extract info
	CGPoint point=[obj point];
	V2 loc=V2(point.x,point.y);
	int taps=[obj taps];
	
	//guess which one moved
	int index=[self getClosestToPos:&loc];
	
	//check bounds
	if (index<0 || index>=HWMaxTouches){
		return;
		NSLog(@"TouchController:moveTouchAtPoint: index out of range");
	}
	
	Touch* t=&touchArray[index];
	
	//double tapping
	t->doubleTapped=BOOL(taps == 2);
	
	//calculate travel dist
	t->travel=dist2(&loc,&t->initialPos);
	
	//velocity
	t->currVelocity=sub2(&loc,&t->pos);
	
	//update displacement
	t->lastDisplacement=dist2(&loc,&t->pos);
	t->totalDisplacement+=t->lastDisplacement;
	
	//get position
	t->pos=loc;
	
}
/////////////
/* HELPERS */
/////////////
- (int) nextAvailable{
	int index=-1;
	int i;
	for (i=0;i<HWMaxTouches;i++){
		if (!touchArray[i].down)
			index=i;
	}
	return index;
}
- (int) getClosestToPos:(V2*) pos{ 
	int ret=-1;
	int index=-1;
	int i;
	int len;
	float closest=HUGE_VAL;
	float dist=0.0f;

		//only user available touches
		len=activeTouchIndicesCount;
		for (i=0;i<len;i++){
			index=activeTouchIndices[i];
			if (touchArray[index].down){
				dist=dist2(pos,&touchArray[index].pos);
				if (dist<closest){
					closest=dist;
					ret=index;
				}
			}
		}	
	return ret;
}

- (void) updateActive{
	//clear old active list
	activeTouchIndicesCount = 0;
	
	int i;
	for (i=0;i<HWMaxTouches;i++){
		if (touchArray[i].down && activeTouchIndicesCount < 128)
			activeTouchIndices[activeTouchIndicesCount++] = i;
	}
}

///////////
/*GENERIC*/
///////////
- (id)init {
    if (self == [super init]) {
		
		//initialize
		touchArray  = (Touch*) malloc(sizeof(class Touch) * HWMaxTouches);
		int i;
		for (i=0;i<HWMaxTouches;i++)
			touchArray[i]=Touch();
		
		//active touches
		activeTouchIndicesCount = 0;
		
		//timing stuff
		mach_timebase_info_data_t info;
		mach_timebase_info(&info);
		timingFactor=1e-9 *((double)info.numer)/((double)info.denom);
		
		//accel
		currAccel=lastAccel=V3();
		shaken=FALSE;
		
    }
    return self;
}

- (void)dealloc {
	//release here
	free(touchArray);
	
	[super dealloc];
}

@end
