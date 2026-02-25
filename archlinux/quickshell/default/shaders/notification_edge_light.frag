#version 440

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float uRadius;
    float uLightAngleDeg;
    float uLightStrength;
    float uLightWidthPx;
    float uLightSharpness;
    float uCornerBoost;
    float uEdgeOpacity;
    vec2 uSize;
    vec4 uEdgeTint;
};

float roundedRectSdf(vec2 p, vec2 size, float r) {
    vec2 halfSize = size * 0.5;
    vec2 q = abs(p - halfSize) - (halfSize - vec2(r));
    return length(max(q, vec2(0.0))) + min(max(q.x, q.y), 0.0) - r;
}

void main() {
    vec2 uv = qt_TexCoord0;
    vec2 pixel = uv * uSize;

    float sdf = roundedRectSdf(pixel, uSize, uRadius);
    float edgeDist = -sdf;
    float shapeMask = smoothstep(0.0, 1.0, edgeDist);

    if (shapeMask <= 0.0001) {
        fragColor = vec4(0.0);
        return;
    }

    vec2 px = vec2(1.0, 0.0);
    vec2 py = vec2(0.0, 1.0);
    float sdfX1 = roundedRectSdf(pixel + px, uSize, uRadius);
    float sdfX0 = roundedRectSdf(pixel - px, uSize, uRadius);
    float sdfY1 = roundedRectSdf(pixel + py, uSize, uRadius);
    float sdfY0 = roundedRectSdf(pixel - py, uSize, uRadius);
    float sdfXYpp = roundedRectSdf(pixel + px + py, uSize, uRadius);
    float sdfXYpn = roundedRectSdf(pixel + px - py, uSize, uRadius);
    float sdfXYnp = roundedRectSdf(pixel - px + py, uSize, uRadius);
    float sdfXYnn = roundedRectSdf(pixel - px - py, uSize, uRadius);

    vec2 grad = vec2(sdfX1 - sdfX0, sdfY1 - sdfY0);
    float gradLen = max(length(grad), 1e-4);
    vec2 normal2d = grad / gradLen;

    float dxx = sdfX1 - (2.0 * sdf) + sdfX0;
    float dyy = sdfY1 - (2.0 * sdf) + sdfY0;
    float dxy = 0.25 * (sdfXYpp - sdfXYpn - sdfXYnp + sdfXYnn);

    float cornerCurvature = abs(dxx) + abs(dyy) + (2.0 * abs(dxy));
    float cornerCurvMask = smoothstep(0.035, 0.33, cornerCurvature);
    float sideDistX = min(pixel.x, uSize.x - pixel.x);
    float sideDistY = min(pixel.y, uSize.y - pixel.y);
    float cornerReach = max(2.0, uRadius * 1.5);
    float cornerNearX = 1.0 - smoothstep(0.0, cornerReach, sideDistX);
    float cornerNearY = 1.0 - smoothstep(0.0, cornerReach, sideDistY);
    float cornerGeomMask = cornerNearX * cornerNearY;
    float cornerness = clamp(max(cornerCurvMask, cornerGeomMask), 0.0, 1.0);

    float lightWidthPx = max(1.0, uLightWidthPx);
    float coreWidthPx = max(1.0, lightWidthPx * 0.18);

    float edgeWide = 1.0 - smoothstep(0.0, lightWidthPx, edgeDist);
    float edgeCore = 1.0 - smoothstep(0.0, coreWidthPx, edgeDist);
    edgeWide *= edgeWide * (3.0 - 2.0 * edgeWide);

    vec3 pseudoNormal = normalize(vec3(-(normal2d * edgeWide), 1.0));
    float fresnel = pow(1.0 - clamp(pseudoNormal.z, 0.0, 1.0), 2.2);

    // Light direction (0 degrees = top, 90 degrees = right, clockwise)
    float a = radians(uLightAngleDeg);
    vec2 lightFrom2d = normalize(vec2(sin(a), -cos(a)));

    float edgeFacing = max(dot(normal2d, lightFrom2d), 0.0);
    float sharp = clamp(uLightSharpness, 0.0, 1.0);

    float edgeLobeWide = pow(edgeFacing, mix(2.0, 6.0, sharp));
    float edgeLobeCore = pow(edgeFacing, mix(8.0, 18.0, sharp));

    vec3 viewDir = vec3(0.0, 0.0, 1.0);
    vec3 lightDir = normalize(vec3(lightFrom2d * 0.82, 0.60));
    vec3 halfVec = normalize(lightDir + viewDir);
    float ndh = max(dot(pseudoNormal, halfVec), 0.0);

    float specWide = pow(ndh, mix(8.0, 24.0, sharp));
    float specCore = pow(ndh, mix(24.0, 72.0, sharp));

    float cornerGain = 1.0 + (clamp(uCornerBoost, 0.0, 1.0) * cornerness);

    float rimHighlight = (0.030 + 0.050 * uLightStrength)
        * edgeWide
        * (0.35 + 0.65 * fresnel)
        * cornerGain;

    float directionalBroad = uLightStrength
        * edgeWide
        * (0.55 * edgeLobeWide + 0.45 * specWide)
        * (0.35 + 0.65 * fresnel)
        * cornerGain;

    float directionalCore = uLightStrength
        * edgeCore
        * (0.50 * edgeLobeCore + 0.50 * specCore)
        * (0.45 + 0.55 * fresnel)
        * cornerGain;

    float oppositeFacing = max(dot(normal2d, -lightFrom2d), 0.0);
    float directionalShadow = 0.020
        * edgeWide
        * pow(oppositeFacing, 1.35)
        * (0.35 + 0.65 * uLightStrength);

    float lightBand = clamp(max(edgeWide, edgeCore), 0.0, 1.0);
    float edgeIntensity = max(0.0, rimHighlight + directionalBroad + directionalCore - directionalShadow);

    float alpha = clamp(edgeIntensity * lightBand * uEdgeOpacity, 0.0, 1.0);
    alpha *= shapeMask * qt_Opacity * clamp(uEdgeTint.a, 0.0, 1.0);

    fragColor = vec4(uEdgeTint.rgb * alpha, alpha);
}
