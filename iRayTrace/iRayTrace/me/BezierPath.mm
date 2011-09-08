//
//  BezierPath.cpp
//  iRayTrace
//
//  Created by Aaron on 8/18/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//

#include "BezierPath.h"

BezierPath::BezierPath(){
    reset();
}
void BezierPath::createPath(V3* center, int nodes, float spacing, float speed, float rotation){
    
    
    //invaid paths
    if (nodes < 4 || nodes > MaxPathLength || speed <= 0.0f || spacing <= speed){
        NSLog(@"Camera: bad path args \n");
        return;
    }
    
    //reset everything
    reset();
    
    //set vars
    nodeSpacing = spacing;
    pathSpeed = speed;
    node = 0;
    t = 0.0f;
    hasPath = true;
    
    //make path
    int k;
    float radius = 0.0f;
    float rot = 0.0f;
    V2 c = V2(center->x, center->y);
    V2 p = V2();
    V3 prev = *center;
    V3 randDir = V3();
    for (k = 0; k < nodes; k++){
        
        //randomly place new node in radius around previous
        randDir = randUnit3();
        randDir.z *= PathScaleZ;
        randDir = unit3(&randDir);
        randDir = mult3(&randDir, spacing);
        prev = add3(&prev, &randDir);
        
        //2D rotate a bit
        p.x = prev.x;
        p.y = prev.y;
        radius = dist2(&c, &p);
        rot = dir2(&c, &p);
        rot += rotation;
        prev.x = c.x + radius * cosf(rot);
        prev.y = c.y + radius * sinf(rot);
        
        //add to path
        path[pathLength] = prev;
        pathLength++;
        
    }
    
    //verlet the points a bit
    float dist = 0.0f;
    float offsetMag = 0.0f;
    int j = 0;
    int z = 0;
    V3 n0 = V3();
    V3 n1 = V3();
    V3 delta = V3();
    for (z = 0; z < PathSmoothIterations; z++){
        for (k = 0; k < pathLength; k++){
            n0 = path[k];
            for (j = k + 1; j < pathLength; j++){
                n1 = path[j];
                dist = dist3(&n0, &n1);
                offsetMag = nodeSpacing - dist;
                if (offsetMag > 0.0f){
                    //do verlet
                    delta = sub3(&n0, &n1);
                    delta = unit3(&delta);
                    delta = mult3(&delta, offsetMag * 0.5f);
                    path[k] = add3(&path[k], &delta);
                    path[j] = sub3(&path[j], &delta);
                    
                }
            }
        }
    }
 
    for (k = 0; k < pathLength; k++){
            NSLog(@"PATH NODE %f   %f   %f", path[k].x, path[k].y, path[k].z);
        
    }
}
V3 BezierPath::getPathPos(){
    
    
    //estimate
    float idealDt = (pathSpeed / (nodeSpacing * 4.0f));
    float idealStepDistance = (pathSpeed / LengthEstimationSteps);
    
    //test estimated dt
    V3 oldPos = getBezierPos(0.0f, false);
    V3 testPos = getBezierPos(idealDt, false);
    float testDist = dist3(&testPos, &oldPos);
    
    //refine dt estimate
    idealDt /= testDist / idealStepDistance;
    
    //iteratively find the distance
    float dtAccum = 0.0f;
    float distAccum = 0.0f;
    
    //default return val
    testPos = oldPos;
    
    int i = 0;
    int steps = LengthEstimationSteps * 3;
    for (i = 0; i < steps; i++){
        //get points
        if (i != 0) {
            oldPos = testPos;
            testPos = getBezierPos(dtAccum, false);
            testDist = dist3(&testPos, &oldPos);
        } else {
            testDist = 0.0f;
        }
        
        //increment and test
        distAccum += testDist;
        
        //weve reached our goal
        if (distAccum > pathSpeed){
            getBezierPos(dtAccum, true);
            return testPos;
        }else{
            dtAccum += idealDt;
        }
        
    }
    return testPos;
    
}
V3 BezierPath::getBezierPos(float dt, bool copy){
    
    
    V3 bezierPos=V3();
    
    //one for each node
    unsigned int nodeIndex[4];
    V3 nodePos[4];
    
    //local
    float currT = t;
    float currNode = node;
    
    //loop stuff
    int i;
    
    //if we have a path
    if (hasPath && pathSpeed > 0.0f && dt < 1.0f){
        
        //increment t and node
        currT += dt;
        if (currT >= 1.0f){
            currT -= 1.0f;
            currNode = getNextNode(currNode);
        }
        
        //get nodes we are working with
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
        
        //get position
        bezierPos = blend(&nodePos[0], &nodePos[1], &nodePos[2], &nodePos[3], currT);
        
        if (copy){
            NSLog(@"%f   %i", t, node);
            t = currT;
            node = currNode;
        }
        
    }
    
    return(bezierPos);
}

V3 BezierPath::blend(V3* x0, V3* x1, V3* x2, V3* x3, float t){
    V3 ret = V3();
    
    float u = 1.0f - t;
    float t2 = t * t;
    float u2 = u * u;
    float u3 = u2 * u;
    float t3 = t2 * t;
    
    float b0 = u3 / 6.0f;
    float b1 = (3.0f * t3 - 6.0f * t2 + 4.0f) / 6.0f;
    float b2 = (-3.0f * t3 + 3.0f * t2 + 3.0f * t + 1.0f) / 6.0f;
    float b3 = t3 / 6.0f;
    
    V3 p0 = mult3(x0, b0);
    V3 p1 = mult3(x1, b1); 
    V3 p2 = mult3(x2, b2); 
    V3 p3 = mult3(x3, b3);
    
    ret = add3(&p0, &p1);
    ret = add3(&ret, &p2);
    ret = add3(&ret, &p3);
    
    return ret;
}

void BezierPath::reset(){
    
    //bezier
    pathSpeed = 0.0f;
    t = 0.0f;
    node = 0;
    
    //path
    hasPath = false;
    pathLength = 0;
    
    int i;
    for (i = 0; i < MaxPathLength; i++)
        path[i] = V3();
    
	
}

unsigned int BezierPath::getNextNode(unsigned int node){
    node++;
    if (node >= pathLength)
        node -=pathLength;
    
    return node;
}
