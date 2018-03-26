#version 300 es
precision highp float;

in vec2 fs_UV;
out vec4 out_Col;

uniform sampler2D u_frame;
uniform sampler2D u_preFrame;
//uniform sampler2D u_gb0;
uniform float u_Time;
uniform vec2 u_Dims;

const vec2 GRID_DIMS = vec2(70.0);

// noise helper functions

// from Adam's demo
vec2 random2(vec2 p) {
    //vec2 sinVec = sin(vec2(dot(p, vec2(127.1, 311.7)), dot(p, vec2(269.5, 183.3))));
    //return sinVec * 0.5 + vec2(0.5);
    //return fract(sinVec * 123.45);
    //return fract(sinVec * 43758.5453);
    return normalize(2.0 * fract(sin(vec2(dot(p, vec2(127.1, 311.7)), dot(p, vec2(269.5, 183.3))))*123.45) - 1.0);
}

float surflet(vec2 P, vec2 gridPoint)
{
    //return (P.x * P.x) * 0.07;
    // Compute falloff function by converting linear distance to a polynomial
    float distX = abs(P.x - gridPoint.x);
    float distY = abs(P.y - gridPoint.y);
    float tX = 1.0 - 6.0 * pow(distX, 5.0) + 15.0 * pow(distX, 4.0) - 10.0 * pow(distX, 3.0);
    float tY = 1.0 - 6.0 * pow(distY, 5.0) + 15.0 * pow(distY, 4.0) - 10.0 * pow(distY, 3.0);

    // Get the random vector for the grid point
    vec2 gradient = random2(gridPoint);
    // Get the vector from the grid point to P
    vec2 diff = P - gridPoint;
    // Get the value of our height field by dotting grid->P with our gradient
    float height = dot(diff, gradient);
    // Scale our height field (i.e. reduce it) by our polynomial falloff function
    return height * tX * tY;
}

float PerlinNoise(vec2 uv)
{
    // Tile the space
    vec2 uvXLYL = floor(uv);
    vec2 uvXHYL = uvXLYL + vec2(1, 0);
    vec2 uvXHYH = uvXLYL + vec2(1, 1);
    vec2 uvXLYH = uvXLYL + vec2(0, 1);

    return surflet(uv, uvXLYL) + surflet(uv, uvXHYL) + surflet(uv, uvXHYH) + surflet(uv, uvXLYH);
}


float normalizedPerlinNoise(vec2 v) {
    return clamp(0.0, 1.0, PerlinNoise(v) + 0.5);
}

/* FBM (uses Perlin) */
float getFBM(vec2 pt, float startFreq) {
    float noiseSum = 0.0;
    float amplitudeSum = 0.0;
    float amplitude = 1.0;
    float frequency = startFreq;
    for (int i = 0; i < 2; i++) {
        float perlin = normalizedPerlinNoise(pt * frequency);
        noiseSum += perlin * amplitude;
        amplitudeSum += amplitude;
        amplitude *= 0.5;
        frequency *= 2.0;
    }
    return noiseSum / amplitudeSum;
}

// "normalizes" coordinate before calling FBM
float getFBMFromRawPosition(vec2 pos, float startFreq) {
    vec2 coord = pos;
    coord += vec2(3.14, 5.01);// +vec2(u_PerlinSeed);
                              //return pow(sin(coord.x + coord.y), 2.0);
    float fbm = getFBM(coord, startFreq);
    // [0.1, 0.8]
    //return pow((fbm - 0.05) / 0.7, 3.2);
    fbm = pow((fbm - 0.05) / 0.7, 3.2);
    fbm = smoothstep(0.0, 1.3, fbm);
    return fbm;
    //return pow(1.0 - fbm, 2.2);
    //return pow(clamp(0.0, 1.0, (fbm - 0.25) / 0.6), 3.2) * 0.5;
}

void main() {
    float radius = 0.4 * 1.0 / GRID_DIMS.x;
	vec3 color = vec3(5.0);
    vec2 cellCorner = floor(fs_UV * GRID_DIMS) / GRID_DIMS;
    vec2 minUV = fs_UV;
    float minLen = 100.0;
    for (int i = -1; i <= 1; i++) {
        for (int j = -1; j <= 1; j++) {
            vec2 sampleCorner = cellCorner + vec2(i, j) / GRID_DIMS;
            vec2 p = fs_UV - sampleCorner; // in corner-space
            p.x *= u_Dims.x / u_Dims.y;
            // find rotation
            const float FREQ = 0.8;
            const float EPSILON = 0.00001;
            float n1, n2, a, b;
            vec2 noisePos = sampleCorner + vec2(-7.88 + u_Time * 0.04, 2.32);
            n1 = getFBMFromRawPosition(noisePos + vec2(0.0, +EPSILON), FREQ);
            n2 = getFBMFromRawPosition(noisePos + vec2(0.0, -EPSILON), FREQ);
            a = (n1 - n2) / (2.0 * EPSILON);
            n1 = getFBMFromRawPosition(noisePos + vec2(+EPSILON, 0.0), FREQ);
            n2 = getFBMFromRawPosition(noisePos + vec2(-EPSILON, 0.0), FREQ);
            b = (n1 - n2) / (2.0 * EPSILON);
            float angle = atan(-b, a);
            float c = cos(angle);
            float s = sin(angle);
            // rotate
            vec2 pRot = vec2(c * p.x - s * p.y, s * p.x + c * p.y);
            // stretch along X
            pRot.x *= 0.25;
            pRot.y *= 0.8;
            float l = length(pRot);
            if (l < radius && l < minLen) {
                minLen = l;
                minUV = sampleCorner;
            }
        }
    }
    vec4 sampleColor = texture(u_frame, minUV);
    color = sampleColor.xyz;
	out_Col = vec4(color, 1.0);
}
