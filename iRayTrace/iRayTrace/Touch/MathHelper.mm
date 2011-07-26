#include "MathHelper.h"

////////////////////
/*HELPER FUNCTIONS*/
////////////////////
//reflection
/*
V2 reflection2(V2* unit,V2* normal,V3* friction) {
	//friction
	//x = air friction
	//y = slide friction
	//z = bounce friction
	float dotProd=dot2(unit,normal);
	float factor=2*(.5*(friction->y/friction->z)+.5);
	float ratio=fabs(dotProd);
	float dampening=ratio*friction->z+(1-ratio)*friction->y;
	V2 ret=mult2(normal,dotProd*factor);
	ret=sub2(unit,&ret);
	ret=mult2(&ret,dampening);
	return (ret);
}
 */
//random sign +/- 1.0f
float randSign(){
	if (rand()%2==0){
		return 1.0f;
	}else{
		return -1.0f;
	}
	
}
//random float
float fRand(){
	return(float(rand()%RAND_MAX)/RAND_MAX);
}
//3d
V3 mult3(V3* a, float scalar){
	return (V3(a->x*scalar,a->y*scalar,a->z*scalar));
}
V3 add3(V3* a, V3* b){
	return(V3(a->x + b->x,a->y + b->y,a->z + b->z));
}
V3 sub3(V3* a, V3* b){
	return(V3(a->x - b->x,a->y - b->y,a->z - b->z));
}
V3 avg3(V3* a, V3* b){
	return(V3((a->x + b->x)*.5,(a->y + b->y)*.5,(a->z + b->z)*.5));
}
V3 unit3(V3* a){
	if (a->x!=0 || a->y!=0 || a->z!=0){
		float m=mag3(a);
		return(mult3(a,1/m));
	}
	return V3();
}
V3 cross3( V3* a, V3* b ) {
	return  V3((b->y * a->z) - (b->z * a->y), (b->z * a->x) - (b->x * a->z), (b->x * a->y) - (b->y * a->x));
}
V3 randUnit3(){
	return(V3());
}
V3 sphericalToUnit(float longitude, float latitude){
    
    float cosLat = cosf(latitude);
    float sinLat = sinf(latitude);
    float cosLong = cosf(longitude);
    float sinLong = sinf(longitude);
    
    float x = cosLong * cosLat;
    float y = sinLong * cosLat;
    float z = sinLat;
    
    
    //NSLog(@"%f, %f, %f",x, y, z);
    V3 ret = V3(x, y, z);
    
    return ret;
}
float dot3(V3* a, V3* b){
	return((a->x * b->x)+(a->y * b->y)+(a->z * b->z));
}
float mag3(V3* a){
	return(sqrt(a->x*a->x+a->y*a->y+a->z*a->z));
}
float dist3(V3* a, V3* b){
	float dx=a->x-b->x;
	float dy=a->y-b->y;
	float dz=a->z-b->z;
	return(sqrt(dx*dx+dy*dy+dz*dz));
}

 

//direction stuff
float findDir(float d1,float  d2) {
   float dir = d1-d2;
   if (dir<(-pi)) 
	   dir = dir+twoPi;
   if (dir>pi) 
	   dir = dir-twoPi;
   return dir;
}
//find 2d direction between 2 points
float dir2(V2* a,V2* b) {
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
/*

BOOL segmentIntersect(V2* a,V2* b, V2* c, V2* d, Collision2* collisionData) {
	
	collisionData->occured=false;
	int l1type =-1;
	int l2type = -1;
	float tempx = 0;
	float tempy = 0;
	float m1 = 0;
	float m2 = 0;
	float b1 = 0;
	float b2 = 0;
	float l1_x1=a->x;
	float l1_y1=a->y;
	float l1_x2=b->x;
	float l1_y2=b->y;
	float l2_x1=c->x;
	float l2_y1=c->y;
	float l2_x2=d->x;
	float l2_y2=d->y;
	
	if (l1_x1-l1_x2 == 0) 
		l1type = 1;
	if (l2_x1-l2_x2 == 0) 
		l2type = 1;
	if (l1_y1-l1_y2 == 0) 
		l1type = 0;
	if (l2_y1-l2_y2 == 0) 
		l2type = 0;
	
	if (l1type+l2type == -2) {
		m1 = (l1_y1-l1_y2)/(l1_x1-l1_x2);
		m2 = (l2_y1-l2_y2)/(l2_x1-l2_x2);
		if (m2-m1 != 0) {
			b1 = -m1*l1_x1+l1_y1;
			b2 = -m2*l2_x1+l2_y1;
			tempy = (b1*m2-b2*m1)/(m2-m1);
			tempx = (b2-b1)/(m1-m2);
		} else {
			return false;
		}
	} else if (l1type != l2type) {
		if (l1type != -1 && l2type != -1) {
			if (l1type == 0 && l2type == 1) {
				tempx = l2_x1;
				tempy = l1_y1;
			}
			if (l1type == 1 && l2type == 0) {
				tempx = l1_x1;
				tempy = l2_y1;
			}
		} else if (l1type == -1) {
			m1 = (l1_y1-l1_y2)/(l1_x1-l1_x2);
			b1 = -m1*l1_x1+l1_y1;
			if (l2type == 0) {
				tempy = l2_y1;
				tempx = (tempy-b1)/m1;
			} else {
				tempx = l2_x1;
				tempy = m1*tempx+b1;
			}
		} else {
			m2 = (l2_y1-l2_y2)/(l2_x1-l2_x2);
			b2 = -m2*l2_x1+l2_y1;
			if (l1type == 0) {
				tempy = l1_y1;
				tempx = (tempy-b2)/m2;
			} else {
				tempx = l1_x1;
				tempy = m2*tempx+b2;
			}
		}
	} else {
		return false;
	}
	
	
	
	if (l1_x1<=l1_x2) {
		if (tempx<l1_x1 || tempx>l1_x2) 
			return false;
		
	} else if (tempx>l1_x1 || tempx<l1_x2) {
		return false;
	}
	if (l1_y1<l1_y2) {
		if (tempy<l1_y1 || tempy>l1_y2) 
			return false;
		
	} else if (tempy>l1_y1 || tempy<l1_y2) {
		return false;
	}
	if (l2_x1<=l2_x2) {
		if (tempx<l2_x1 || tempx>l2_x2) 
			return false;
		
	} else if (tempx>l2_x1 || tempx<l2_x2) {
		return false;
	}
	if (l2_y1<=l2_y2) {
		if (tempy<l2_y1 || tempy>l2_y2) 
			return false;
		
	} else if (tempy>l2_y1 || tempy<l2_y2) {
		return false;
	}
	
	//to get collision data
	collisionData->pos=V2(tempx,tempy);
	collisionData->occured=true;
	
	return true;
	
}

*/

