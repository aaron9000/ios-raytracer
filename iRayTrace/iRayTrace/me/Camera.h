#import "MathHelper.h"
#import "mat4.h"

class Camera{
	public:
		
		//positional
		V3 pos,lastPos;
        
        //zoom
        float zoom;
    
        //rotational
        Mat4 cameraMat;
        float cameraLatitude;
        float cameraLongitude;

		//bezier
		float pathSpeed;
		float currT;
		unsigned int currNode;
    
        //inactivity
        int idleTicker;

		//path
		bool hasPath;
        int pathLength;
		V3 path[128];
	

        //default constructor
        Camera();
        Camera(V3 position, float inLongitude);
        void followPath(V3* center, int nodes, float spacing, float speed);
        V3 getBezierPos();
        void control(float deltaX, float deltaY, bool panToOrigin, float targetZoom);
    
        float constrainLong(float longitude);
        float constrainLat(float latitude);
    
        void reset();
            
	private:
};
