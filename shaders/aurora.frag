#version 460 core
#include <flutter/runtime_effect.glsl>

precision highp float;

// Uniforms — set by index in declaration order from Dart (vec2 = 2 float slots):
//   0,1 -> uResolution
//   2   -> uTime
//   3,4 -> uMouse
//   5   -> uVivid   (0 = calm, 1 = vivid; eased by Dart)
uniform vec2  uResolution;
uniform float uTime;
uniform vec2  uMouse;
uniform float uVivid;

out vec4 fragColor;

float hash(vec2 p) {
    p = fract(p * vec2(123.34, 345.45));
    p += dot(p, p + 34.345);
    return fract(p.x * p.y);
}

float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    vec2 u = f * f * (3.0 - 2.0 * f);
    float a = hash(i);
    float b = hash(i + vec2(1.0, 0.0));
    float c = hash(i + vec2(0.0, 1.0));
    float d = hash(i + vec2(1.0, 1.0));
    return mix(mix(a, b, u.x), mix(c, d, u.x), u.y);
}

float fbm(vec2 p) {
    float v = 0.0;
    float a = 0.5;
    for (int i = 0; i < 5; i++) {
        v += a * noise(p);
        p *= 2.02;
        a *= 0.5;
    }
    return v;
}

void main() {
    vec2 frag = FlutterFragCoord().xy;
    vec2 uv = frag / uResolution;

    float aspect = uResolution.x / uResolution.y;
    vec2 p = uv;
    p.x *= aspect;

    vec2 m = uMouse / uResolution;
    m.x *= aspect;

    float t = uTime * 0.045;

    vec2 q = vec2(
        fbm(p * 1.6 + vec2(0.0, t)),
        fbm(p * 1.6 + vec2(5.2, 1.3) - t)
    );
    vec2 r = vec2(
        fbm(p * 1.6 + 3.5 * q + vec2(1.7, 9.2) + 0.15 * t),
        fbm(p * 1.6 + 3.5 * q + vec2(8.3, 2.8) - 0.12 * t)
    );
    float f = fbm(p * 1.6 + 3.0 * r);

    // Palette — matches AppColors.
    vec3 base   = vec3(0.027, 0.027, 0.055);
    vec3 violet = vec3(0.486, 0.361, 1.000);
    vec3 cyan   = vec3(0.176, 0.831, 1.000);
    vec3 pink   = vec3(1.000, 0.361, 0.541);

    // Vivid shifts the palette to the brighter variants.
    violet = mix(violet, vec3(0.608, 0.482, 1.000), uVivid);
    cyan   = mix(cyan,   vec3(0.302, 0.890, 1.000), uVivid);
    pink   = mix(pink,   vec3(1.000, 0.435, 0.627), uVivid);

    // Scale mix weights so vivid = more saturated fill.
    float vw = 1.0 + 0.4 * uVivid;
    vec3 col = base;
    col = mix(col, violet, clamp(f * f * 1.7 * vw, 0.0, 1.0));
    col = mix(col, cyan,   clamp(r.x * 0.85 * vw, 0.0, 1.0));
    col = mix(col, pink,   clamp(q.y * 0.55 * vw, 0.0, 1.0));

    // Cursor glow — wider and stronger in vivid mode.
    float md = distance(p, m);
    float glow = smoothstep(0.95, 0.0, md);
    col += cyan * glow * (0.22 + 0.8 * uVivid);

    // Saturation boost for vivid.
    float lum = dot(col, vec3(0.299, 0.587, 0.114));
    col = mix(vec3(lum), col, 1.0 + 0.6 * uVivid);

    // Vignette.
    float vig = smoothstep(1.25, 0.25, length(uv - 0.5));
    col *= mix(0.55, 1.0, vig);

    // Overall brightness — slightly higher in vivid.
    col *= 0.66 + 0.08 * uVivid;

    fragColor = vec4(col, 1.0);
}
