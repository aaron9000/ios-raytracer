//
//  BezierPath.h
//  iRayTrace
//
//  Created by Aaron on 8/18/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//
#import "MathHelper.h"
#import "mat4.h"

#define MaxPathLength 128

class BezierPath{
public:
    
    //positional
    V3 pos,lastPos;
    
    //bezier
    float pathSpeed;
    float currT;
    unsigned int currNode;
    
    //path
    bool hasPath;
    int pathLength;
    V3 path[MaxPathLength];
	
    
    //default constructor
    BezierPath();
    
    //methods
    void followPath(V3* center, int nodes, float spacing, float speed);
    V3 getBezierPos();
    void control(float deltaX, float deltaY, bool panToOrigin, float targetZoom);    
    void reset();
    
private:
};
