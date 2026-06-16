#version 460 core
#include <flutter/runtime_effect.glsl>

precision highp float;

// Slot index in declaration order (vec2 = 2 floats):
//   0,1 -> uResolution
//   2   -> uTime
//   3,4 -> uMouse
//   5   -> uSpeed
//   6   -> uWarp
//   7   -> uGlow
//   8   -> uHue
uniform vec2  uResolution;
uniform float uTime;
uniform vec2  uMouse;
uniform float uSpeed;
uniform float uWarp;
uniform float uGlow;
uniform float uHue;

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

vec3 hueShift(vec3 col, float a) {
    const vec3 k = vec3(0.57735);
    float c = cos(a);
    return col * c + cross(k, col) * sin(a) + k * dot(k, col) * (1.0 - c);
}

void main() {
    vec2 frag = FlutterFragCoord().xy;
    vec2 uv = frag / uResolution;

    float aspect = uResolution.x / uResolution.y;
    vec2 p = uv;
    p.x *= aspect;

    vec2 m = uMouse / uResolution;
    m.x *= aspect;

    float t = uTime * 0.045 * uSpeed;

    vec2 q = vec2(
        fbm(p * 1.6 * uWarp + vec2(0.0, t)),
        fbm(p * 1.6 * uWarp + vec2(5.2, 1.3) - t)
    );
    vec2 r = vec2(
        fbm(p * 1.6 * uWarp + 3.5 * q + vec2(1.7, 9.2) + 0.15 * t),
        fbm(p * 1.6 * uWarp + 3.5 * q + vec2(8.3, 2.8) - 0.12 * t)
    );
    float f = fbm(p * 1.6 * uWarp + 3.0 * r);

    vec3 base   = vec3(0.027, 0.027, 0.055);
    vec3 violet = vec3(0.486, 0.361, 1.000);
    vec3 cyan   = vec3(0.176, 0.831, 1.000);
    vec3 pink   = vec3(1.000, 0.361, 0.541);

    vec3 col = base;
    col = mix(col, violet, clamp(f * f * 1.7, 0.0, 1.0));
    col = mix(col, cyan,   clamp(r.x * 0.85, 0.0, 1.0));
    col = mix(col, pink,   clamp(q.y * 0.55, 0.0, 1.0));

    float md = distance(p, m);
    float glow = smoothstep(0.95, 0.0, md);
    col += cyan * glow * uGlow;

    float vig = smoothstep(1.25, 0.25, length(uv - 0.5));
    col *= mix(0.55, 1.0, vig);
    col *= 0.66;

    col = hueShift(col, uHue);

    fragColor = vec4(col, 1.0);
}
