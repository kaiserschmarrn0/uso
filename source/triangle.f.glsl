#version 450 core
out vec4 final_col;

in vec3 frag_col;
in vec2 frag_tex;

uniform sampler2D texture1;
uniform sampler2D texture2;

void main() {
	final_col = mix(texture(texture1, frag_tex), texture(texture2, frag_tex), 0.2f);
}