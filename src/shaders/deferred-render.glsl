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

uniform mat4 u_View;
uniform vec4 u_CamPos;   

const float CAMERA_TAN = tan(0.5 * 45.0 * 3.1415962 / 180.0);

void main() { 
	// read from GBuffers
	vec4 gb0 = texture(u_gb0, fs_UV);
	vec4 gb1 = texture(u_gb1, fs_UV);
	vec4 gb2 = texture(u_gb2, fs_UV);

    // read albedo
    vec3 albedo = gb2.xyz;
    float depth = gb0.w;

    vec3 col;

    // background
    if (depth >= -5.0) {
        col = vec3(fs_UV, 0.2);
    }
    // shade
    else {
        depth += 5.0;
        col = albedo;
        // get cam-space position
        vec3 ndcPos = vec3(fs_UV.xy * 2.0 - 1.0, depth);
        //vec3 ndcPos = vec3(fs_UV.x * 2.0 - 1.0, 1.0 - fs_UV.y * 2.0, depth);
        //col = abs(ndcPos - vec3(gb0.xy / 760.0, gb0.z)) * 0.1;
        //col = abs(ndcPos - vec3(gb0.x * 2.0 - 1.0, 1.0 - gb0.y, gb0.z)) * 1.0;
        float vert = CAMERA_TAN * abs(depth);
        float hori = vert;
        vec3 camPos = ndcPos * vec3(hori, vert, 1.0);
        //col = abs(camPos - gb0.xyz) * 1.0;
        //col = col.yyy;
        vec3 worPos = vec3(inverse(u_View) * vec4(camPos, 1.0));
        col = abs(worPos - gb0.xyz) * 1.0;
        //col = vec3(depth - gb0.z);
    }

	out_Col = vec4(col, 1.0);
}