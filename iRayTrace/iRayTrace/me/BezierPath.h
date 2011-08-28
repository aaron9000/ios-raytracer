//
//  BezierPath.h
//  iRayTrace
//
//  Created by Aaron on 8/18/11.
//  Copyright 2011 __MyCompanyName__. All rights reserved.
//
#import "MathHelper.h"
#import "mat4.h"


//consts
#define MaxPathLength 128
#define LengthEstimationSteps 50
#define PathScaleZ 0.5f
#define PathSmoothIterations 5

class BezierPath{
public:
    
    
    //bezier
    float pathSpeed;
    float nodeSpacing;
    float t;
    unsigned int node;
    
    //path
    bool hasPath;
    int pathLength;
    V3 path[MaxPathLength];
	
    
    //default constructor
    BezierPath();
    
    //methods
    void createPath(V3* center, int nodes, float spacing, float speed);
    V3 getBezierPos(float dt, bool copy);
    V3 getPathPos();
    void control(float deltaX, float deltaY, bool panToOrigin, float targetZoom);    
    void reset();
    
    //helpers
    unsigned int getNextNode(unsigned int node);
    
private:
};
