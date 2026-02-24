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
    float uSplayDepth;
    float uRimWidth;
    float uRimStrength;
    float uBodyDepth;
    float uBodyExponent;
    float uBodyStrength;
    float uMagnifyStrength;
    float uVibrance;
    float uGlassOpacity;
    float uTime;
    float uDebug;
    float uDebugView;
    float uLightAngleDeg;
    float uLightStrength;
    float uLightWidthPx;
    float uLightSharpness;
    float uBodyRefractionWidthPx;
    float uCornerBoost;
    float uDispersionLimit;
    float uDispersionWidthPx;
    float uDispersionCurve;
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

vec2 clampToUvRect(vec2 uv, vec4 uvRect) {
    vec2 uvMin = uvRect.xy + vec2(0.0005);
    vec2 uvMax = (uvRect.xy + uvRect.zw) - vec2(0.0005);
    return clamp(uv, uvMin, max(uvMin, uvMax));
}

void main() {
    vec2 uv = qt_TexCoord0;
    vec2 pixel = uv * uSize;

    float sdf = roundedRectSdf(pixel, uSize, uRadius);
    float edgeDist = -sdf;

    float mask = smoothstep(0.0, 1.0, edgeDist);
    float rimWidthPx = max(1.0, uRimWidth);
    // Rim mask: narrow edge-focused band for crisp silhouette distortion.
    float rimMask = 1.0 - smoothstep(0.0, rimWidthPx, edgeDist);
    rimMask *= rimMask;
    float edgeInfluence = rimMask;

    float bodyDepthPx = max(1.0, max(uBodyDepth, uBodyRefractionWidthPx * 2.0));
    // Body mask: normalized interior depth from SDF, spread by bodyExponent.
    float insideNorm = clamp(edgeDist / bodyDepthPx, 0.0, 1.0);
    float bodyExponent = max(0.15, uBodyExponent);
    float bodyMask = pow(insideNorm, bodyExponent);

    vec2 centerUv = (uv - vec2(0.5)) * vec2(uSize.x / max(1.0, uSize.y), 1.0);
    float radial = clamp(length(centerUv) * 1.41421356, 0.0, 1.4);
    // Lens profile: broad radial shaping so interior stays optically active.
    float lensCore = 1.0 - smoothstep(0.0, 1.15, radial);
    float lensProfile = mix(0.45, 1.0, lensCore);
    float bodyInfluence = bodyMask * lensProfile;

    // Avoid dFdx/dFdy seam across the internal quad triangle split by using
    // finite differences in pixel space.
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
    vec2 tangent = vec2(-normal2d.y, normal2d.x);
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
    cornerness *= (0.4 + 0.6 * max(rimMask, bodyInfluence));

    float depthGain = 1.0 + (uDepth * 0.95);
    vec2 pixelToUv = vec2(1.0 / max(1.0, uSize.x), 1.0 / max(1.0, uSize.y));
    float refrControl = max(uRefraction, 0.0);
    float refrResponse = 1.0 - exp(-refrControl * 0.04);
    float cornerBoost = clamp(uCornerBoost, 0.0, 1.0);
    float refrBasePx = (9.6 * refrResponse) * (0.35 + 0.65 * depthGain);

    float rimStrength = max(0.0, uRimStrength);
    float rimPx = refrBasePx
        * rimStrength
        * rimMask
        * (1.0 + cornerBoost * cornerness);
    vec2 rimOffset = normal2d * rimPx * pixelToUv;

    float splayReachPx = max(1.0, uSplayDepth);
    float splayInfluence = 1.0 - smoothstep(0.0, splayReachPx, edgeDist);
    splayInfluence *= splayInfluence;
    float splayPx = (0.2 + 2.2 * uSplay) * splayInfluence;
    vec2 splayOffset = tangent * splayPx * pixelToUv;

    float bodyStrength = max(0.0, uBodyStrength);
    vec2 centerVec = pixel - (uSize * 0.5);
    float centerLen = length(centerVec);
    vec2 centerDir = centerLen > 1e-4 ? (centerVec / centerLen) : normal2d;
    vec2 mixedBodyDir = mix(normal2d, centerDir, 0.35);
    vec2 bodyDir = mixedBodyDir / max(length(mixedBodyDir), 1e-4);
    float bodyPx = refrBasePx * bodyStrength * bodyInfluence;
    vec2 bodyOffset = bodyDir * bodyPx * pixelToUv;

    // Center magnification/compression: subtle radial lensing in the interior.
    float magnifyStrength = clamp(uMagnifyStrength, -0.35, 0.35);
    float centerMask = bodyMask * (1.0 - smoothstep(0.20, 1.0, radial));
    vec2 centerMagnifyOffset = -(uv - vec2(0.5))
        * magnifyStrength
        * centerMask
        * (0.65 + 0.35 * depthGain);

    // Final distortion combines rim, broad body, and center lens contributions.
    vec2 distortionUv = rimOffset + splayOffset + bodyOffset + centerMagnifyOffset;

    vec2 mappedUv = uUvRect.xy + (uv * uUvRect.zw);
    vec2 refractedUv = clampToUvRect(mappedUv + distortionUv, uUvRect);

    if (uDebug > 0.5) {
        if (uDebugView < 0.5) {
            fragColor = vec4(rimMask, 0.0, 0.0, 1.0);
            return;
        }
        if (uDebugView < 1.5) {
            fragColor = vec4(0.0, bodyInfluence, 0.0, 1.0);
            return;
        }

        float distortionPx = length(distortionUv * uSize);
        float distortionNorm = clamp(distortionPx / max(1.0, refrBasePx * 1.6), 0.0, 1.0);
        vec3 heat = mix(vec3(0.05, 0.08, 0.20), vec3(0.0, 0.85, 0.95), distortionNorm);
        heat = mix(heat, vec3(1.0, 0.90, 0.10), smoothstep(0.45, 0.85, distortionNorm));
        heat = mix(heat, vec3(1.0, 0.20, 0.10), smoothstep(0.85, 1.0, distortionNorm));
        fragColor = vec4(heat, 1.0);
        return;
    }

    float dispersionWidthPx = max(1.0, uDispersionWidthPx);
    float dispersionMask = 1.0 - smoothstep(0.0, dispersionWidthPx, edgeDist);
    dispersionMask *= dispersionMask * (3.0 - 2.0 * dispersionMask);
    dispersionMask *= (0.72 + 0.28 * cornerness);
    float dispersionControl = max(uDispersion, 0.0);
    float dispersionNorm = dispersionControl / (1.0 + dispersionControl);
    float dispersionCurve = max(0.2, uDispersionCurve);
    float dispersionResponse = pow(dispersionNorm, dispersionCurve);
    float dispersionLimit = clamp(uDispersionLimit, 0.0, 1.0);
    float dispersionAmount = min(dispersionResponse * dispersionMask, dispersionLimit);
    float dispersionMix = clamp(dispersionAmount * 2.6, 0.0, 1.0);
    // Keep dispersion restrained, but allow a visible RGB split at practical widget sizes.
    float dispersionPx = (0.20 + 4.40 * dispersionAmount) * (0.70 + 0.30 * bodyMask);
    vec2 dispersionDir = normalize(normal2d + (tangent * 0.30));
    vec2 dispersionVec = dispersionDir * dispersionPx * pixelToUv;

    vec3 baseColor = sampleScene(mappedUv);
    vec3 monoRefracted = sampleScene(refractedUv);
    vec3 dispersedColor;
    dispersedColor.r = sampleScene(clampToUvRect(refractedUv + (dispersionVec * 1.35), uUvRect)).r;
    dispersedColor.g = sampleScene(clampToUvRect(refractedUv - (dispersionVec * 0.20), uUvRect)).g;
    dispersedColor.b = sampleScene(clampToUvRect(refractedUv - (dispersionVec * 1.35), uUvRect)).b;
    vec3 refractedColor = mix(monoRefracted, dispersedColor, dispersionMix);

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

    vec3 pseudoNormal = normalize(vec3(
        -(normal2d.x * edgeInfluence) * depthGain,
        -(normal2d.y * edgeInfluence) * depthGain,
        1.0
    ));

    float fresnel = pow(1.0 - clamp(pseudoNormal.z, 0.0, 1.0), 2.2);

    // Light direction (0°=top, 90°=right, clockwise)
    float a = radians(uLightAngleDeg);
    vec2 lightFrom2D = normalize(vec2(sin(a), -cos(a)));

    // Separate width masks
    float lightWidthPx = max(1.0, uLightWidthPx);
    float coreWidthPx = max(1.0, lightWidthPx * 0.18);

    // Broad band inside edge
    float edgeWide = 1.0 - smoothstep(0.0, lightWidthPx, edgeDist);

    // Thin core line
    float edgeCore = 1.0 - smoothstep(0.0, coreWidthPx, edgeDist);

    // Shape wide band falloff
    edgeWide *= edgeWide * (3.0 - 2.0 * edgeWide);

    // Edge facing
    float edgeFacing = max(dot(normal2d, lightFrom2D), 0.0);

    // Sharpness control
    float sharp = clamp(uLightSharpness, 0.0, 1.0);

    // Broad/core directional lobes
    float edgeLobeWide = pow(edgeFacing, mix(2.0, 6.0, sharp));
    float edgeLobeCore = pow(edgeFacing, mix(8.0, 18.0, sharp));

    // Blinn specular
    vec3 V = vec3(0.0, 0.0, 1.0);
    vec3 L = normalize(vec3(lightFrom2D * (0.75 + 0.35 * uDepth), 0.55 + 0.25 * uDepth));
    vec3 H = normalize(L + V);

    float ndh = max(dot(pseudoNormal, H), 0.0);

    // Broad/core spec lobes
    float specWide = pow(ndh, mix(8.0, 24.0, sharp));
    float specCore = pow(ndh, mix(24.0, 72.0, sharp));

    // Ambient rim
    float rimHighlight = (0.025 + 0.10 * uDepth)
        * edgeWide
        * (0.35 + 0.65 * fresnel);

    // Broad directional glow
    float directionalBroad = uLightStrength
        * edgeWide
        * (0.55 * edgeLobeWide + 0.45 * specWide)
        * (0.35 + 0.65 * fresnel);

    // Thin bright core rim
    float directionalCore = uLightStrength
        * edgeCore
        * (0.50 * edgeLobeCore + 0.50 * specCore)
        * (0.45 + 0.55 * fresnel);

    // Opposite-edge darkening for thickness
    float oppositeFacing = max(dot(normal2d, -lightFrom2D), 0.0);
    float directionalShadow = (0.008 + 0.028 * uDepth)
        * edgeWide
        * pow(oppositeFacing, 1.35)
        * (0.35 + 0.65 * uLightStrength);

    // Optional subtle bottom shadow
    float bottomStrip = smoothstep(0.72, 0.98, uv.y);
    float innerShadow = (0.010 + 0.024 * uDepth) * bottomStrip;

    // Apply
    glassColor += rimHighlight + directionalBroad + directionalCore;
    glassColor -= directionalShadow + innerShadow;

    glassColor = mix(glassColor, uTint.rgb, clamp(uTint.a, 0.0, 1.0));

    float vibrance = clamp(uVibrance, -1.0, 1.0);
    float maxChannel = max(glassColor.r, max(glassColor.g, glassColor.b));
    float minChannel = min(glassColor.r, min(glassColor.g, glassColor.b));
    float saturation = maxChannel - minChannel;
    float vibranceScale = 1.0 + (vibrance >= 0.0 ? (vibrance * (1.0 - saturation)) : vibrance);
    float vibranceLuma = dot(glassColor, vec3(0.2126, 0.7152, 0.0722));
    glassColor = vec3(vibranceLuma) + ((glassColor - vec3(vibranceLuma)) * max(0.0, vibranceScale));

    float effectMix = uGlassOpacity;
    vec3 composited = mix(baseColor, glassColor, effectMix);
    float alpha = mask * qt_Opacity;

    fragColor = vec4(composited * alpha, alpha);
}
