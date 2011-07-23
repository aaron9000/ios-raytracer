#ifndef TOUCH_H
#define TOUCH_H
#include "V2.h"
//touch class for storing touch data
class Touch{
	public:
	
	//ownership of this touch
	BOOL hasOwner;
	
	//where the touch is
	V2 initialPos;
	V2 pos;
	V2 currVelocity;
	
	//if the screen is being touched
	BOOL down;
	BOOL doubleTapped;
	BOOL tapping;
	
	//keeping track of when the touch started/ended
	uint64_t initialTime;
	uint64_t endTime;
	
	//how far from initial touch point the touch is
	float travel;
	
	//how much it moved / total
	float lastDisplacement;
	float totalDisplacement;
	
	//methods
	Touch();

};
#endif

