import core.stdc.stdio;
import core.time;

import std.math;

import usomath;

@nogc:
nothrow:

enum cam_dir {
    forward,
    backward,
    left,
    right,
    up,
    down
};

v3 pos = v3(0f, 0f, -1f);
v3 front = v3(0f, 0f, 1f,);
v3 up = v3(0f, 1f, 0f);
v3 right = v3(0f, 0f, 0f);
v3 abs_up = v3(0f, 1f, 0f);

float yaw = 90f;
float pitch = 0f;

float speed = 5f;
float sens = 0.1f;
float zoom = 45f;

void cam_move(cam_dir dir, float dt) {
    float vel = speed * dt;
    final switch(dir) {
        case cam_dir.forward:
            pos += front * vel;
            break;
        case cam_dir.backward:
            pos -= front * vel;
            break;
        case cam_dir.left:
            pos -= right * vel;
            break;
        case cam_dir.right:
            pos += right * vel;
            break;
        case cam_dir.up:
            pos += up * vel;
            break;
        case cam_dir.down:
            pos -= up * vel;
            break;
    }
}

void cam_look(float xoff, float yoff) {
    yaw += xoff * sens;
    pitch -= yoff * sens;

    if (yaw > 360f) {
        yaw %= 360f;
    } else if (yaw < -360f) {
        yaw %= 360f;
    }

    if (pitch > 89f) {
        pitch = 89f;
    } else if (pitch < - 89f) {
        pitch = - 89f;
    }

    cam_update();
}

void cam_zoom(float z) {
    if (zoom >= 1f && zoom <= 45f) {
        zoom -= z;
    }
    if (zoom <= 1f) {
        zoom = 1f;
    }
    if (zoom >= 45f) {
        zoom = 45f;
    }
}

void cam_update() {
    front.x = cos(radians(pitch)) * cos(radians(yaw));
    front.y = sin(radians(pitch));
    front.z = sin(radians(yaw)) * cos(radians(pitch));
    
    front = norm(front);
    right = norm(cross(front, v3(0, 1, 0)));
    up = norm(cross(right, front));
}