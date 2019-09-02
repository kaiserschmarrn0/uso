#version 450 core
layout (location = 0) in vec3 my_pos;
layout (location = 1) in vec3 my_col;

out vec3 frag_col;

void main() {
	gl_Position = vec4(my_pos, 1.0f);
	frag_col = my_col;
}