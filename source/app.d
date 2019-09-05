import core.stdc.stdio;
import core.stdc.stdlib;
import core.thread;
import core.time;
import core.simd;

import std.math;

import bindbc.glfw;
import bindbc.opengl;

import stb.image.binding;

import usomath;
import camera;

nothrow:
@nogc:

GLFWwindow* win;

uint win_w = 640;
uint win_h = 480;

export bool NvOptimusEnablement = true;
export bool AmdPowerXPressRequestHighPerformance = true;

extern (C) void uso_glfw_error_cb(int code, const(char)* dsc) {
	printf("uso: glfw error:\n\terror code: %d\n\terror desc: %s\n", code, dsc);
}

extern (C) void uso_win_close_cb(GLFWwindow* win) {
	printf("uso: closed window.\n");
}

double lastx = 0f;
double lasty = 0f;

extern (C) void uso_cursor_enter_cb(GLFWwindow* win, int entered) {
	/*if (entered) {
		//glfwGetCursorPos(win, &lastx, &lasty);
		printf("entered\n");
	}*/
}

bool paused = true;

extern (C) void uso_cursor_pos_cb(GLFWwindow* win, double x, double y) {
	//printf("uso: cursor pos:\n\tx: %lf\n\tf: %lf\n", x, y);
	if (!paused) {
		cam_look(x - lastx, y - lasty);
		lastx = x;
		lasty = y;
	}
}

extern (C) void uso_mouse_button_cb(GLFWwindow* win, int button, int action, int mods) {
	//printf("uso: mouse button:\n\tbutton: %d\n\taction: %d\n\tmods: %d\n", button, action, mods);

	uso_try_unpause();
}

extern (C) void uso_scroll_cb(GLFWwindow* win, double xoff, double yoff) {
	//printf("uso: scroll:\n\txoff: %lf\n\tyoff: %lf\n", xoff, yoff);
	if (!paused) {
		cam_zoom(yoff);
	}
}

extern (C) void uso_fb_size_cb(GLFWwindow* win, int width, int height) {
	win_w = width;
	win_h = height;
	glViewport(0, 0, width, height);
}

extern (C) void uso_drop_cb(GLFWwindow* win, int count, const char** paths) {
	printf("uso: drop:\n\tcount: %d\n", count);
	for (uint i = 0; i < count; i++) {
		printf("\tpath %d: %s\n", i, paths[i]);
	}
}

void uso_pause() {
	glfwSetInputMode(win, GLFW_CURSOR, GLFW_CURSOR_NORMAL);
	paused = true;
}

void uso_unpause() {
	glfwGetCursorPos(win, &lastx, &lasty);
	//printf("%f %f\n", lastx, lasty);
	glfwSetInputMode(win, GLFW_CURSOR, GLFW_CURSOR_DISABLED);
	paused = false;
}

void uso_try_pause() {
	if (!paused) {
		uso_pause();
	}
}

void uso_try_unpause() {
	if (paused) {
		uso_unpause();
	}
}

void uso_toggle_pause() {
	if (paused) {
		uso_unpause();
	} else {
		uso_pause();
	} 
}

extern (C) void uso_key_cb(GLFWwindow* win, int key, int scancode, int action, int mods) {
	//GLFW_PRESS GLFW_RELEASE GLFW_REPEAT
	//GLFW_KEY_UNKNOWN
	//printf("uso: keyboard:\n\tkey: %d\n\tscancode: %d\n\taction: %d\n\tmods: %d\n", key, scancode, action, mods);
	if (key == GLFW_KEY_ESCAPE && action == GLFW_PRESS) {
		uso_toggle_pause();
	}
}

void uso_keyboard(float dt) {
	if (glfwGetKey(win, GLFW_KEY_W) == GLFW_PRESS) {
		cam_move(cam_dir.forward, dt);
	}
	if (glfwGetKey(win, GLFW_KEY_S) == GLFW_PRESS) {
		cam_move(cam_dir.backward, dt);
	}
	if (glfwGetKey(win, GLFW_KEY_A) == GLFW_PRESS) {
		cam_move(cam_dir.left, dt);
	}
	if (glfwGetKey(win, GLFW_KEY_D) == GLFW_PRESS) {
		cam_move(cam_dir.right, dt);
	}
	if (glfwGetKey(win, GLFW_KEY_SPACE) == GLFW_PRESS) {
		cam_move(cam_dir.up, dt);
	}
	if (glfwGetKey(win, GLFW_KEY_LSHIFT) == GLFW_PRESS) {
		cam_move(cam_dir.down, dt);
	}
}

