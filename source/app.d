import core.stdc.stdio;
import core.stdc.stdlib;
import core.thread;
import core.time;
import core.simd;

import bindbc.glfw;
import bindbc.opengl;

import stb.image.binding;

import usomath;

nothrow:
@nogc:

GLFWwindow* win;

extern (C) void uso_glfw_error_cb(int code, const(char)* dsc) {
	printf("uso: glfw error:\n\terror code: %d\n\terror desc: %s\n", code, dsc);
}

extern (C) void uso_win_close_cb(GLFWwindow* win) {
	printf("uso: closed window.\n");
}

extern (C) void uso_cursor_pos_cb(GLFWwindow* win, double x, double y) {
	//printf("uso: cursor pos:\n\tx: %lf\n\tf: %lf\n", x, y);
}

extern (C) void uso_mouse_button_cb(GLFWwindow* win, int button, int action, int mods) {
	printf("uso: mouse button:\n\tbutton: %d\n\taction: %d\n\tmods: %d\n", button, action, mods);
}

extern (C) void uso_scroll_cb(GLFWwindow* win, double xoff, double yoff) {
	printf("uso: scroll:\n\txoff: %lf\n\tyoff: %lf\n", xoff, yoff);
}

extern (C) void uso_fb_size_cb(GLFWwindow* win, int width, int height) {
	glViewport(0, 0, width, height);
}

extern (C) void uso_drop_cb(GLFWwindow* win, int count, const char** paths) {
	printf("uso: drop:\n\tcount: %d\n", count);
	for (uint i = 0; i < count; i++) {
		printf("\tpath %d: %s\n", i, paths[i]);
	}
}

extern (C) void uso_key_cb(GLFWwindow* win, int key, int scancode, int action, int mods) {
	//GLFW_PRESS GLFW_RELEASE GLFW_REPEAT
	//GLFW_KEY_UNKNOWN
	printf("uso: keyboard:\n\tkey: %d\n\tscancode: %d\n\taction: %d\n\tmods: %d\n", key, scancode, action, mods);
	if (key == GLFW_KEY_ESCAPE && action == GLFW_PRESS) {
		glfwSetWindowShouldClose(win, true);
	}
}

bool setup_shader(ref uint shader, const char *fname, GLenum type) {
	enum size_t buf_max = 1024;

	FILE* fp = fopen(fname, "r");
	char[buf_max] buf;
	if (fp == null) {
		printf("uso: unable to open shader file %s.\n", fname);
		return false;
	}

	const size_t len = fread(buf.ptr, char.sizeof, buf_max, fp);
	fclose(fp);
	if (len >= buf_max) {
		printf("uso: shader %s too long.\n", fname);
		return false;
	}
	buf[len] = '\0';

	shader = glCreateShader(type);
	char *bufptr = buf.ptr;
	glShaderSource(shader, 1, &bufptr, null);
	glCompileShader(shader);
	
	int success;
	glGetShaderiv(shader, GL_COMPILE_STATUS, &success);
	if (!success) {
		char[512] info;
		glGetShaderInfoLog(shader, 512, null, info.ptr);
		printf("uso: failed to compile %s shader: %s\n", fname, info.ptr);
		return false;
	}

	return true;
}

bool setup_program(ref uint shader_program, const char *vertex_name, const char *fragment_name) {
	uint vertex_shader; // @suppress(dscanner.suspicious.unmodified)
	if (!setup_shader(vertex_shader, vertex_name, GL_VERTEX_SHADER)) {
		return false;
	}
	uint fragment_shader; // @suppress(dscanner.suspicious.unmodified)
	if (!setup_shader(fragment_shader, fragment_name, GL_FRAGMENT_SHADER)) {
		return false;
	}

	shader_program = glCreateProgram();
	glAttachShader(shader_program, vertex_shader);
	glAttachShader(shader_program, fragment_shader);
	glLinkProgram(shader_program);
	int success;
	glGetProgramiv(shader_program, GL_LINK_STATUS, &success);
	glDeleteShader(vertex_shader);
	glDeleteShader(fragment_shader);
	if (!success) {
		char[512] info;
		glGetProgramInfoLog(shader_program, 512, null, info.ptr);
		printf("uso: failed to link shader program: %512s\n", info.ptr);
		return false;
	}
	
	return true;
}

