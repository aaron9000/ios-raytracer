
attribute vec4 vertex;
varying vec3 screenPos;
uniform float zoom;
uniform vec3 cameraPos;
uniform mat4 matrix;
void main(void) {
	
	//get the coordinate on the virtual screen in world space
    screenPos.zyx = vertex.yxz;
    screenPos.x *= zoom;
    screenPos.y *= 0.75; // for 4 : 3 aspect ratio
    
	//final output
	gl_Position = vertex;
}