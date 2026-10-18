#version 440

layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(binding = 1) uniform sampler2D sourceTexture;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec2 resolution;
    float strength;
    float time;
};

void main() {
    vec2 uv = qt_TexCoord0;
    vec2 p = uv * 2.0 - 1.0;

    float r2 = dot(p, p);
    vec2 normal = normalize(p + vec2(0.0001));
    vec2 offset = normal * r2 * strength;

    vec2 warpedUV = clamp(
        uv + offset / max(resolution, vec2(1.0)),
        vec2(0.001),
        vec2(0.999)
    );

    vec4 scene = texture(sourceTexture, warpedUV);
    float edge = smoothstep(0.95, 0.35, r2);
    vec3 highlight = vec3(0.72, 0.87, 1.0) * edge * 0.10;

    fragColor = vec4(scene.rgb + highlight, scene.a) * qt_Opacity;
}
