#include "Camera.h"


Camera::Camera(){
    reset();
}
    
Camera::Camera(V3 position,float inLongitude){
        
    reset();

    //pass in args
    pos = lastPos = position;
    
    //point in default direction
    cameraLongitude = inLongitude;
}
    

void Camera::followPath(V3* center, int nodes, float spacing, float speed){
		
    //if ok then start pathing!
    if (nodes > 4 && nodes < 128 && speed > 0.0f && spacing > speed){

        //reset apth
        pathLength = 0;
        
        //make path
        int k;
        V3 prev = *center;
        V3 randDir = V3();
        for (k = 0; k < nodes; k++){
            
            //find position of new node
            randDir = randUnit3(0.5f);
            randDir = mult3(&randDir, spacing);
            prev = add3(&prev, &randDir);
            
            ////add to path
            path[pathLength] = prev;
            pathLength++;
            
        }
        
        //path position
        pathSpeed = speed;
        currNode = 0;
        currT = 0.0f;
        hasPath = true;
        
    }else{
        NSLog(@"Camera: bad path args \n");
    }
}
    
V3 Camera::getBezierPos(){
    //////////////////////
    //temp vars
    //////////////////////
    V3 bezierPos=V3();
    
    //one for each node
    unsigned int nodeIndex[4];
    V3 nodePos[4];
    V3 nodeDir[4];
    float nodeDist[4];
    V3 prevPos;
    
    //speed stuff
    float dt;
    float dtRemainder;
    float speedRemainder;
    
    //ratios
    float f0, f1, f2, f3;
    Vec4 px, py, pz;
    
    //loop stuff
    bool done = false;
    int i;
    //////////////////////
    
    //if we have a path
    if (hasPath && pathSpeed > 0){
        while (!done){
            
            //////////////////////
            //get node info
            for (i = 0; i < 4; i++){
                //indices
                if (i == 0){
                    nodeIndex[i] = currNode;
                }else{
                    nodeIndex[i] = nodeIndex[i - 1] + 1;
                }
                if (nodeIndex[i] >= pathLength)
                    nodeIndex[i] = 0;
                //pos
                nodePos[i] = path[nodeIndex[i]];
            }
            for (i=0; i<4; i++){
                //dir and direction
                if (i == 3){
                    nodeDir[i] = sub3(&nodePos[0], &nodePos[i]);
                }else{
                    nodeDir[i] = sub3(&nodePos[i + 1], &nodePos[i]);
                }
                //distance
                nodeDist[i] = mag3(&nodeDir[i]);
                
                //normalize it
                V3 n = unit3(&nodeDir[i]);
                nodeDir[i] = mult3(&n, nodeDist[i] * 0.5f);
            }
            
            
            //get previous
            int prevIndex = currNode - 1;
            if (prevIndex < 0)
                prevIndex = pathLength - 1;
            prevPos = path[prevIndex];
            
            //speed stuff
            dt = pathSpeed / nodeDist[0];
            
            //attempt to move
            if ((currT + dt) > 1.0f){
                dtRemainder = (currT + dt) - 1.0f;
                speedRemainder = nodeDist[0] * (dtRemainder);
                dt = speedRemainder / nodeDist[1];
                currT = 0.0f;
                currNode++;
                if (currNode >= pathLength)
                    currNode = 0;
                
            }else{
                currT += dt;
                done = true;
            }
        }
        
        //hermite matrix
        float t = currT;
        float t2 = t * t;
        float t3 = t2 * t;
        
        //UNIFORM CUBIC B SPLINE////////////////////
        f0 = -t3 + 3.0f * t2 -3.0f * t + 1.0f;
        f1 = 3.0f * t3 -6.0f * t2 + 4.0f;
        f2 = -3.0f * t3 + 3.0f * t2 + 3.0f * t + 1.0f;
        f3 = t3                 ;
        
        //times 1/6
        float sixth = (float) 1 / 6;
        f0 = f0 * sixth;
        f1 = f1 * sixth;
        f2 = f2 * sixth;
        f3 = f3 * sixth;
        
        px = Vec4(prevPos.x, nodePos[0].x, nodePos[1].x, nodePos[2].x);
        py = Vec4(prevPos.y, nodePos[0].y, nodePos[1].y, nodePos[2].y);
        pz = Vec4(prevPos.z, nodePos[0].z, nodePos[1].z, nodePos[2].z);
        //UNIFORM CUBIC B SPLINE////////////////////
        
        //get position
        bezierPos.x = f0 * px[0] + f1 * px[1] + f2 * px[2] + f3 * px[3];
        bezierPos.y = f0 * py[0] + f1 * py[1] + f2 * py[2] + f3 * py[3];
        bezierPos.z = f0 * pz[0] + f1 * pz[1] + f2 * pz[2] + f3 * pz[3];
        
        
    }
    
    return(bezierPos);
}
                    
