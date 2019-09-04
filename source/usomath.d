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

enum m4 identity = { arr : [ 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1 ] };

static float radians(float degrees) {
    return degrees * (pi32 / 180.0f);
}

static float degrees(float radians) {
    return radians * (180.0f / pi32);
}

union v3 {
    @nogc:
    nothrow:
    
    float4 vec;

    ref float opIndex(const size_t i) {
        assert(i < 3, "failed to index v3");
		return vec[i];
	}

    this(float4 v) {
        this.vec = v;
    }

    void opAssign(v3 v) {
        this.vec = v.vec;
    }

    void opAssign(v4 v) {
        this.vec = v.vec;
    }

    v4 opAdd(v4 v) {
        return v4(this.vec + v.vec);
    }

    v4 opMul_r(float f) {
        return v4(this.vec * f);
    }

    v4 opMul(float f) {
        return v4(this.vec * f);
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

    ref float opIndex(const size_t i) {
		return vec[i];
	}

    v4 opAdd(v4 v) {
        return v4(this.vec + v.vec);
    }

    v4 opMul_r(float f) {
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
    printf("]\n");
}

union m4 {
    @nogc:
    nothrow:

	v4[4] vecs;
	float[16] arr = identity.arr;

	ref v4 opIndex(const size_t i) {
		return vecs[i];
    }

    v4 opMul(v4 v) {
        return (v.x * this.vecs[0] + v.y * this.vecs[1] + v.z * this.vecs[2] + v.w * this.vecs[3]);
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
}

m4 translate(v3 v) {
    m4 ret;
    ret[3] = v;
    return ret;
}

m4 rotate(float a, v3 axis) {

}

void main() {
    printf("running usomath driver.\n\n");

    {
        v4 vec = [ 1.0f, 0.0f, 0.0f, 1.0f ];
        m4 trans = translate(v3([ 1.0f, 1.0f, 0.0f ]));
        vec = trans * vec;
        v4_print(vec);
    }

    {
        m5 trans
    }
}
