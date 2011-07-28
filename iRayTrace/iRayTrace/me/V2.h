//2d point class
#ifndef V2_H
#define V2_H
class V2{
public:
	//vars
	float x;
	float y;
	
	//methods
	/*
	inline V2();
	inline V2(float val_x, float val_y);
	inline V2(const V2& source); 
	*/
	//2d point class
	inline V2(){
		x=0.0f;
		y=0.0f;
	}
	inline V2(float val_x, float val_y){
		x = val_x;
		y = val_y;
	}
	inline bool operator==(const V2 &other) const{
		return ((x == other.x) && (y == other.y));
	}
	inline bool operator!=(const V2 &other) const{
		return ((x != other.x) || (y != other.y));
	}
	 
};
#endif

