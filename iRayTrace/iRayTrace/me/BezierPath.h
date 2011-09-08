#ifndef BEZIERPATH
#define BEZIERPATH

#import "MathHelper.h"
#import "mat4.h"

//consts
#define MaxPathLength 128
#define LengthEstimationSteps 30
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
    void createPath(V3* center, int nodes, float spacing, float speed, float rotation);
    V3 getBezierPos(float dt, bool copy);
    V3 getPathPos();
    V3 blend(V3* x0, V3* x1, V3* x2, V3* x3, float t);
    void control(float deltaX, float deltaY, bool panToOrigin, float targetZoom);    
    void reset();
    
    //helpers
    unsigned int getNextNode(unsigned int node);
    
private:
};

#endif
