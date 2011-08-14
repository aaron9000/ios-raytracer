#include "Touch.h"

//touch class
Touch::Touch(){
	hasOwner = false;
	initialPos = pos = currVelocity = V2();
	down = doubleTapped = tapping = false;
	initialTime = endTime = 0;
	travel = 0.0f;
	lastDisplacement = totalDisplacement = 0.0f;
}


