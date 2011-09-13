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
    float sceneRotationVelocity = (fRand() * 0.32f + 0.32f) * randSign();
    path.createPath(position, 24, 3.2f, 0.08f, sceneRotationVelocity);
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
        float idleRatio = (float)idleTicker / (float)IdleTicks;
        idleRatio *= idleRatio;
        
        //longitude adjustments
        V2 pos2 = V2(pos.x, pos.y);
        float idealLongitude = constrainLong(dir2(&pos2, &origin));
        float deltaLong = findDir(cameraLongitude, idealLongitude);
		float adjustedPanSpeed = PanSpeed * fabsf(deltaLong / pi);
        if (fabs(deltaLong) <= adjustedPanSpeed){
            cameraLongitude = idealLongitude;
        }else{
            if (deltaLong > 0.0f){
                cameraLongitude -= adjustedPanSpeed * idleRatio;
            }else{
                cameraLongitude += adjustedPanSpeed * idleRatio;
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
}

float Camera::getZoom(){
	return zoom;
}

V3 Camera::getPos(){
	return pos;
}
Mat4 Camera::getRotationMat(){
    return cameraMat;

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
