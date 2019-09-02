import core.stdc.stdio;
import core.thread;
import core.time;

import bindbc.glfw;
import bindbc.opengl;

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

bool setup_shader(const char *name, GLenum type, const char *src, uint *shader) {
	const uint loc = glCreateShader(type);
	*shader = loc;
	glShaderSource(loc, 1, &src, null);
	glCompileShader(loc);

	int success;
	glGetShaderiv(loc, GL_COMPILE_STATUS, &success);
	if (!success) {
		char[512] info;
		glGetShaderInfoLog(loc, 512, null, info.ptr);
		printf("uso: failed to compile %s shader: %512s\n", name, info.ptr);
		return true;
	}
	return false;
}

void setup_buffer(GLuint* bo, GLenum type, void* data, size_t len, GLenum usage) {
	glGenBuffers(1, bo);
	glBindBuffer(type, *bo);
	glBufferData(type, len, data, usage);
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

	const char *vertex_shader_src = 
		"#version 450 core\n
		layout (location = 0) in vec3 aPos;\n
		void main(){\n
			gl_Position = vec4(aPos.x, aPos.y, aPos.z, 1.0);\n
		}\0";

	const char *fragment_shader_src =
		"#version 450 core\n
		out vec4 FragColor;\n
		void main(){\n
			FragColor = vec4(1.0f, 0.5f, 0.2f, 1.0f);\n
		}\0";

	uint vertex_shader;
	if (setup_shader("vertex", GL_VERTEX_SHADER, vertex_shader_src, &vertex_shader)) {
		goto out1;
	}

	uint fragment_shader;
	if (setup_shader("fragment", GL_FRAGMENT_SHADER, fragment_shader_src, &fragment_shader)) {
		goto out1;
	}
	
	const uint shader_program = glCreateProgram();
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
		goto out1;
	}

	const float[12] vertices = [ .5f, .5f, 0f, .5f, -.5f, 0f, -.5f, -.5f, 0f, -.5f, .5f, 0f ];
	const uint[6] indices = [ 0, 1, 3, 1, 2, 3 ];

	uint vao;
	glGenVertexArrays(1, &vao);
	glBindVertexArray(vao);

	uint vbo;
	setup_buffer(&vbo, GL_ARRAY_BUFFER, cast(void*)vertices.ptr, vertices.sizeof, GL_STATIC_DRAW);

	uint ebo;
	setup_buffer(&ebo, GL_ELEMENT_ARRAY_BUFFER, cast(void*)indices.ptr, indices.sizeof, GL_STATIC_DRAW);

	//info about vertex array
	glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 3 * float.sizeof, cast(void*)0);
	glEnableVertexAttribArray(0);

	//unbind stuff
	glBindBuffer(GL_ARRAY_BUFFER, 0);
	glBindVertexArray(0);

	enum double fps = 60;
	enum Duration spf = usecs(cast(long)(1_000_000 * 1f / fps));
	while (!glfwWindowShouldClose(win)) {
		const MonoTime start = MonoTime.currTime;

		glfwPollEvents();

		glClearColor(0.2f, 0.3f, 0.3f, 1.0f);
		glClear(GL_COLOR_BUFFER_BIT);

		glUseProgram(shader_program);
		glBindVertexArray(vao);
		glDrawElements(GL_TRIANGLES, 6, GL_UNSIGNED_INT, cast(const(void)*)0);

		glfwSwapBuffers(win);

		Duration end;
		do {
			end = MonoTime.currTime - start;
			glfwWaitEventsTimeout((cast(double)spf.total!"usecs" - cast(double)end.total!"usecs") / 1_000_000f);
			printf("proc\n");
		} while(spf >= end);
		printf("frame\n");
	}

	glDeleteVertexArrays(1, &vao);
	glDeleteBuffers(1, &vbo);
	glDeleteBuffers(1, &ebo);

out1:
	glfwDestroyWindow(win);
	glfwTerminate();
	printf("uso: exiting.\n");
	return;
}
