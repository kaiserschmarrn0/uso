#version 330 core
out vec4 f_col;

in float f_tex;

uniform sampler1D slidertex;

void main() {
	f_col = texture(slidertex, f_tex);
}