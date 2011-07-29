/////////
//INPUT//
/////////
varying highp vec3 screenPos;
uniform mediump vec3 negLightDir;
uniform highp vec3 cameraPos;
uniform highp mat3 matrix;

////////////
//#DEFINES//
////////////
//consts
#define HUGE 9999999.0
#define TINY 0.005
#define CUTOFF 0.01

///////////
//STRUCTS//
///////////
struct Ray {
	highp vec3 origin;
	highp vec3 dir;
	mediump float power;
};
struct Collision {
	highp float dist;
	highp vec3 intersectPos;
	highp vec3 normal;
	mediump vec4 material;
};

////////////////////
//CREATE FUNCTIONS//
////////////////////
Collision createCollision() {
	Collision ret;
	ret.intersectPos = vec3(0.0); 
	ret.normal = vec3(0.0);	
	ret.material = vec4(0.0);
	ret.dist = HUGE;
	return ret;
}

////////////////////////
//INTERSECTION HELPERS//
////////////////////////
void raySphereIntersect(Ray r, mediump vec4 sphereMat, highp vec4 sphereDef, inout Collision c){

    //math
	highp float dotProd = dot(r.dir, (r.origin - sphereDef.xyz));
	highp float distFromRay = distance(r.origin, sphereDef.xyz);
	highp float k = (distFromRay * distFromRay) - (sphereDef.w * sphereDef.w);
	highp float det = dotProd * dotProd - k;

	//facing the right way
	if (det <= 0.0)
		return;

	//ok to sqrt now
	det = sqrt(det);

	//calculate things
	highp float i1 = (- dotProd - det);
	highp float i2 = ((-dotProd) + det);

	//use i2 in this case
	if (i1 <= 0.0)
		i1 = HUGE;
	
	//find distance
	highp float dist = min(i2, i1);

	//early distance return
	if (dist <= 0.0 || c.dist < dist)
		return;

	//////////////////////////////////
	//-we actually have a collision-//
	//////////////////////////////////

	//adjust collision
	c.dist = dist;
    c.intersectPos = r.dir * dist + r.origin;;
	c.normal = normalize(c.intersectPos - sphereDef.xyz);;
	c.material = sphereMat;
}



Collision intersectionCheck(Ray r){

		Collision c = createCollision();

        
		//each sphere we are going to check against
        raySphereIntersect(r, vec4(0.3, 1.0, 0.0, 0.5), vec4(-7.0, 3.0, -0.0, 2.5), c);	
		raySphereIntersect(r, vec4(1.0, 0.0, 0.2, 0.3), vec4(5.0, 1.0, 5.0, 2.0), c);
		raySphereIntersect(r, vec4(0.0, 1.0, 1.0, 0.2), vec4(-9.0, -6.0, -4.0, 2.5), c);	
		raySphereIntersect(r, vec4(0.5, 0.0, 1.0, 0.9), vec4(1.40, 8.0, 7.0, 3.0), c);
		raySphereIntersect(r, vec4(0.2, 0.4, 1.0, 0.8), vec4(-3.0, -3.0, 1.0, 2.75), c);
		raySphereIntersect(r, vec4(0.5, 0.2, 0.9, 0.7), vec4(9.0, -6.0, 8.0, 4.75), c);
        raySphereIntersect(r, vec4(1.0, 0.8, 0.3, 0.5), vec4(-10.0, 5.0, -7.0, 3.75), c);
        raySphereIntersect(r, vec4(1.0, 1.0, 1.0, 0.8), vec4(0.0, 0.0, 0.0, 1), c);
    
        //enclosing sphere
        raySphereIntersect(r, vec4(1.0, 1.0, 1.0, 0.0), vec4(-120.0, -40.0, 32.0, 256), c);


	return c;
}

///////////////////////
//RAY CASTING HELPERS//
///////////////////////
void shootRay(mediump vec3 eyeDir, inout Ray r, inout mediump vec3 color) {
	
	//early return
	if (r.power < CUTOFF)
		return;

	//collision check
	Collision c = intersectionCheck(r);
    
	if (c.dist < HUGE){
        
		//on hit reflect the specular part and sum the diffuse part
		mediump vec3 temp = normalize(negLightDir + eyeDir);
		mediump float diffuseFactor = clamp(dot(c.normal, temp), 0.0, 1.0);
		diffuseFactor = clamp(diffuseFactor * diffuseFactor, 0.0, 1.0);
		color += c.material.xyz * diffuseFactor * (1.0 - c.material.w) ;
		
        //update ray
        r.dir = reflect(r.dir, c.normal);
        r.origin.xyz = (r.dir * TINY) + c.intersectPos;
        r.power *= c.material.w;

        
	} else {
		//on miss absorb all power
		r.power = 0.0;
	}
     
}
 


////////////////
//PIXEL SHADER//
////////////////
void main (void)
{  
	
	//start with no color contributions
	mediump vec3 color = mediump vec3(0.0);

	//get ray from screen position
    Ray r = Ray(cameraPos, normalize(screenPos) * matrix, 1.0);
    
    //calculate the eye dir
	mediump vec3 negEyeDir = -r.dir;

	//3 iterations
	shootRay(negEyeDir, r, color);
	shootRay(negEyeDir, r, color);
    shootRay(negEyeDir, r, color);
 
    //output
    gl_FragColor = mediump vec4(color, 1.0);
    
}