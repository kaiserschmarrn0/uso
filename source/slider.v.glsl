#version 330 core

layout (location = 0) in vec3 v_vtx;
layout (location = 1) in float v_tex;

out float f_tex;

uniform mat4 model;
uniform mat4 view;
uniform mat4 proj;

void main() {
	gl_Position = proj * view * model * vec4(v_vtx, 1.0f);
	f_tex = v_tex;
}