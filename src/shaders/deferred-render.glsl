#version 300 es
precision highp float;

#define EPS 0.0001
#define PI 3.1415962

in vec2 fs_UV;
out vec4 out_Col;

uniform sampler2D u_gb0;
uniform sampler2D u_gb1;
uniform sampler2D u_gb2;

uniform float u_Time;
uniform float u_AspectRatio;

uniform mat4 u_View;
uniform vec4 u_CamPos;   

const float CAMERA_TAN = tan(0.5 * 45.0 * 3.1415962 / 180.0);
const float DEPTH_OFFSET = 0.125;

const vec3 LIGHT_POS = vec3(0, 20, 10);

float getLambert(vec3 worldPos, vec3 normal) {
    vec3 toLight = normalize(LIGHT_POS - worldPos);
    return clamp(0.0, 1.0, dot(toLight, normal));
}

void main() { 
	// read from GBuffers
	vec4 gb0 = texture(u_gb0, fs_UV);
	vec4 gb1 = texture(u_gb1, fs_UV);
	vec4 gb2 = texture(u_gb2, fs_UV);

    // put GBuffer data in more readable variables
    vec3 nor = gb0.xyz;
    float depth = gb0.w;
    vec3 albedo = gb2.xyz;

    // final color of this fragment
    vec3 col;

    // background
    if (depth >= -DEPTH_OFFSET) {
        col = vec3(fs_UV, 0.2);
    }
    // shade
    else {
        depth += DEPTH_OFFSET;
        //col = albedo;
        // get cam-space position
        vec3 ndcPos = vec3(fs_UV.xy * 2.0 - 1.0, depth);
        float vert = CAMERA_TAN * abs(depth);
        float hori = vert * u_AspectRatio;
        vec3 camPos = ndcPos * vec3(hori, vert, 1.0);
        // convert to world-space pos
        vec3 worldPos = vec3(inverse(u_View) * vec4(camPos, 1.0));
        col = (0.2 + 0.8 * getLambert(worldPos, nor)) * albedo;
    }

	out_Col = vec4(col, 1.0);
}