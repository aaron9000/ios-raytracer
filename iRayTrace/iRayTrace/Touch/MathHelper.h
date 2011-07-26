#ifndef MATHHELPER_H
#define MATHHELPER_H
#include <math.h>
#include "V2.h"
#include "V3.h"



////////////
/* CONSTS */
////////////
const float pi=3.14159265358979323846264338327950288;
const float quarterPi=pi*.25;
const float halfPi=pi*.5;
const float threeHalfPi=pi*1.5;
const float twoPi=pi*2;
const float radToDeg = 180/pi;
const float degToRad = pi/180;
////////////////////
/*HELPER FUNCTIONS*/
////////////////////

//BOOL intersectBoundary(V2* to,V2* from,float radius,V2* intersectPoint);

//random functions
float fRand();
float randSign();


//3d
V3 mult3(V3* a, float scalar);
V3 add3(V3* a, V3* b);
V3 sub3(V3* a, V3* b);
V3 avg3(V3* a, V3* b);
V3 unit3(V3* a);
V3 cross3( V3* a, V3* b );
V3 randUnit3();
V3 sphericalToUnit(float longitude, float latitude);
float dot3(V3* a, V3* b);
float mag3(V3* a);
float dist3(V3* a, V3* b);



//2d
//INLINED
inline V2 mult2(V2* a, float scalar){
	return (V2(a->x*scalar,a->y*scalar));
};
inline V2 add2(V2* a, V2* b){
	return(V2(a->x + b->x,a->y + b->y));
};
inline V2 sub2(V2* a, V2* b){
	return(V2(a->x - b->x,a->y - b->y));
};
inline V2 avg2(V2* a, V2* b){
	return(V2((a->x + b->x)*.5,(a->y + b->y)*.5));
};
inline V2 unit2(V2* a){
	float mag=sqrt(a->x*a->x+a->y*a->y);
	if (mag==0.0f){
		return(V2());
	}else{
		return(mult2(a,1.0f/mag));
	}
};
inline V2 randUnit2(){
	float dir=fRand()*twoPi;
	return(V2(cos(dir),sin(dir)));
};
inline float dot2(V2* a, V2* b){
	return((a->x * b->x)+(a->y * b->y));
};
inline float mag2(V2* a){
	return(sqrt(a->x*a->x+a->y*a->y));
};
inline float dist2(V2* a, V2* b){
	float dx=a->x-b->x;
	float dy=a->y-b->y;
	return(sqrt(dx*dx+dy*dy));
};
inline V2 randSpread2(float radius){
	V2 ret=randUnit2();
	ret=mult2(&ret,fRand()*radius);
	return ret;
}


//direction stuff
float findDir(float d1,float  d2);
float dir2(V2* a , V2* b);

#endif


