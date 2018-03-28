#version 300 es
precision highp float;

in vec2 fs_UV;
out vec4 out_Col;

uniform sampler2D u_frame;
//uniform sampler2D u_preFrame;
uniform sampler2D u_gb0;
uniform float u_Time;
uniform vec2 u_Dims;

// from https://stackoverflow.com/questions/15095909/from-rgb-to-hsv-in-opengl-glsl
vec3 rgb2hsv(vec3 c)
{
    vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
    vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
    vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));

    float d = q.x - min(q.w, q.y);
    float e = 1.0e-10;
    return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

vec3 hsv2rgb(vec3 c)
{
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

vec2 random2(vec2 p) {
    return normalize(2.0 * fract(sin(vec2(dot(p, vec2(127.1, 311.7)), dot(p, vec2(269.5, 183.3))))*123.45) - 1.0);
}

const float NOISE_TILE_DIM = 400.0;
//const float NOISE_COS = 0.93969;
//const float NOISE_SIN = -0.3420201;
const float NOISE_STRIPE_DIM = 30.0;

const float GAUSS_KERNEL[5] = float[5](
    0.122581, 0.233062, 0.288713, 0.233062, 0.122581);

void main() {
    vec3 color = texture(u_frame, fs_UV).xyz;
    vec2 pixelDims = 1.0 / u_Dims;
    // chromatic aberration
    float GREEN_OFFSET = 5.0 * (1.0 + abs(fs_UV.x - 0.5) * 5.0) * (1.0 + 0.1 * random2(vec2(fs_UV.y * 9.12)).y);
    vec3 neighbor = texture(u_frame, fs_UV + pixelDims * vec2(GREEN_OFFSET, 0.0)).xyz;
    color.y = neighbor.y;

    // add constant static
    vec2 noiseCell = floor(fs_UV * NOISE_TILE_DIM) / NOISE_TILE_DIM;
    // rotate point
    //noiseCell = vec2(dot(noiseCell, vec2(NOISE_COS, -NOISE_SIN)), dot(noiseCell, vec2(NOISE_SIN, NOISE_COS)));
    // noiseCell * 0.01 gives a wave-like pattern
    float noise = 0.5 + 0.5 * random2(noiseCell * 0.1 + vec2(u_Time * 0.0002, -u_Time * 0.00003)).x;
    color *= 0.9 + 0.1 * noise;

    float STRIPE_START = mod(-u_Time * 0.4, 1.5);

    // add intermittent static stripe
    if (STRIPE_START < fs_UV.y && fs_UV.y < STRIPE_START + pixelDims.y * NOISE_STRIPE_DIM) {
        noise = 0.0;
        // 2 pixels tall
        noiseCell.y = floor(fs_UV.y * u_Dims.y) / (u_Dims.y);
        // randomly scale size of noise column for each row
        float rowScale = random2(noiseCell.yy).y * 0.5 + 1.5;
        for (int i = -2; i <= 2; i++) {
            noiseCell.x = floor((fs_UV.x + float(i) * pixelDims.x) * NOISE_TILE_DIM * 0.05 * rowScale) / (NOISE_TILE_DIM * 0.05 * rowScale);
            noise += GAUSS_KERNEL[i + 2] * 1.3 * smoothstep(-0.9, 0.95, random2(noiseCell + vec2(u_Time * 0.0002, u_Time * 0.000)).y);
        }
        color *= 0.8 + 0.2 * noise;
    }

	out_Col = vec4(color, 1.0);
}
