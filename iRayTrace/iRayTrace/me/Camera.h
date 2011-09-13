
#ifndef CAMERA
#define CAMERA

#import "MathHelper.h"
#import "mat4.h"
#import "BezierPath.h"

//consts
#define XSensitivity 0.0048f
#define YSensitivity 0.0032f
#define PanSpeed 0.04f
#define IdleTicks 50

class Camera{
public:

    
    //constructor
    Camera();
    Camera(V3* position, float inLongitude); 
    
    //public methods
    void control(float deltaX, float deltaY, bool panToOrigin, float targetZoom);
    V3 getPos();
    float getZoom();
    Mat4 getRotationMat();
private:
    
    //member vars
    V3 pos,lastPos;
    float zoom;
    BezierPath path;
    Mat4 cameraMat;
    float cameraLatitude;
    float cameraLongitude;
    int idleTicker;
    
    //private methods
    float constrainLong(float longitude);
    float constrainLat(float latitude);
    void reset();
    
};

#endif