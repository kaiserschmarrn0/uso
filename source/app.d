import core.stdc.stdio;
import bindbc.glfw;
import bindbc.opengl;

nothrow:

extern (C) void uso_glfw_error_cb(int code, const(char)* dsc) {
	printf("uso: glfw error:\n\terror code: %d\n\terror desc: %s\n", code, dsc);
}

extern (C) void uso_win_close_cb(GLFWwindow *win) {
	printf("uso: closed window.\n");
}

extern (C) void uso_key_cb(GLFWwindow *win, int key, int scancode, int action, int mods) {
	//GLFW_PRESS GLFW_RELEASE GLFW_REPEAT
	//GLFW_KEY_UNKNOWN
	printf("uso: keyboard:\n\tkey: %d\n\tscancode: %d\n\taction: %d\n\tmods: %d\n", key, scancode, action, mods);
}

extern (C) void uso_cursor_pos_cb(GLFWwindow *win, double x, double y) {
	//printf("uso: cursor pos:\n\tx: %lf\n\tf: %lf\n", x, y);
}

extern (C) void uso_mouse_button_cb(GLFWwindow *win, int button, int action, int mods) {
	printf("uso: mouse button:\n\tbutton: %d\n\taction: %d\n\tmods: %d\n", button, action, mods);
}

extern (C) void uso_scroll_cb(GLFWwindow *win, double xoff, double yoff) {
	printf("uso: scroll:\n\txoff: %lf\n\tyoff: %lf\n", xoff, yoff);
}

extern (C) void uso_drop_cb(GLFWwindow *win, int count, const char** paths) {
	printf("uso: drop:\n\tcount: %d\n", count);
	for (uint i = 0; i < count; i++) {
		printf("\tpath %d: %s\n", i, paths[i]);
	}
}

extern (C) void main() {
	printf("uso: hello uso.\nuso: using glfw %s.\n", glfwGetVersionString);

	if (!glfwInit()) {
		printf("error: glfwInit()\n");
		return;
	}

	glfwSetErrorCallback(&uso_glfw_error_cb);

	GLFWwindow* win = glfwCreateWindow(640, 480, "uso!", null, null);
	glfwMakeContextCurrent(win);
	glfwSwapInterval(0);

	glfwSetWindowCloseCallback(win, &uso_win_close_cb);
	glfwSetKeyCallback(win, &uso_key_cb);
	glfwSetCursorPosCallback(win, &uso_cursor_pos_cb);
	glfwSetMouseButtonCallback(win, &uso_mouse_button_cb);
	glfwSetScrollCallback(win, &uso_scroll_cb);
	glfwSetDropCallback(win, &uso_drop_cb);

	const GLSupport retVal = loadOpenGL();
	if (retVal == GLSupport.gl46) {
		printf("uso: loaded OpenGL 4.6\n");
	} else {
		printf("uso: unable to load OpenGL 4.6\n");
		goto out1;
	}

	enum double spf = 1f / 60f;
	while (!glfwWindowShouldClose(win)) {
		glfwPollEvents();

		glfwSwapBuffers(win);
	}

out1:
	glfwDestroyWindow(win);

	glfwTerminate();

	printf("uso: exiting.\n");

	return;
}