import core.simd;
import core.stdc.stdio;
import core.stdc.stdlib;

import std.math;

@nogc:
nothrow:

enum float pi32 = 3.14159265358979323846264338327950288f;
enum double pi64 = 3.14159265358979323846264338327950288;

enum float tau32 = 2.0f * pi32;
enum double tau64 = 2.0 * pi64;

enum m4 identity = [ 1.0f, 0f, 0f, 0f, 0f, 1f, 0f, 0f, 0f, 0f, 1f, 0f, 0f, 0f, 0f, 1f ];

static float radians(float degrees) {
    return degrees * (pi32 / 180.0f);
}

static float degrees(float radians) {
    return radians * (180.0f / pi32);
}

union v2 {
    @nogc:
    nothrow:
    
    float4 vec;
    struct {
        float x;
        float y;
    }

    ref float opIndex(const size_t i) {
        assert(i < 2, "failed to index v3");
		return vec[i];
	}

    this(float4 v) {
        this.vec = v;
    }

    this(float x, float y) {
        this.x = x;
        this.y = y;
    }

    void opAssign(v2 v) {
        this.vec = v.vec;
    }

    void opAssign(v3 v) {
        this.vec = v.vec;
    }

    void opAssign(v4 v) {
        this.vec = v.vec;
    }

    ref v2 opOpAssign(string op)(v2 v) if (op == "+") {
        this.vec += v.vec;
        return this;
    }

    ref v2 opOpAssign(string op)(v2 v) if (op == "-") {
        this.vec -= v.vec;
        return this;
    }

    v2 opAdd(v2 v) {
        return v2(this.vec + v.vec);
    }

    v2 opMul_r(float f) {
        return v2(this.vec * f);
    }

    v2 opMul(float f) {
        return v2(this.vec * f);
    }

    v2 opBinary(string op)(float f) if (op == "/") {
        return v2(this.vec / f);
    }

    v2 opBinary(string op)(v2 v) if (op == "-") {
        return v2(this.vec - v.vec);
    }
}

union v3 {
    @nogc:
    nothrow:
    
    float4 vec;
    struct {
        float x;
        float y;
        float z;
    }

    ref float opIndex(const size_t i) {
        assert(i < 3, "failed to index v3");
		return vec[i];
	}

    this(float4 v) {
        this.vec = v;
    }

    this(float x, float y, float z) {
        this.x = x;
        this.y = y;
        this.z = z;
    }

    void opAssign(v3 v) {
        this.vec = v.vec;
    }

    void opAssign(v4 v) {
        this.vec = v.vec;
    }

    ref v3 opOpAssign(string op)(v3 v) if (op == "+") {
        this.vec += v.vec;
        return this;
    }

    ref v3 opOpAssign(string op)(v3 v) if (op == "-") {
        this.vec -= v.vec;
        return this;
    }

    v3 opAdd(v3 v) {
        return v3(this.vec + v.vec);
    }

    v3 opMul_r(float f) {
        return v3(this.vec * f);
    }

    v3 opMul(float f) {
        return v3(this.vec * f);
    }

    v3 opBinary(string op)(float f) if (op == "/") {
        return v3(this.vec / f);
    }

    v3 opBinary(string op)(v3 v) if (op == "-") {
        return v3(this.vec - v.vec);
    }
}

void v3_print(v3 v) {
    printf("[ ");
    for (uint r = 0; r < 3; r++) {
        printf("%f ", v[r]);
    }
    printf("]\n");
}

union v4 {
    @nogc:
    nothrow:
    
    float4 vec;
    struct {
        float x;
        float y;
        float z;
        float w;
    }

    this(float4 v) {
        this.vec = v;
    }

    void opAssign(v3 v) {
        this.vec[0..3] = v.vec[0..3];
    }

    void opAssign(v4 v) {
        this.vec = v.vec;
    }

    ref v4 opOpAssign(string op)(v3 v) if (op == "+") {
        this.vec[0..3] += v.vec[0..3];
        return this;
    }

    ref v4 opOpAssign(string op)(v4 v) if (op == "+") {
        this.vec += v.vec;
        return this;
    }

    ref float opIndex(const size_t i) {
		return vec[i];
	}

    v4 opAdd(v4 v) {
        return v4(this.vec + v.vec);
    }

    v4 opBinary(string op)(float f) if (op == "*") {
        return v4(this.vec * f);
    }

    v4 opMul(float f) {
        return v4(this.vec * f);
    }
}

void v4_print(v4 v) {
    printf("[ ");
    for (uint r = 0; r < 4; r++) {
        printf("%0.2f ", v[r]);
    }
    printf("]\n\n");
}

union m4 {
    @nogc:
    nothrow:

	v4[4] vecs;
	float[16] arr;

    this(float v) {
        this.arr = v;
    }

    this(float[16] a) {
        this.arr = a;
    }

