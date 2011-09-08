#include "Camera.h"


Camera::Camera(){
    reset();
}
    
Camera::Camera(V3* position, float inLongitude){
        
    reset();

    //pass in args
    pos = lastPos = *position;
    
    //point in default direction
    cameraLongitude = inLongitude;

    //make a real path
    float sceneRotationVelocity = (fRand() * 0.3f + 0.4f) * randSign();
    path.createPath(position, 24, 1.6f, 0.08f, sceneRotationVelocity);
    
    NSLog(@"CAMERA START = %f %f %f", position->x,  position->y, position->z);
}
    
                    
void Camera::control(float deltaX, float deltaY, bool panToOrigin, float targetZoom){

   //zooming
    zoom = targetZoom;
    
    //auto centering
    if (panToOrigin){
        
        //start rseetting to look at the origin
        V2 origin = V2();

        //we are idle
        idleTicker++;
        idleTicker = MIN(idleTicker, IdleTicks);
        
        //find idle ratio
        float idleRatio = (float)idleTicker / (float)IdleTicks;
        idleRatio *= idleRatio;
          
        //longitude
        V2 pos2 = V2(pos.x, pos.y);
        float idealLongitude = constrainLong(dir2(&pos2, &origin));
        float deltaLong = findDir(cameraLongitude, idealLongitude);
        if (fabs(deltaLong) <= PanSpeed){
            cameraLongitude = idealLongitude;
            
        }else{
            if (deltaLong > 0.0f){
                cameraLongitude -= PanSpeed * idleRatio;
            }else{
                cameraLongitude += PanSpeed * idleRatio;
            }
        }
        cameraLongitude = constrainLong(cameraLongitude);
        
    }else{
        
        //zoom ratio
        float zoomRatio = 1.0f / sqrtf(zoom);
        
        //no longer idle in this case
        if (fabs(deltaX) > 0.01f || fabs(deltaY) > 0.01f)
            idleTicker = 0;
            
        //update camrea
        cameraLongitude += deltaX * XSensitivity * zoomRatio;
        cameraLatitude -= deltaY * YSensitivity * zoomRatio;
        
        //make sure they are in bounds
        cameraLongitude = constrainLong(cameraLongitude);
        cameraLatitude = constrainLat(cameraLatitude);
        
    }
        
    //construct rotation matrix
    V3 unit = sphericalToUnit(cameraLongitude, cameraLatitude);
    cameraMat = fpsRotMat(&unit);
    
    //follow path
    pos = path.getPathPos();

    return;
    
}
       

float Camera::constrainLong(float longitude){
    
    if (longitude < -pi)
        longitude += twoPi; 
    if (longitude > pi)
        longitude -= twoPi; 
    
    return longitude;
}

float Camera::constrainLat(float latitude){
    float amt = halfPi * 0.975f;
    if (latitude <= -amt)
        latitude = -amt; 
    if (latitude >= amt)
        latitude = amt; 
    
    return latitude;
}

void Camera::reset(){
    
    //set pos to origin
    pos = lastPos = V3();
    
    //zoom
    zoom = 1.0f;
    
    //inactivity
    idleTicker = 0;
    
    //rotational
    cameraLatitude = 0.0f;
    cameraLongitude = 0.0f;
    V3 unit = sphericalToUnit(cameraLongitude, cameraLatitude);
    cameraMat = fpsRotMat(&unit);
    
    //bezier path
    V3 origin = V3();
    path = BezierPath();
   
}
    