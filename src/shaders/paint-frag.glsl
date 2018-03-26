#version 300 es
precision highp float;

in vec2 fs_UV;
out vec4 out_Col;

uniform sampler2D u_frame;
uniform sampler2D u_preFrame;
//uniform sampler2D u_gb0;
uniform float u_Time;
uniform vec2 u_Dims;


void main() {
    vec2 GRID_DIMS = vec2(70.0) * 0.5 * u_Dims.x / 526.0;
    float radius = 0.4 * 1.0 / GRID_DIMS.x;
	vec3 color = vec3(5.0);
    vec2 cellCorner = floor(fs_UV * GRID_DIMS) / GRID_DIMS;
    vec3 minColor = vec3(0.0);
    float minLen = 100.0;
    for (int i = -2; i <= 2; i++) {
        for (int j = -2; j <= 2; j++) {
            // read curl noise's angle and color from prepass frame
            vec2 sampleCorner = cellCorner + vec2(i, j) / GRID_DIMS;
            vec4 prepass = texture(u_preFrame, sampleCorner);
            vec2 p = fs_UV - sampleCorner; // in corner-space
            p.x *= u_Dims.x / u_Dims.y;
            // find rotation
            float angle = prepass.w;
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
                minColor = prepass.xyz;
            }
            else if (i == 0 && j == 0 && minLen == 100.0) {
                minColor = prepass.xyz; // use this fragment's default color
            }
        }
    }
	out_Col = vec4(minColor, 1.0);
}
