#version 440

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float uRadius;
    float uRefraction;
    float uDepth;
    float uDispersion;
    float uFrost;
    float uSplay;
    float uGlassOpacity;
    float uTime;
    float uDebug;
    vec2 uSize;
    vec4 uUvRect;
    vec4 uTint;
};

layout(binding = 1) uniform sampler2D sceneTex;

float roundedRectSdf(vec2 p, vec2 size, float r) {
    vec2 halfSize = size * 0.5;
    vec2 q = abs(p - halfSize) - (halfSize - vec2(r));
    return length(max(q, vec2(0.0))) + min(max(q.x, q.y), 0.0) - r;
}

float hash12(vec2 p) {
    vec3 p3 = fract(vec3(p.xyx) * 0.1031);
    p3 += dot(p3, p3.yzx + 33.33);
    return fract((p3.x + p3.y) * p3.z);
}

vec3 sampleScene(vec2 uv) {
    vec2 clamped = clamp(uv, vec2(0.001), vec2(0.999));
    return texture(sceneTex, clamped).rgb;
}

void main() {
    vec2 uv = qt_TexCoord0;
    vec2 pixel = uv * uSize;

    if (uDebug > 0.5) {
        float grid = step(0.95, fract(uv.x * 10.0)) + step(0.95, fract(uv.y * 10.0));
        vec3 dbg = vec3(
            clamp(uRefraction, 0.0, 1.0),
            clamp(uDispersion, 0.0, 1.0),
            clamp(uFrost, 0.0, 1.0)
        );
        dbg = mix(dbg, vec3(1.0, 1.0, 0.0), clamp(grid, 0.0, 1.0) * 0.35);
        dbg += vec3(0.10 * sin(uTime * 4.0 + uv.x * 20.0));
        fragColor = vec4(clamp(dbg, 0.0, 1.0), 1.0);
        return;
    }

    float sdf = roundedRectSdf(pixel, uSize, uRadius);
    float edgeDist = -sdf;

    float mask = smoothstep(0.0, 1.0, edgeDist);
    float edgeMask = 1.0 - smoothstep(0.0, 18.0, edgeDist);
    float edgeInfluence = edgeMask * edgeMask;

    // Avoid dFdx/dFdy seam across the internal quad triangle split by using
    // finite differences in pixel space.
    vec2 px = vec2(1.0, 0.0);
    vec2 py = vec2(0.0, 1.0);
    float sdfX1 = roundedRectSdf(pixel + px, uSize, uRadius);
    float sdfX0 = roundedRectSdf(pixel - px, uSize, uRadius);
    float sdfY1 = roundedRectSdf(pixel + py, uSize, uRadius);
    float sdfY0 = roundedRectSdf(pixel - py, uSize, uRadius);
    vec2 grad = vec2(sdfX1 - sdfX0, sdfY1 - sdfY0);
    float gradLen = max(length(grad), 1e-4);
    vec2 normal2d = grad / gradLen;
    vec2 tangent = vec2(-normal2d.y, normal2d.x);

    float depthGain = 1.0 + (uDepth * 0.95);
    vec2 pixelToUv = vec2(1.0 / max(1.0, uSize.x), 1.0 / max(1.0, uSize.y));

    float refrPx = (0.8 + 4.8 * uRefraction)
        * (0.35 + 0.65 * depthGain)
        * edgeInfluence;
    vec2 refrOffset = normal2d * refrPx * pixelToUv;

    float splayPx = (0.2 + 2.2 * uSplay) * edgeInfluence;
    vec2 splayOffset = tangent * splayPx * pixelToUv;

    vec2 mappedUv = uUvRect.xy + (uv * uUvRect.zw);
    vec2 refractedUv = mappedUv + refrOffset + splayOffset;

    float dispersionUv = (0.0007 + 0.0032 * uDispersion) * edgeInfluence;
    vec2 dispersionVec = normal2d * dispersionUv;

    vec3 baseColor = sampleScene(mappedUv);
    vec3 refractedColor;
    refractedColor.r = sampleScene(refractedUv + dispersionVec).r;
    refractedColor.g = sampleScene(refractedUv).g;
    refractedColor.b = sampleScene(refractedUv - dispersionVec).b;

    float frostFactor = uFrost;
    vec2 frostStep = pixelToUv * (1.8 + 5.5 * frostFactor);

    vec3 extraBlur = vec3(0.0);
    extraBlur += sampleScene(refractedUv + vec2(frostStep.x, 0.0));
    extraBlur += sampleScene(refractedUv - vec2(frostStep.x, 0.0));
    extraBlur += sampleScene(refractedUv + vec2(0.0, frostStep.y));
    extraBlur += sampleScene(refractedUv - vec2(0.0, frostStep.y));
    extraBlur *= 0.25;

    vec3 glassColor = mix(refractedColor, extraBlur, frostFactor * 0.68);

    float luminance = dot(glassColor, vec3(0.2126, 0.7152, 0.0722));
    glassColor = mix(vec3(luminance), glassColor, 1.0 - (0.22 * frostFactor));
    glassColor = mix(vec3(0.5), glassColor, 1.0 - (0.18 * frostFactor));

    float noise = hash12((uv * uSize) + vec2(uTime * 31.0, uTime * 23.0));
    glassColor += (noise - 0.5) * (0.010 + 0.020 * frostFactor);

    vec3 pseudoNormal = normalize(vec3(-(normal2d.x * edgeInfluence) * depthGain, -(normal2d.y * edgeInfluence) * depthGain, 1.0));
    float fresnel = pow(1.0 - clamp(pseudoNormal.z, 0.0, 1.0), 2.6);
    float topStrip = smoothstep(0.26, 0.02, uv.y);
    float bottomStrip = smoothstep(0.72, 0.98, uv.y);

    float rimHighlight = (0.06 + 0.24 * uDepth) * edgeMask * (0.4 + 0.6 * fresnel);
    float topSpec = (0.03 + 0.08 * uDepth) * topStrip;
    float innerShadow = (0.03 + 0.08 * uDepth) * bottomStrip;

    glassColor += rimHighlight + topSpec;
    glassColor -= innerShadow;

    glassColor = mix(glassColor, uTint.rgb, clamp(uTint.a, 0.0, 1.0));

    float effectMix = uGlassOpacity;
    vec3 composited = mix(baseColor, glassColor, effectMix);
    float alpha = mask * qt_Opacity;

    fragColor = vec4(composited * alpha, alpha);
}
