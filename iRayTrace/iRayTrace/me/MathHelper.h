#ifndef MATHHELPER_H
#define MATHHELPER_H

#include <math.h>
#include "V2.h"
#include "V3.h"
#include "mat4.h"

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
//random numbers
inline float randSign(){
	if (rand() % 2 == 0){
		return 1.0f;
	}else{
		return -1.0f;
	}
	
}
inline float fRand(){
	return(float(rand()%RAND_MAX)/RAND_MAX);
}

//2d
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

//3d 
inline V3 mult3(V3* a, float scalar){
	return (V3(a->x*scalar,a->y*scalar,a->z*scalar));
}
inline V3 add3(V3* a, V3* b){
	return(V3(a->x + b->x,a->y + b->y,a->z + b->z));
}
inline V3 sub3(V3* a, V3* b){
	return(V3(a->x - b->x,a->y - b->y,a->z - b->z));
}
inline V3 avg3(V3* a, V3* b){
	return(V3((a->x + b->x)*.5,(a->y + b->y)*.5,(a->z + b->z)*.5));
}
inline float mag3(V3* a){
	return(sqrtf(a->x*a->x+a->y*a->y+a->z*a->z));
}
inline V3 unit3(V3* a){
	if (a->x!=0 || a->y!=0 || a->z!=0){
		float m = mag3(a);
		return(mult3(a,1/m));
	}
	return V3();
}
inline V3 cross3( V3* a, V3* b ) {
	return  V3((b->y * a->z) - (b->z * a->y), (b->z * a->x) - (b->x * a->z), (b->x * a->y) - (b->y * a->x));
}
inline V3 randUnit3(){
    float phi = fRand() * twoPi;
    float z = (2.0f * fRand()) - 1.0f;
    float cosPhi = cosf(phi);
    float sinPhi = sinf(phi);
    V3 vec = V3(cosPhi, sinPhi, z);
    vec = mult3(&vec, sqrtf(1.0f - (z * z)));
    
	return(vec);
}
inline V3 sphericalToUnit(float longitude, float latitude){
    
    float cosLat = cosf(latitude);
    float sinLat = sinf(latitude);
    float cosLong = cosf(longitude);
    float sinLong = sinf(longitude);
    
    float x = cosLong * cosLat;
    float y = sinLong * cosLat;
    float z = sinLat;
    
    V3 ret = V3(x, y, z);
    
    return ret;
}
inline float dot3(V3* a, V3* b){
	return((a->x * b->x)+(a->y * b->y)+(a->z * b->z));
}

inline float dist3(V3* a, V3* b){
	float dx=a->x-b->x;
	float dy=a->y-b->y;
	float dz=a->z-b->z;
	return(sqrt(dx*dx+dy*dy+dz*dz));
}

//matrices
//rotation matrix for a FPS style camera from a unit vector
inline Mat4 fpsRotMat(V3* f){
    V3 l;
    *f = unit3(f);
    if (fabs(f->z) == 1.0f){
        l = V3(f->z, 0.0f, 0.0f);
    }else{
        V3 temp = V3(f->y, -f->x, 0.0f);
        l = unit3(&temp);
    }
    
    V3 u = cross3(f, &l);
    
    Mat4 m;
    m(0,0) = f->x;      m(0,1) = f->y;      m(0,2) = f->z;  m(0,3) = 0.0f;
    m(1,0) = l.x;       m(1,1) = l.y;       m(1,2) = l.z;   m(1,3) = 0.0f;
    m(2,0) = u.x;       m(2,1) = u.y;       m(2,2) = u.z;   m(2,3) = 0.0f;
    m(3,0) = 0.0f;      m(3,1) = 0.0f;      m(3,2) = 0.0f;  m(3,3) = 1.0f;
    
    return m;
}


//direction stuff
inline float findDir(float d1,float  d2) {
    float dir = d1 - d2;
    if (dir < -pi) 
        dir = dir + twoPi;
    if (dir>pi) 
        dir = dir - twoPi;
    return dir;
}

inline float dir2(V2* a,V2* b) {
	float temp=0.0f;
	float dx =b->x-a->x;
	float dy =b->y-a->y;
	if (dx!=0.0f && dy!=0.0f) {
		temp = atan(fabs(dy)/fabs(dx));
		if (dy<0.0f){
			if (dx<0.0f){ 
				temp=pi+temp;
			}else{
				temp=twoPi-temp;
			}
		}else{
			if (dx<0.0f)
				temp = pi-temp;
		}
	} else {
		if (dy==0.0f){
			if (dx>0.0f){
				temp=0.0f;
			}else{
				temp=pi;
			}
		}else{
			if (dy>0.0f){
				temp=halfPi;
			}else{
				temp=threeHalfPi;
			}
		}
	}
	return temp;
}

#endif


