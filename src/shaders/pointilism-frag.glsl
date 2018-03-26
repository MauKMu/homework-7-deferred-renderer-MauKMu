#version 300 es
precision highp float;

in vec2 fs_UV;
out vec4 out_Col;

uniform sampler2D u_frame;
//uniform sampler2D u_preFrame;
//uniform sampler2D u_gb0;
//uniform float u_Time;
uniform vec2 u_Dims;

const vec2 GRID_DIMS = vec2(200.0);

void main() {
    vec2 cellCorner = floor(fs_UV * GRID_DIMS) / GRID_DIMS;
    float minF = 5.0;
    for (int i = -1; i <= 1; i++) {
        for (int j = -1; j <= 1; j++) {
            vec2 sampleCorner = cellCorner + vec2(i, j) / GRID_DIMS;
            vec4 sampleColor = texture(u_frame, sampleCorner);
            float lum = dot(sampleColor.xyz, vec3(0.2126, 0.7152, 0.072));
            float dist = 0.0002 + 0.001 * (1.0 - clamp(0.0, 3.0, lum) / 3.0);
            float f = smoothstep(dist, 3.0 * dist, distance(sampleCorner, fs_UV));
            minF = min(minF, 5.0 * f);
            /*
            if (distance(sampleCorner, fs_UV) < dist) {
                color = vec3(0.0);
            }
            */
        }
    }
	vec3 color = vec3(minF);
	out_Col = vec4(color, 1.0);
}
