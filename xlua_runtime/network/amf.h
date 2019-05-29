#ifndef _A_GAME_COMM_AMF_H_
#define _A_GAME_COMM_AMF_H_

#include <stdlib.h>
#include <stdint.h>
#include <stdio.h>

#include "buffer.h"

#ifdef __cplusplus
extern "C" {
#endif
//using  namespace std;


struct amf_slice {
	void * buffer;
	size_t len;
};

#define AMF_INTEGER_MAX 0x1FFFFFFF

enum amf_type {
	amf_undefine = 0x00,
	amf_null = 0x01,
	amf_false = 0x02,
	amf_true = 0x03,
	amf_integer = 0x04,
	amf_double = 0x05,
	amf_string = 0x06,
	amf_xml_doc = 0x07,
	amf_date = 0x08,
	amf_array = 0x09,
	amf_object = 0x0A,
	amf_xml = 0x0B,
	amf_byte_array = 0x0C,
	amf_sinteger = 0x0D
};


typedef  enum amf_type  AMF_TYPE ;

enum amf_type amf_next_type(const char * data, size_t len);

// encode
size_t amf_encode_undefine(struct buffer * buffer);
size_t amf_encode_null(struct buffer * buffer);
size_t amf_encode_false(struct buffer * buffer);
size_t amf_encode_true(struct buffer * buffer);
size_t amf_encode_integer(struct buffer * buffer, uint32_t integer);
size_t amf_encode_sinteger(struct buffer * buffer, int32_t integer);
size_t amf_encode_double(struct buffer * buffer, double d);
size_t amf_encode_string(struct buffer * buffer, const char * string, size_t sz);
size_t amf_encode_array(struct buffer * buffer, size_t size);
size_t amf_encode_byte_array(struct buffer * buffer, const char * ptr, size_t sz);

// decode
size_t amf_decode_double(const char * data, size_t len, double * d);
size_t amf_decode_integer(const char * data, size_t len, uint32_t * v);
size_t amf_decode_sinteger(const char * data, size_t len, int32_t * v);
size_t amf_decode_string(const char * data, size_t len, struct amf_slice * slice);
size_t amf_decode_undefine(const char * data, size_t dlen);
size_t amf_decode_null(const char * data, size_t dlen);
size_t amf_decode_false(const char * data, size_t dlen);
size_t amf_decode_true(const char * data, size_t dlen);
size_t amf_decode_array(const char * data, size_t len, size_t * sz);
size_t amf_decode_byte_array(const char * data, size_t len, struct amf_slice * slice);


#ifdef __cplusplus
}
#endif

    
#endif
