attribute highp vec4 vertex;
attribute highp vec4 uvCoord;

varying highp vec2 textureCoordinate;
void main() {
    gl_Position = vertex;
    
    textureCoordinate = uvCoord.xy;
}