    this(m4 m) {
        this.arr = m.arr;
    }

	ref v4 opIndex(const size_t i) {
		return vecs[i];
    }

    v4 opBinary(string op)(v4 v) if (op == "*") {
        return (v.x * this.vecs[0] + v.y * this.vecs[1] + v.z * this.vecs[2] + v.w * this.vecs[3]);
    }

    m4 opBinary(string op)(m4 r) if (op == "*") {
        m4 ret;
        for (uint i = 0; i < 4; i++) {
            ret.vecs[i] = 
                    ((r[i][0] * this.vecs[0]) + (r[i][1] * this.vecs[1])) +
                    ((r[i][2] * this.vecs[2]) + (r[i][3] * this.vecs[3]));
        }
        return ret;
    }
}

void m4_print(m4 m) {
    for (uint c = 0; c < 4; c++) {
        printf("[ ");
        for (uint r = 0; r < 4; r++) {
            printf("%0.2f ", m[c][r]);
        }
        printf("]\n");
    }
    printf("\n");
}

m4 translate(v3 v) {
    m4 ret = identity;
    ret[3] += v;
    return ret;
}

float dot(v3 l, v3 r) {
    return l.x * r.x + l.y * r.y + l.z * r.z;
}

float lensq(v3 v) {
    return dot(v, v);
}

float len(v3 v) {
    return sqrt(lensq(v));
}

v3 cross(v3 l, v3 r) {
    return v3(l.y * r.z - l.z *r.y, l.z * r.x - l.x * r.z, l.x * r.y - l.y * r.x);
}

v3 norm(v3 v) {
    return v / len(v);
}

m4 rotate(float a, v3 axis) {
    const float s = sin(a);
    const float c = cos(a);

    axis = norm(axis);

    v3 temp = axis * (1.0f - c);

    m4 ret = identity;
    ret[0][0] = c + temp[0] * axis[0];
	ret[0][1] = temp[0] * axis[1] + s * axis[2];
	ret[0][2] = temp[0] * axis[2] - s * axis[1];
	ret[1][0] = temp[1] * axis[0] - s * axis[2];
	ret[1][1] = c + temp[1] * axis[1];
	ret[1][2] = temp[1] * axis[2] + s * axis[0];
	ret[2][0] = temp[2] * axis[0] + s * axis[1];
	ret[2][1] = temp[2] * axis[1] - s * axis[0];
	ret[2][2] = c + temp[2] * axis[2];

    return ret;
}

m4 scale(v3 s) {
    m4 ret = identity;
    ret[0][0] = s.x;
    ret[1][1] = s.y;
    ret[2][2] = s.z;

    return ret;
}

m4 perspective(float fovy, float aspect, float z_near, float z_far) {
    const float t = tan(fovy / 2.0f);

    m4 ret = 0;
    ret[0][0] = 1.0f / (aspect * t);
    ret[1][1] = 1.0f / t;
    ret[2][2] = - (z_far + z_near) / (z_far / z_near);
    ret[2][3] = - 1.0f;
    ret[3][2] = - (2.0f * z_far * z_near) / (z_far / z_near);

    return ret;
}

m4 look_at(v3 pos, v3 at, v3 up) {
    v3 f = norm(at - pos);
    v3 s = norm(cross(f, up));
    v3 u = cross(s, f);

    m4 ret = 0f;
    ret[0][0] = s.x;
    ret[0][1] = u.x;
    ret[0][2] = - f.x;
    ret[1][0] = s.y;
    ret[1][1] = u.y;
    ret[1][2] = - f.y;
    ret[2][0] = s.z;
    ret[2][1] = u.z;
    ret[2][2] = - f.z;
    ret[3][0] = - dot(s, pos);
    ret[3][1] = - dot(u, pos);
    ret[3][2] = dot(f, pos);
    ret[3][3] = 1.0f;

    return ret;
}

import core.stdc.stdlib;
import core.stdc.string;

bool bez(ref v2 res, v2* points, uint len, float t) {
    enum uint len_max = 256;
    if (len >= len_max) {
        printf("uso: too many points in curve.\n");
        return false;
    }
    
    v2[len_max] tmp;
    memcpy(tmp.ptr, points, len * v2.sizeof);

    for (uint i = len - 1; i > 0; i--) {
        for (uint k = 0; k < i; k++) {
            tmp[k] = tmp[k] + t * (tmp[k+1] - tmp[k]);
        }
    }

    res = tmp[0];
    return true;
}

void main() {
    v2[3] points = [ v2(0f, 1f), v2(0f, 0f), v2(1f, 0f) ];

    for (float i = 0; i < 1.1; i+= .1f) {
        v2 res;
        if (!bez(res, points.ptr, points.length, i)) {
            return;
        }
        printf("%f %f\n", res.x, res.y);
    }
}