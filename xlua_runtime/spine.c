#include <string.h>
#include <stdlib.h>
#include <assert.h>

#ifdef __cplusplus
extern "C" {
#endif

#include "lua.h"
#include "lauxlib.h"
#include "lualib.h"

typedef struct {
    const unsigned char* start;
    const unsigned char* cursor; 
    const unsigned char* end;
} _dataInput;

LUALIB_API  _dataInput * sp_newInput(const unsigned char * ptr, long len) {
    _dataInput * input = malloc(sizeof(_dataInput));
    input->start  = ptr;
    input->cursor = ptr;
    input->end    = ptr + len;
    return input;
}

LUALIB_API  void sp_inputSetPosition(_dataInput * input, long position) {
    input->cursor = input->start + position;
}

LUALIB_API  long sp_inputGetPosition(_dataInput * input) {
    return (long)(input->cursor - input->start);
}

LUALIB_API void sp_freeInput(_dataInput * input) {
    free(input);
}

LUALIB_API int sp_readByte (_dataInput* input) {
    return *input->cursor++;
}

LUALIB_API signed char sp_readSByte (_dataInput* input) {
    return (signed char)sp_readByte(input);
}

LUALIB_API int sp_readBoolean (_dataInput* input) {
    return sp_readByte(input) != 0;
}

LUALIB_API int sp_readInt (_dataInput* input) {
    int result = sp_readByte(input);
    result <<= 8;
    result |= sp_readByte(input);
    result <<= 8;
    result |= sp_readByte(input);
    result <<= 8;
    result |= sp_readByte(input);
    return result;
}

LUALIB_API int sp_readVarint (_dataInput* input, int/*bool*/optimizePositive) {
    unsigned char b = sp_readByte(input);
    int value = b & 0x7F;
    if (b & 0x80) {
        b = sp_readByte(input);
        value |= (b & 0x7F) << 7;
        if (b & 0x80) {
                b = sp_readByte(input);
                value |= (b & 0x7F) << 14;
                if (b & 0x80) {
                    b = sp_readByte(input);
                    value |= (b & 0x7F) << 21;
                    if (b & 0x80) value |= (sp_readByte(input) & 0x7F) << 28;
                }
        }
    }
    if (!optimizePositive) value = (((unsigned int)value >> 1) ^ -(value & 1));
    return value;
}

LUALIB_API float sp_readFloat (_dataInput* input) {
    union {
        int intValue;
        float floatValue;
    } intToFloat;
    intToFloat.intValue = sp_readInt(input);
    return intToFloat.floatValue;
}

LUALIB_API char* sp_readString (_dataInput* input, int * len) {
    int length = sp_readVarint(input, 1);
    // char* string;
    static char string[512];
    if (length == 0) {
        *len = 0;
        return 0;
    }

    assert(length < 512);
    memcpy(string, input->cursor, length - 1);
    input->cursor += length - 1;
    string[length - 1] = '\0';
    *len = length;
    return string;
}

LUALIB_API void sp_readColor (_dataInput* input, float *r, float *g, float *b, float *a) {
    *r = sp_readByte(input) / 255.0f;
    *g = sp_readByte(input) / 255.0f;
    *b = sp_readByte(input) / 255.0f;
    *a = sp_readByte(input) / 255.0f;
}

#define CURVE_LINEAR 0
#define CURVE_STEPPED 1
#define CURVE_BEZIER 2

static const int BEZIER_SIZE = 10 * 2 - 1;

static void spCurveTimeline_setCurve (float * curves, int frameIndex, float cx1, float cy1, float cx2, float cy2) {
    float tmpx = (-cx1 * 2 + cx2) * 0.03f, tmpy = (-cy1 * 2 + cy2) * 0.03f;
    float dddfx = ((cx1 - cx2) * 3 + 1) * 0.006f, dddfy = ((cy1 - cy2) * 3 + 1) * 0.006f;
    float ddfx = tmpx * 2 + dddfx, ddfy = tmpy * 2 + dddfy;
    float dfx = cx1 * 0.3f + tmpx + dddfx * 0.16666667f, dfy = cy1 * 0.3f + tmpy + dddfy * 0.16666667f;
    float x = dfx, y = dfy;

    int i = frameIndex * BEZIER_SIZE, n = i + BEZIER_SIZE - 1;
    curves[i++] = CURVE_BEZIER;

    for (; i < n; i += 2) {
        curves[i] = x;
        curves[i + 1] = y;
        dfx += ddfx;
        dfy += ddfy;
        ddfx += dddfx;
        ddfy += dddfy;
        x += dfx;
        y += dfy;
    }
}

LUALIB_API void sp_readCurve (_dataInput* input, int frameIndex, float * curves) {
    switch (sp_readByte(input)) {
        case CURVE_STEPPED:
            curves[frameIndex * BEZIER_SIZE] = CURVE_STEPPED;
            break;
        case CURVE_BEZIER: {
            float cx1 = sp_readFloat(input);
            float cy1 = sp_readFloat(input);
            float cx2 = sp_readFloat(input);
            float cy2 = sp_readFloat(input);
            spCurveTimeline_setCurve(curves, frameIndex, cx1, cy1, cx2, cy2);
            break;
		}
    }
}

LUALIB_API void sp_readFloatArray(_dataInput* input, float * array, int start, int end, float scale) {
    int i;
    for (i = start; i < end; i++) {
        array[i] = sp_readFloat(input) * scale;
    }
}

#ifdef __cplusplus
}
#endif

