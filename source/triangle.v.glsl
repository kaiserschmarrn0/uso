#version 450 core
layout (location = 0) in vec3 my_pos;
//ayout (location = 1) in vec3 my_col;
layout (location = 1) in vec2 my_tex;

out vec2 frag_tex;

uniform mat4 model;
uniform mat4 view;
uniform mat4 proj;

void main() {
	gl_Position = proj * view * model * vec4(my_pos, 1.0f);
	//frag_col = my_col;
	frag_tex = my_tex;
}