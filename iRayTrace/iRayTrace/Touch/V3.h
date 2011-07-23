//3d point class
#ifndef V3_H
#define V3_H
class V3{
public:
	//vars
	float x;
	float y;
	float z;
	
	//methods
	/*
	V3();
	V3(float val_x, float val_y, float val_z);
	V3(const V3& source); 
	
	const V3& operator=(const V3& source);
	bool operator==(const V3 &other) const;	
	bool operator!=(const V3 &other) const;
	void copy(const V3& source);
	 */
	inline V3(){
		x=0.0f;
		y=0.0f;
		z=0.0f;
	}
	inline V3(float val_x, float val_y,float val_z){
		x = val_x;
		y = val_y;
		z = val_z;
	}
	inline V3(const V3& source){
		copy(source);
	}
	inline const V3& operator=(const V3& source){
		if (this != &source) 
			copy(source);
		return *this;
	}
	inline bool operator==(const V3 &other) const{
		return ((x == other.x) && (y == other.y) && (z==other.z));
	}
	inline bool operator!=(const V3 &other) const{
		return ((x != other.x) || (y != other.y) || (z!=other.z));
	}
	inline void copy(const V3& source){
		x = source.x;
		y = source.y;
		z = source.z;
	}
	
};
#endif

