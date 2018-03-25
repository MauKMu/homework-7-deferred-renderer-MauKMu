#version 300 es
precision highp float;

in vec2 fs_UV;
out vec4 out_Col;

uniform sampler2D u_frame;
//uniform sampler2D u_preFrame;
//uniform float u_Time;

// Interpolation between color and greyscale over time on left half of screen
void main() {
	vec3 color = texture(u_frame, fs_UV).xyz;
    float lum = dot(color, vec3(0.2126, 0.7152, 0.072));
    color = (lum > 0.9) ? color : vec3(0.0);
	out_Col = vec4(color, 1.0);
}
