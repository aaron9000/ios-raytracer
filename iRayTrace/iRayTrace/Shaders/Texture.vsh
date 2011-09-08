attribute mediump vec4 vertex;
attribute mediump vec4 uvCoord;

varying mediump vec2 textureCoordinate;
void main() {
    gl_Position = vertex;
    
    textureCoordinate = uvCoord.xy;
}