#import "MathHelper.h"
#import "mat4.h"
#import "BezierPath.h"
class Camera{
	public:
		
		//positional
		V3 pos,lastPos;
        
        //zoom
        float zoom;
    
        //path
        BezierPath path;
        
        //rotational
        Mat4 cameraMat;
        float cameraLatitude;
        float cameraLongitude;

        //inactivity
        int idleTicker;

        //constructor
        Camera();
        Camera(V3 position, float inLongitude); 
        
        //methods
        void control(float deltaX, float deltaY, bool panToOrigin, float targetZoom);
        float constrainLong(float longitude);
        float constrainLat(float latitude);
    
        void reset();
            
	private:
};
