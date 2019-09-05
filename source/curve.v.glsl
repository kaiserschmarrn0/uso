#version 330 core

layout(location = 0) in vec4 v_vtx;
layout(location = 1) in vec4 v_col;

out vec4 f_col;
out vec4 f_vtx:

void main() {
	gl_Position = proj * view * model * vec4(my_pos, 1.0f);
	f_col = v_col;
	f_vtx = v_vtx;
}