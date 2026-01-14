#version 440

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float edgePx;
    float intensity;
    vec2 invSize;
    vec2 lightDir;
} ubuf;

layout(binding = 1) uniform sampler2D maskSource;

float a(vec2 uv) { return texture(maskSource, uv).a; }

void main() {
    vec2 uv = qt_TexCoord0;

    vec2 d = ubuf.invSize * ubuf.edgePx;

    float c  = a(uv);
    float l  = a(uv + vec2(-d.x,  0.0));
    float r  = a(uv + vec2( d.x,  0.0));
    float t  = a(uv + vec2( 0.0, -d.y));
    float b  = a(uv + vec2( 0.0,  d.y));

    vec2 grad = vec2(r - l, b - t);
    float g = length(grad);

    float inside = smoothstep(0.02, 0.15, c);
    float edge = smoothstep(0.05, 0.35, g) * inside;

    vec2 n = normalize(grad + vec2(1e-6));
    vec2 L = normalize(ubuf.lightDir);

    float ndotl = clamp(dot(n, -L), 0.0, 1.0);

    float spec = pow(ndotl, 10.0);
    float alpha = edge * spec * ubuf.intensity;

    vec3 col = vec3(0.95, 0.98, 1.00);
    fragColor = vec4(col * alpha, alpha) * ubuf.qt_Opacity;
}
