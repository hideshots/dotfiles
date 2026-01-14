#version 440

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float strength;
    float zoom;
} ubuf;

layout(binding = 1) uniform sampler2D source;

void main() {
    vec2 uv = qt_TexCoord0;

    uv = (uv - vec2(0.5)) / ubuf.zoom + vec2(0.5);

    vec2 cc = uv - vec2(0.5);
    float r2 = dot(cc, cc);
    vec2 warped = uv + cc * r2 * ubuf.strength;

    warped = clamp(warped, vec2(0.0), vec2(1.0));
    fragColor = texture(source, warped) * ubuf.qt_Opacity;
}
