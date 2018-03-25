#version 300 es
precision highp float;

in vec2 fs_UV;
out vec4 out_Col;

uniform sampler2D u_frame;
//uniform sampler2D u_preFrame;
uniform sampler2D u_gb0;
//uniform float u_Time;
uniform vec2 u_Dims;

const float GAUSS_KERNEL[7] = float[7](
    0.092904, 0.137865, 0.174704, 0.189054, 0.174704, 0.137865, 0.092904);

const float IDENTITY_KERNEL[7] = float[7](
    0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0);

const float FOCAL_LENGTH = -60.0; 

void main() {
	vec3 color = vec3(0.0);
    vec4 gb0 = texture(u_gb0, fs_UV);
    float depth = gb0.w;
    depth = (depth >= 1.0) ? 1000000.0 : depth;
    float weight = smoothstep(4.0, 40.0, abs(depth - FOCAL_LENGTH));
    float pixelDim = 1.0 / u_Dims.x;
    for (int i = -3; i <= 3; i++) {
    	color += mix(IDENTITY_KERNEL[i], GAUSS_KERNEL[i], weight) * texture(u_frame, fs_UV + vec2(float(i) * pixelDim, 0.0)).xyz;
    }
	out_Col = vec4(color, 1.0);
}
