#ifndef BEZIERPATH
#define BEZIERPATH

#import "MathHelper.h"
#import "mat4.h"

//consts
#define MaxPathLength 128
#define LengthEstimationSteps 30
#define PathSmoothIterations 4
#define NodePlacementVariation 0.65f

class BezierPath{
public:
    
    //default constructor
    BezierPath();
    
    //public methods
    void createPath(V3* center, int nodes, float spacing, float speed, float rotation);
    V3 getPathPos();
    
private:
    
    //vars
    float pathSpeed;
    float nodeSpacing;
    float t;
    unsigned int node;
    bool hasPath;
    int pathLength;
    V3 path[MaxPathLength];
	
	//helper methods
	void reset();
    V3 getBezierPos(float dt, bool copy);
    V3 blend(V3* x0, V3* x1, V3* x2, V3* x3, float t);
    unsigned int getNextNode(unsigned int node);
    
};

#endif