bool setup_shader(ref uint shader, const char *fname, GLenum type) {
	enum size_t buf_max = 1024;

	FILE* fp = fopen(fname, "r");
	if (fp == null) {
		printf("uso: unable to open shader file %s.\n", fname);
		return false;
	}

	char[buf_max] buf;
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

bool setup_texture(ref uint t, const char* fname, GLenum mode) {
	int w;
	int h;
	int channels;
	ubyte *data = stbi_load(fname, &w, &h, &channels, 0);
	if (!data) {
		printf("uso: failed to load image %s\n.", fname);
		return false;
	}

	glGenTextures(1, &t);
	glBindTexture(GL_TEXTURE_2D, t);

	glTexImage2D(GL_TEXTURE_2D, 0, GL_RGB, w, h, 0, mode, GL_UNSIGNED_BYTE, data);
	stbi_image_free(data);
	glGenerateMipmap(GL_TEXTURE_2D);

	return true;
}

void main() {
	printf("uso: hello uso.\nuso: using glfw %s.\n", glfwGetVersionString);

	if (!glfwInit()) {
		printf("error: glfwInit()\n");
		return;
	}

	scope(exit) {
		glfwDestroyWindow(win);
		glfwTerminate();
		printf("uso: exiting.\n");
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
		return;
	}

	glViewport(0, 0, 640, 480);
	glfwSetFramebufferSizeCallback(win, &uso_fb_size_cb);
	glfwSetWindowCloseCallback(win, &uso_win_close_cb);
	glfwSetKeyCallback(win, &uso_key_cb);
	glfwSetCursorPosCallback(win, &uso_cursor_pos_cb);
	glfwSetCursorEnterCallback(win, &uso_cursor_enter_cb);
	glfwSetMouseButtonCallback(win, &uso_mouse_button_cb);
	glfwSetScrollCallback(win, &uso_scroll_cb);
	glfwSetDropCallback(win, &uso_drop_cb);

	uint shader_program;
	if (!setup_program(shader_program, "source/triangle.v.glsl", "source/triangle.f.glsl")) {
		return;
	}

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

	v3[9] cubes = [
        v3( 0f,  0f,  0f),
        v3( 3f,  3f,  3f),
		v3(-3f,  3f,  3f),
		v3( 3f, -3f,  3f),
		v3(-3f, -3f,  3f),
		v3( 3f,  3f, -3f),
		v3(-3f,  3f, -3f),
		v3( 3f, -3f, -3f),
		v3(-3f, -3f, -3f)
	];

	stbi_set_flip_vertically_on_load(true);

	uint texture1;
	if (!setup_texture(texture1, "egg.jpg", GL_RGB)) {
		return;
	}

	uint texture2;
	if (!setup_texture(texture2, "miku.png", GL_RGBA)) {
		return;
	}

	uint vao;
	glGenVertexArrays(1, &vao);
	glBindVertexArray(vao);

	uint vbo;
	setup_buffer(&vbo, GL_ARRAY_BUFFER, cast(void*)vertices.ptr, vertices.sizeof, GL_STATIC_DRAW);

	scope(exit) {
		glDeleteVertexArrays(1, &vao);
		glDeleteBuffers(1, &vbo);
	}

	glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 5 * float.sizeof, cast(void*)0);
	glEnableVertexAttribArray(0);

	glVertexAttribPointer(1, 2, GL_FLOAT, GL_FALSE, 5 * float.sizeof, cast(void*)(3 * float.sizeof));
	glEnableVertexAttribArray(1);

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

	glBindVertexArray(vao);

	glEnable(GL_DEPTH_TEST);

	//should this be here?
	glUseProgram(shader_program);

	enum double fps = 120;
	enum Duration spf = usecs(cast(long)(1_000_000 * 1f / fps));
	
	MonoTime lf = MonoTime.currTime;
	while (!glfwWindowShouldClose(win)) {
		const MonoTime start = MonoTime.currTime;
		const Duration dt = start - lf;
		lf = start;

		uso_keyboard(dt.total!"usecs" / 1_000_000f);

		glClearColor(0.2f, 0.3f, 0.3f, 1.0f);
		glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

		m4 proj = perspective(radians(camera.zoom), win_w / win_h, 0.1f, 100f);
		glUniformMatrix4fv(glGetUniformLocation(shader_program, "proj"), 1, GL_FALSE, proj.arr.ptr);

		m4 view = look_at(camera.pos, camera.pos + camera.front, camera.up);
		glUniformMatrix4fv(glGetUniformLocation(shader_program, "view"), 1, GL_FALSE, view.arr.ptr);

		for (uint i = 0; i < cubes.length; i++) {
			m4 model = rotate(2f * cast(float)glfwGetTime(), v3([0.5f, 1.0f, 0.0f]));
			model = translate(cubes[i]) * model;
			glUniformMatrix4fv(glGetUniformLocation(shader_program, "model"), 1, GL_FALSE, model.arr.ptr);

			glDrawArrays(GL_TRIANGLES, 0, 36);
		}

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
}
