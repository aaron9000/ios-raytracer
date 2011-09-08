varying mediump vec2 textureCoordinate;
uniform sampler2D textureSample;
void main() {
    
    gl_FragColor = texture2D(textureSample, textureCoordinate);

}



