/* HOW TO CALCULATE SHIT SCREEN DIST */
//for 90 degree vertical FOV
//const float vFOV = (3.14/2.0) * 1.0;  
//const float hFOV = (3.14/2.0) * 0.75; //adjusted for aspect iPad ratio
//const float screenDistance = cos(vFOV * 0.5)/sin(vFOV * 0.5);
/* HOW TO CALCULATE SHIT SCREEN DIST */
attribute vec4 vertex;
varying vec3 screenPos;
uniform float zoom;
uniform vec3 cameraPos;
uniform mat4 matrix;
void main(void) {
	
	//get the coordinate on the virtual screen in world space
    screenPos.zyx = vertex.yxz;
    screenPos.x *= zoom;
    screenPos.y *= 0.75;
    
	//final output
	gl_Position = vertex;
}