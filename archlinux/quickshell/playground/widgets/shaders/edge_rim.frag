#version 440

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec2 uSize;
    float uRadius;
    float uRimWidthPx;
    float uGlowWidthPx;
    float uHighlightOpacity;
    float uShadeOpacity;
    float uCornerBoost;
    float uDpr;
};

highp float sdRoundRect(highp vec2 p, highp vec2 halfSize, highp float r) {
    highp vec2 q = abs(p) - (halfSize - vec2(r));
    return length(max(q, vec2(0.0))) + min(max(q.x, q.y), 0.0) - r;
}

highp float sdAt(highp vec2 p, highp vec2 halfSize, highp float r) {
    return sdRoundRect(p, halfSize, r);
}

void main() {
    highp vec2 sizePx = max(uSize * uDpr, vec2(1.0));
    highp vec2 p = (qt_TexCoord0 * sizePx) - (sizePx * 0.5);
    highp vec2 halfSize = sizePx * 0.5;
    highp float r = min(uRadius * uDpr, min(halfSize.x, halfSize.y));

    highp float sd = sdAt(p, halfSize, r);

    highp float rimW = max(0.001, uRimWidthPx * uDpr);
    highp float glowW = max(rimW, uGlowWidthPx * uDpr);

    highp float rimMask = smoothstep(rimW, 0.0, abs(sd)) * smoothstep(0.0, -rimW, sd);
    highp float glowMask = smoothstep(glowW, 0.0, sd) * (1.0 - smoothstep(0.0, 1.0, -sd));

    highp float eps = max(0.5, 0.5 * uDpr);
    highp float sdx1 = sdAt(p + vec2(eps, 0.0), halfSize, r);
    highp float sdx2 = sdAt(p - vec2(eps, 0.0), halfSize, r);
    highp float sdy1 = sdAt(p + vec2(0.0, eps), halfSize, r);
    highp float sdy2 = sdAt(p - vec2(0.0, eps), halfSize, r);
    highp vec2 n = normalize(vec2(sdx1 - sdx2, sdy1 - sdy2) + vec2(1e-6));

    highp vec2 lightDir = normalize(vec2(-0.8, -1.0));
    highp float facing = clamp(dot(n, lightDir) * 0.5 + 0.5, 0.0, 1.0);

    highp float corner = pow(1.0 - abs(dot(n, vec2(1.0, 0.0))), 2.0)
                      * pow(1.0 - abs(dot(n, vec2(0.0, 1.0))), 2.0);

    highp float highlight = rimMask * facing * uHighlightOpacity;
    highp float shade = rimMask * (1.0 - facing) * uShadeOpacity;
    highlight += rimMask * corner * uCornerBoost * uHighlightOpacity;
    highlight += glowMask * 0.25 * uHighlightOpacity;

    highp float outA = clamp(highlight + shade, 0.0, 1.0);
    highp vec3 outRgb = vec3(highlight);

    fragColor = vec4(outRgb, outA) * qt_Opacity;
}
