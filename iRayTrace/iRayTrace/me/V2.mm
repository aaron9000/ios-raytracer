#import "V2.h"

/*
//2d point class
V2::V2(){
	x=0.0f;
	y=0.0f;
}
V2::V2(float val_x, float val_y){
	x = val_x;
	y = val_y;
}
V2::V2(const V2& source){
	copy(source);
}

const V2& V2::operator=(const V2& source){
	if (this != &source) 
		copy(source);
	return *this;
}
bool V2::operator==(const V2 &other) const{
	return ((x == other.x) && (y == other.y));
}
bool V2::operator!=(const V2 &other) const{
	return ((x != other.x) || (y != other.y));
}
void V2::copy(const V2& source){
	x = source.x;
	y = source.y;
}
 */

/*
 uat mat_to_quat(Mat4* m){
 //must be orthonormal
 float t=1+(*m)(0,0) + (*m)(1,1) + (*m)(2,2);
 float w; 
 float x; 
 float y;
 float z;
 if (t>0){
 w=sqrt(t)*.5;
 x = ((*m)(2,1) - (*m)(1,2))/(4*w);
 y = ((*m)(0,2) - (*m)(2,0))/(4*w);
 z = ((*m)(1,0) - (*m)(0,1))/(4*w);
 }else{
 x=y=z=0;
 w=1;
 }
 
 return Quat(x,y,z,w); 
 }
 
 
 Mat4 simple_rot_mat(v3* f){
 v3 l;
 *f=norm(f);
 if (fabs(f->z)==1.0){
 l=v3(-f->z,0,0);
 }else{
 l=norm(&v3(-f->y,f->x,0));
 }
 
 v3 u=cross(f,&l);
 
 Mat4 m;
 m(0,0)=-l.x;  m(0,1)=-l.y;  m(0,2)=-l.z;  m(0,3)=0;
 m(1,0)=-u.x;  m(1,1)=-u.y;  m(1,2)=-u.z;  m(1,3)=0;
 m(2,0)=-f->x;  m(2,1)=-f->y;  m(2,2)=-f->z;  m(2,3)=0;
 m(3,0)=0;  m(3,1)=0;  m(3,2)=0;  m(3,3)=1;
 
 return m;
 }
 
 v3 spherical_to_unit(float longitude,float latitude){
 v3 ret=v3();
 float cos_lat=abs(cos(latitude));
 float sin_lat=sin(latitude);
 ret.x=-cos(longitude)*cos_lat;
 ret.y=-sin(longitude)*cos_lat;
 ret.z=-sin(latitude);
 return ret;
 }
 */



