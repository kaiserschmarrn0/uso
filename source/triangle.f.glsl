#version 450 core
out vec4 final_col;
in vec3 frag_col;

void main() {
	final_col = vec4(frag_col, 1.0f);
}