void Camera::control(float deltaX, float deltaY, bool panToOrigin){

   
    if (panToOrigin){
        
        //start rseetting to look at the origin
        float panSpeed = 0.1f;
        float zoomSpeed = 0.1f;
        float idleZoom = 0.9f;
        
        V2 origin = V2();

        //we are idle
        idleTicker++;
        if (idleTicker > 100)
            idleTicker = 100;
        
        
        //adjust pan speed by idle ratio
        float idleRatio = idleTicker / 100.0f;
        idleRatio *= idleRatio;
        panSpeed *= idleRatio;
        
        
        //zoom
        zoomSpeed *= idleRatio;
        if (fabsf(idleZoom - zoom) < zoomSpeed){
            zoom = idleZoom;
        }else{
            if (zoom > idleZoom){
                zoom -= zoomSpeed;
            }else{
                zoom += zoomSpeed;
            }
        }
        
        //longitude
        V2 pos2 = V2(pos.x, pos.y);
        float idealLongitude = constrainLong(dir2(&pos2, &origin));
        float deltaLong = findDir(cameraLongitude, idealLongitude);
        if (fabs(deltaLong) <= panSpeed){
            cameraLongitude = idealLongitude;
            
        }else{
            if (deltaLong > 0.0f){
                cameraLongitude -= panSpeed;
            }else{
                cameraLongitude += panSpeed;
            }
        }
        cameraLongitude = constrainLong(cameraLongitude);
        
    }else{
        
        if (fabs(deltaX) > 0.01f || fabs(deltaY) > 0.01f)
            idleTicker = 0;
            
        //update camrea
        cameraLongitude += deltaX;
        cameraLatitude -= deltaY;
        
        //make sure they are in bounds
        cameraLongitude = constrainLong(cameraLongitude);
        cameraLatitude = constrainLat(cameraLatitude);
        
    }
    

    
    //construct rotation matrix
    V3 unit = sphericalToUnit(cameraLongitude, cameraLatitude);
    cameraMat = fpsRotMat(&unit);
}
       

float Camera::constrainLong(float longitude){
    
    if (longitude < -pi)
        longitude += twoPi; 
    if (longitude > pi)
        longitude -= twoPi; 
    
    return longitude;
}

float Camera::constrainLat(float latitude){
    float amt = halfPi*0.95f;
    if (latitude <= -amt)
        latitude = -amt; 
    if (latitude >= amt)
        latitude = amt; 
    
    return latitude;
}

void Camera::reset(){
    //set pos to origin
    pos = lastPos = V3(0.0f, 0.0f, 0.0f);
    
    //zoom
    zoom = 1.0f;
    
    
    //inactivity
    idleTicker = 0.0f;
    
    //bezier
    hasPath = false;
    pathSpeed = 0.0f;
    currT = 0.0f;
    currNode = 0;
    
    //point in default direction
    cameraLatitude = 0.0f;
    cameraLongitude = 0.0f;
    
    V3 unit = sphericalToUnit(cameraLongitude, cameraLatitude);
    cameraMat = fpsRotMat(&unit);
    //update camera Matrix
}
    