#version 440

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(binding = 1) uniform sampler2D sourceTexture;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec2 resolution;   // size of the whole effect item, logical px
    vec2 pillPos;      // glass top-left inside that item, px
    vec2 pillSize;     // glass size, px
    float radius;      // glass corner radius, px
    float strength;    // max edge displacement, px
    float thickness;   // width of the refracting bevel, px
    float dispersion;  // chromatic split at the edge (0.0 - 0.3)
};

void main() {
    vec2 uv = qt_TexCoord0;
    vec4 base = texture(sourceTexture, uv);

    // Signed distance to the rounded-rect glass (negative = inside).
    vec2 halfSize = pillSize * 0.5;
    vec2 q = uv * resolution - (pillPos + halfSize);
    vec2 k = abs(q) - (halfSize - vec2(radius));
    float d = length(max(k, 0.0)) + min(max(k.x, k.y), 0.0) - radius;

    // Outside the glass, or in the flat interior: untouched.
    if (d >= 0.0 || d <= -thickness) {
        fragColor = base * qt_Opacity;
        return;
    }

    // Outward surface normal of the rounded rect.
    vec2 n = (k.x > 0.0 && k.y > 0.0)
        ? normalize(k) * sign(q)
        : (k.x > k.y ? vec2(sign(q.x), 0.0) : vec2(0.0, sign(q.y)));

    // Bevel profile: 0 at the inner edge of the bevel, 1 at the rim.
    float t = 1.0 + d / thickness;
    float bend = pow(t, 2.4);

    // Sample from further out toward the rim: content bends and compresses
    // like it would through a thick convex edge. R/G/B split slightly.
    vec2 disp = n * bend * strength / resolution;
    float split = dispersion * bend;
    vec2 lo = vec2(0.001), hi = vec2(0.999);
    float r = texture(sourceTexture, clamp(uv + disp * (1.0 + split), lo, hi)).r;
    vec4  g = texture(sourceTexture, clamp(uv + disp,                 lo, hi));
    float b = texture(sourceTexture, clamp(uv + disp * (1.0 - split), lo, hi)).b;

    // Directional light: bright top-left, softer bounce bottom-right.
    vec2 L = normalize(vec2(-0.6, -0.8));
    float spec = bend * bend * (0.04 + 0.22 * max(dot(n, L), 0.0)
                                     + 0.10 * max(dot(n, -L), 0.0));
    vec3 glow = vec3(0.82, 0.92, 1.0) * spec;

    fragColor = vec4(vec3(r, g.g, b) + glow, max(g.a, spec)) * qt_Opacity;
}
