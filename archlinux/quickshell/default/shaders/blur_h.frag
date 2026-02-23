#version 440

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float blurStrength;
    vec2 texelSize;
};

layout(binding = 1) uniform sampler2D source;

void main() {
    float s = max(0.01, blurStrength);
    vec2 stepUv = vec2(texelSize.x * s, 0.0);

    vec4 color = texture(source, qt_TexCoord0) * 0.227027;
    color += texture(source, qt_TexCoord0 + (stepUv * 1.384615)) * 0.316216;
    color += texture(source, qt_TexCoord0 - (stepUv * 1.384615)) * 0.316216;
    color += texture(source, qt_TexCoord0 + (stepUv * 3.230769)) * 0.070270;
    color += texture(source, qt_TexCoord0 - (stepUv * 3.230769)) * 0.070270;

    fragColor = color * qt_Opacity;
}
