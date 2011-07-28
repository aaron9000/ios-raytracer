#include "MathHelper.h"
#include "mat4.h"

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
	if (rand() % 2 == 0){
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
V3 randUnit3(float zScale){
    float phi = fRand() * twoPi;
    float z = (2.0f * fRand()) - 1.0f;
    float cosPhi = cosf(phi);
    float sinPhi = sinf(phi);
    V3 vec = V3(cosPhi, sinPhi, 0.0f);
    vec = mult3(&vec, sqrtf(1.0f - (z * z)));
    vec.z = z * zScale;
    vec = unit3(&vec);
	return(vec);
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
	return(sqrtf(a->x*a->x+a->y*a->y+a->z*a->z));
}
float dist3(V3* a, V3* b){
	float dx=a->x-b->x;
	float dy=a->y-b->y;
	float dz=a->z-b->z;
	return(sqrt(dx*dx+dy*dy+dz*dz));
}


//rotation matrix for a FPS style camera from a unit vector
Mat4 fpsRotMat(V3* f){
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