void setup_buffer(GLuint* bo, GLenum type, void* data, size_t len, GLenum usage) {
	glGenBuffers(1, bo);
	glBindBuffer(type, *bo);
	glBufferData(type, len, data, usage);
}

void print_v(int4 v) {
	for (uint i = 0; i < v.array.length; i++) {
		printf("%d ", v.ptr[i]);
	}

	printf("\n");
}

void print_v(float4 v) {
	for (uint i = 0; i < v.array.length; i++) {
		printf("%ls ", v.ptr[i]);
	}

	printf("\n");
}

void main() {
	printf("uso: hello uso.\nuso: using glfw %s.\n", glfwGetVersionString);

	if (!glfwInit()) {
		printf("error: glfwInit()\n");
		return;
	}

	glfwSetErrorCallback(&uso_glfw_error_cb);

	glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 4);
	glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 5);
	glfwWindowHint(GLFW_OPENGL_PROFILE, GLFW_OPENGL_CORE_PROFILE);

	win = glfwCreateWindow(640, 480, "uso!", null, null);
	glfwMakeContextCurrent(win);
	glfwSwapInterval(0);

	const GLSupport support = loadOpenGL();
	if (support == GLSupport.gl45) {
		printf("uso: loaded OpenGL 4.5\n");
	} else {
		printf("uso: unable to load OpenGL 4.5\n");
		goto out1;
	}

	glViewport(0, 0, 640, 480);
	glfwSetFramebufferSizeCallback(win, &uso_fb_size_cb);
	glfwSetWindowCloseCallback(win, &uso_win_close_cb);
	glfwSetKeyCallback(win, &uso_key_cb);
	glfwSetCursorPosCallback(win, &uso_cursor_pos_cb);
	glfwSetMouseButtonCallback(win, &uso_mouse_button_cb);
	glfwSetScrollCallback(win, &uso_scroll_cb);
	glfwSetDropCallback(win, &uso_drop_cb);

	uint shader_program;
	if (!setup_program(shader_program, "source/triangle.v.glsl", "source/triangle.f.glsl")) {
		goto out1;
	}

	/*const float[32] vertices = [
		 0.5f,  0.5f, 0.0f,   1.0f, 0.0f, 0.0f,   1.0f, 1.0f,
		 0.5f, -0.5f, 0.0f,   0.0f, 1.0f, 0.0f,   1.0f, 0.0f,
		-0.5f, -0.5f, 0.0f,   0.0f, 0.0f, 1.0f,   0.0f, 0.0f,
		-0.5f,  0.5f, 0.0f,   0.0f, 1.0f, 0.0f,   0.0f, 1.0f,
	];*/

	float[36 * 5] vertices = [
		-0.5f, -0.5f, -0.5f,  0.0f, 0.0f,
		 0.5f, -0.5f, -0.5f,  1.0f, 0.0f,
		 0.5f,  0.5f, -0.5f,  1.0f, 1.0f,
		 0.5f,  0.5f, -0.5f,  1.0f, 1.0f,
		-0.5f,  0.5f, -0.5f,  0.0f, 1.0f,
		-0.5f, -0.5f, -0.5f,  0.0f, 0.0f,

		-0.5f, -0.5f,  0.5f,  0.0f, 0.0f,
		 0.5f, -0.5f,  0.5f,  1.0f, 0.0f,
		 0.5f,  0.5f,  0.5f,  1.0f, 1.0f,
		 0.5f,  0.5f,  0.5f,  1.0f, 1.0f,
		-0.5f,  0.5f,  0.5f,  0.0f, 1.0f,
		-0.5f, -0.5f,  0.5f,  0.0f, 0.0f,

		-0.5f,  0.5f,  0.5f,  1.0f, 0.0f,
		-0.5f,  0.5f, -0.5f,  1.0f, 1.0f,
		-0.5f, -0.5f, -0.5f,  0.0f, 1.0f,
		-0.5f, -0.5f, -0.5f,  0.0f, 1.0f,
		-0.5f, -0.5f,  0.5f,  0.0f, 0.0f,
		-0.5f,  0.5f,  0.5f,  1.0f, 0.0f,

		 0.5f,  0.5f,  0.5f,  1.0f, 0.0f,
		 0.5f,  0.5f, -0.5f,  1.0f, 1.0f,
		 0.5f, -0.5f, -0.5f,  0.0f, 1.0f,
		 0.5f, -0.5f, -0.5f,  0.0f, 1.0f,
		 0.5f, -0.5f,  0.5f,  0.0f, 0.0f,
		 0.5f,  0.5f,  0.5f,  1.0f, 0.0f,

		-0.5f, -0.5f, -0.5f,  0.0f, 1.0f,
		 0.5f, -0.5f, -0.5f,  1.0f, 1.0f,
		 0.5f, -0.5f,  0.5f,  1.0f, 0.0f,
		 0.5f, -0.5f,  0.5f,  1.0f, 0.0f,
		-0.5f, -0.5f,  0.5f,  0.0f, 0.0f,
		-0.5f, -0.5f, -0.5f,  0.0f, 1.0f,

		-0.5f,  0.5f, -0.5f,  0.0f, 1.0f,
		 0.5f,  0.5f, -0.5f,  1.0f, 1.0f,
		 0.5f,  0.5f,  0.5f,  1.0f, 0.0f,
		 0.5f,  0.5f,  0.5f,  1.0f, 0.0f,
		-0.5f,  0.5f,  0.5f,  0.0f, 0.0f,
		-0.5f,  0.5f, -0.5f,  0.0f, 1.0f
	];

	v3[10] cubes= [
        v3([ 0.0f,  0.0f,  0.0f ]),
        v3([ 2.0f,  5.0f, -15.0f]),
        v3([-1.5f, -2.2f, -2.5f]),
        v3([-3.8f, -2.0f, -12.3f]),
		v3([ 2.4f, -0.4f, -3.5f]),
        v3([-1.7f,  3.0f, -7.5f]),
        v3([ 1.3f, -2.0f, -2.5f]),
        v3([ 1.5f,  2.0f, -2.5f]),
        v3([ 1.5f,  0.2f, -1.5f]),
        v3([-1.3f,  1.0f, -1.5f])
	];

	//const uint[6] indices = [ 0, 1, 3, 1, 2, 3 ];

	stbi_set_flip_vertically_on_load(true);

	int w;
	int h;
	int channels;
	ubyte *egg_data = stbi_load("egg.jpg", &w, &h, &channels, 0);
	if (!egg_data) {
		printf("uso: failed to load image\n.");
		goto out1;
	}

	uint texture1;
	glGenTextures(1, &texture1);
	glActiveTexture(GL_TEXTURE0);
	glBindTexture(GL_TEXTURE_2D, texture1);
	glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB, w, h, 0, GL_RGB, GL_UNSIGNED_BYTE, egg_data);
	stbi_image_free(egg_data);
	glGenerateMipmap(GL_TEXTURE_2D);

	egg_data = stbi_load("miku.png", &w, &h, &channels, 0);
	if (!egg_data) {
		printf("uso: failed to load image miku\n.");
		goto out1;
	}

	uint texture2;
	glGenTextures(1, &texture2);

	glBindTexture(GL_TEXTURE_2D, texture2);
	glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB, w, h, 0, GL_RGBA, GL_UNSIGNED_BYTE, egg_data);
	glGenerateMipmap(GL_TEXTURE_2D);

	uint vao;
	glGenVertexArrays(1, &vao);
	glBindVertexArray(vao);

	uint vbo;
	setup_buffer(&vbo, GL_ARRAY_BUFFER, cast(void*)vertices.ptr, vertices.sizeof, GL_STATIC_DRAW);

	/*uint ebo;
	setup_buffer(&ebo, GL_ELEMENT_ARRAY_BUFFER, cast(void*)indices.ptr, indices.sizeof, GL_STATIC_DRAW);*/

	//info about vertex array
	glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 5 * float.sizeof, cast(void*)0);
	glEnableVertexAttribArray(0);

	glVertexAttribPointer(1, 3, GL_FLOAT, GL_FALSE, 5 * float.sizeof, cast(void*)(3 * float.sizeof));
	glEnableVertexAttribArray(1);

	/*glVertexAttribPointer(2, 2, GL_FLOAT, GL_FALSE, 8 * float.sizeof, cast(void*)(6 * float.sizeof));
	glEnableVertexAttribArray(2);*/

	//unbind stuff
	glBindBuffer(GL_ARRAY_BUFFER, 0);
	glBindVertexArray(0);

	//wireframe;
	//glPolygonMode(GL_FRONT_AND_BACK, GL_LINE);

	//do i need to use this here?
	glUseProgram(shader_program);
	glUniform1i(glGetUniformLocation(shader_program, "texture1"), 0);
	glUniform1i(glGetUniformLocation(shader_program, "texture2"), 1);

	//bind textures
	glActiveTexture(GL_TEXTURE0);
	glBindTexture(GL_TEXTURE_2D, texture1);
	glActiveTexture(GL_TEXTURE1);
	glBindTexture(GL_TEXTURE_2D, texture2);

	//rarely changes
	m4 proj = perspective(radians(45f), 640 / 480, 0.1f, 100f);
	glUniformMatrix4fv(glGetUniformLocation(shader_program, "proj"), 1, GL_FALSE, proj.arr.ptr);

	m4 view = translate(v3([0f, 0f, -3f]));
	glUniformMatrix4fv(glGetUniformLocation(shader_program, "view"), 1, GL_FALSE, view.arr.ptr);
	
	/*m4 trans = scale(v3([ 2f, 2f, 2f ]));
  	trans = rotate(radians(90f), v3([ 0f, 0f, 1f ])) * trans;
	glUniformMatrix4fv(glGetUniformLocation(shader_program, "trans"), 1, GL_FALSE, trans.arr.ptr);*/

	glBindVertexArray(vao);

	glEnable(GL_DEPTH_TEST);

	//should this be here?
	glUseProgram(shader_program);

	enum double fps = 120;
	enum Duration spf = usecs(cast(long)(1_000_000 * 1f / fps));

	while (!glfwWindowShouldClose(win)) {
		const MonoTime start = MonoTime.currTime;

		glClearColor(0.2f, 0.3f, 0.3f, 1.0f);
		glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

		for (uint i = 0; i < 10; i++) {
			m4 model = translate(cubes[i]);
			model = rotate(/*radians(-55f)*/ cast(float)glfwGetTime(), v3([0.5f, 1.0f, 0.0f])) * model;
			glUniformMatrix4fv(glGetUniformLocation(shader_program, "model"), 1, GL_FALSE, model.arr.ptr);
		
			glDrawArrays(GL_TRIANGLES, 0, 36);
		}
		
		//only for indices
		//glDrawElements(GL_TRIANGLES, 36, GL_UNSIGNED_INT, cast(const(void)*)0);

		glfwSwapBuffers(win);

		Duration end = MonoTime.currTime - start;
		if (end < spf) {
			do {
				glfwWaitEventsTimeout(cast(double)(spf - end).total!"usecs" / 1_000_000f);
				end = MonoTime.currTime - start;
			} while(end < spf);
		} else {
			glfwPollEvents();
		}
	}

	glDeleteVertexArrays(1, &vao);
	glDeleteBuffers(1, &vbo);
	//glDeleteBuffers(1, &ebo);

out1:
	glfwDestroyWindow(win);
	glfwTerminate();
	printf("uso: exiting.\n");
	return;
}
