#include <assert.h>
#include <stdint.h>
#include <string.h>

#include "amf.h"
#include "buffer.h"

#define DATA_POP(l, c) do { if(len < l) return 0; data += (l); (c) += (l), len -= (l); } while(0)

enum amf_type amf_next_type(const char * data, size_t len)
{
	if (len == 0) {return amf_undefine;}

	return (enum amf_type)data[0];
}


// signed int -> uint29
static uint32_t S2UInt29(int32_t i) 
{
	uint32_t ui = i;

 	if (i > 0xFFFFFFF || i < -0x10000000) {
		assert(0 && "out of range");
	}

	ui = (ui&0xFFFFFFF) | (ui & 0x80000000 >> 3);
	return ui;
}

// uint29 -> signed int
static int32_t U2SInt29(uint32_t i) 
{
	if (i > 0x1FFFFFFF) {
		assert(0 && "out of range");
	}
	if ((i&0x10000000) != 0) {
		return (int32_t)(i|0xFF000000);
	}
	return (int32_t)i;
}

#define BEGIN_CHECK size_t __osize = _agB_size(buffer); 
#define END_CHECK(n) assert((_agB_size(buffer) - __osize) == n);

static size_t amf_encode_u29(struct buffer * buffer, uint32_t val)
{
	BEGIN_CHECK

	size_t n = 0;
	char data[4];
	if (val <= 0x0000007F) {
		data[0] = val & 0x7F;;
		n = 1;
	} else if (val <= 0x00003FFF) {
		data[0] = (val >>7)|0x80;
		data[1] = (val & 0x7F);
		n = 2;
	} else if (val <= 0x001FFFFF) {
		data[0] = (val>>14 | 0x80);
		data[1] = (((val>>7)&0x7F)|0x80);
		data[2] = (val&0x7F);
		n = 3;
	} else if (val <= 0x1FFFFFFF) {
		data[0] = ((val>>22)|0x80);
		data[1] = (((val>>15)&0x7F)|0x80);
		data[2] = (((val>>8)&0x7F)|0x80);
		data[3] = val & 0xFF;
		n = 4;
	} else {
		assert(0 && "out of range");
	}


	_agB_write(buffer, data, n);


	END_CHECK(n);

	return n;
}

static size_t amf_encode_i29(struct buffer * buffer, int32_t val)
{
	uint32_t un;
	if (val >= AMF_INTEGER_MAX || val <= -AMF_INTEGER_MAX) {
		return amf_encode_double(buffer, val);
	} else {
		un = S2UInt29(val);
		un = (un&0xFFFFFFF) | ((un&0x80000000) >> 3);
		return amf_encode_u29(buffer, un);
	}
}

#define log(...) //printf

size_t amf_encode_array(struct buffer * buffer, size_t size)
{
	BEGIN_CHECK

	size_t n = 0;
	//type
	_agB_putc(buffer, amf_array);
	n += 1;

	//size
	size <<= 1;
	size |= 1;
	n += amf_encode_u29(buffer, (uint32_t)size);

	//name
	_agB_putc(buffer, 0x01);
	n += 1;

	END_CHECK(n);

	return n;
}

static size_t amf_encode_integer_with_type(struct buffer * buffer, uint32_t integer, enum amf_type type)
{
	assert(type == amf_integer || type == amf_sinteger);

	if (integer > AMF_INTEGER_MAX) {
		return amf_encode_double(buffer, integer);
	}

	BEGIN_CHECK

	size_t n = 0;
	//type
	_agB_putc(buffer, type);
	n += 1;

	//value
	n += amf_encode_u29(buffer, integer);

	END_CHECK(n);

	return n;
}

size_t amf_encode_integer(struct buffer * buffer, uint32_t integer)
{
	return amf_encode_integer_with_type(buffer, integer, amf_integer);
}

size_t amf_encode_sinteger(struct buffer * buffer, int32_t integer)
{
	uint32_t u = S2UInt29(integer);

	((void)amf_encode_i29);
	return amf_encode_integer_with_type(buffer, u, amf_sinteger);
}

size_t amf_encode_double(struct buffer * buffer, double d)
{
	log("amf_encode_double %f\n", d);

	BEGIN_CHECK

	//type
	_agB_putc(buffer, amf_double);

	char * data = (char*)_agB_buffer(buffer, 8);

	char * ptr = (char*)&d;
	data[7] = ptr[0];
	data[6] = ptr[1];
	data[5] = ptr[2];
	data[4] = ptr[3];
	data[3] = ptr[4];
	data[2] = ptr[5];
	data[1] = ptr[6];
	data[0] = ptr[7];

	END_CHECK(9)

	return 9;
}

size_t amf_encode_string(struct buffer * buffer, const char * string, size_t str_len)
{
	size_t e_len;
	size_t n = 0;

	BEGIN_CHECK

	if (str_len == 0) str_len = strlen(string);

	log("amf_encode_stirng %zu\n", str_len);

	//type
	_agB_putc(buffer, amf_string);
	n += 1;

	//size
	e_len = (str_len << 1) | 1;
	n += amf_encode_u29(buffer, (uint32_t)e_len);

	// str
	_agB_write(buffer, string, str_len);
	n += str_len;

	END_CHECK(n)

	return n;
}

size_t amf_encode_byte_array(struct buffer * buffer, const char * ptr, size_t sz)
{
	size_t e_len, n = 0;

	BEGIN_CHECK

	log("amf_encode_byte_array %zu\n", sz);

	//type
	_agB_putc(buffer, amf_byte_array);
	n += 1;

	//size
	e_len = (sz << 1) | 1;
	n += amf_encode_u29(buffer, (uint32_t)e_len);

	_agB_write(buffer, ptr, sz);
	n += sz;

	END_CHECK(n)

	return n;
}

size_t amf_encode_undefine(struct buffer * buffer)
{
	log("amf_encode_undefine\n");

	BEGIN_CHECK

	_agB_putc(buffer, amf_undefine);

	END_CHECK(1)

	return 1;
}

size_t amf_encode_null(struct buffer * buffer)
{
	BEGIN_CHECK
	log("amf_encode_null\n");
	_agB_putc(buffer, amf_null);

	END_CHECK(1)

	return 1;
}

size_t amf_encode_false(struct buffer * buffer)
{
	BEGIN_CHECK
	log("amf_encode_false\n");
	_agB_putc(buffer, amf_false);
	END_CHECK(1)
	return 1;
}

size_t amf_encode_true(struct buffer * buffer)
{
	BEGIN_CHECK
	log("amf_encode_true\n");
	_agB_putc(buffer, amf_true);
	END_CHECK(1)
	return 1;
}

static struct {
	const char * ptr;
	size_t len;
} string_ref[1024];

static unsigned int cur_ref = 0;

static size_t amf_decode_u29(const char * data, size_t len, uint32_t * v)
{
	size_t skip = 0;
	uint32_t n = 0;

	size_t i = 0;
	while(1) {
		unsigned char c;

		if (len < 1) return 0;

		c = (unsigned char)data[0];
		DATA_POP(1, skip); 
		if (i != 3) {
			n |= (uint32_t)(c&0x7F);
			if((c&0x80) != 0) {
				if (i != 2) {
					n <<= 7;
				} else {
					n <<= 8;
				}
			} else {
				break;
			}
		} else {
			n |= (uint32_t)(c);
			break;
		}
		i++;
	}
	if (v) *v = n;
	return skip;
}

/*
static size_t amf_decode_i29(const char * data, size_t len, int32_t * v)
{
	uint32_t u = 0;
	size_t s = amf_decode_u29(data, len, &u);
	if (v) *v = U2SInt29(u);
	return s;
}
*/

size_t amf_decode_double(const char * data, size_t len, double * d)
{
	union {
		double d;
		char c[8];
	} v;

	log("amf_decode_double\n");

	if (len < 9) return 0;

	data += 1;

	v.c[0] = data[7];
	v.c[1] = data[6];
	v.c[2] = data[5];
	v.c[3] = data[4];
	v.c[4] = data[3];
	v.c[5] = data[2];
	v.c[6] = data[1];
	v.c[7] = data[0];

	if (d) *d = v.d;

	return 9;
}

size_t amf_decode_integer(const char * data, size_t len, uint32_t * v)
{
	size_t skip = 0;
	size_t cur_len;

	log("amf_decode_integer\n");


	//type
	if (len == 1) { return 0; }
	//assert(data[0] == amf_integer);
	DATA_POP(1, skip);

	//value
	cur_len = amf_decode_u29(data,len, v);
	if (cur_len == 0) {
		return 0;
	}
	DATA_POP(cur_len, skip);

	return skip;
}

size_t amf_decode_sinteger(const char * data, size_t len, int32_t * v)
{
	uint32_t u = 0;
	size_t s = amf_decode_integer(data, len, &u);
	if (v) *v = U2SInt29(u);
	return s;
}

size_t amf_decode_string(const char * data, size_t len, struct amf_slice * slice)
{
	size_t skip = 0;
	uint32_t string_size;
	size_t cur_len;

	log("amf_decode_string\n");

	//type
	if (len == 0)  {
		slice->buffer = (void*)"";
		slice->len    = 0;
		return 0; 
	}

	assert(data[0] == amf_string);
	DATA_POP(1, skip);

	//size
	string_size = 0;
	cur_len = amf_decode_u29(data, len, &string_size);
	if (cur_len == 0) {
		slice->buffer = (void*)"";
		slice->len    = 0;
		return 0;
	}
	DATA_POP(cur_len, skip);

	if ((string_size & 1) == 0) {
		//load ref
		unsigned int ref = string_size >> 1;
		if (ref >= cur_ref) {
			slice->buffer = (void*)"";
			slice->len    = 0;
			return 0;  
		}

		if (slice) {
			if (ref < 1024) {
				slice->buffer = (void*)string_ref[ref].ptr;
				slice->len    = string_ref[ref].len;
			} else {
				slice->buffer = (void*)"";
				slice->len    = 0;
			}
		}
	} else {
		string_size >>= 1;

		//create
		if (len < string_size)  return 0;

		if (slice) {
			slice->buffer = (void*)data;
			slice->len = string_size;
		}

		if (cur_ref < 1024) {
			string_ref[cur_ref].ptr = data;
			string_ref[cur_ref].len = string_size;
		}

		//assert(cur_ref < 1024);
		cur_ref ++;

		DATA_POP(string_size, skip);
	}

	return skip;
}

size_t amf_decode_byte_array(const char * data, size_t len, struct amf_slice * slice)
{
	size_t skip = 0;
	uint32_t string_size;
	size_t cur_len;
	log("amf_decode_byte_array\n");


	//type
	if (len == 0)  {
		slice->buffer = (void*)"";
		slice->len    = 0;
		return 0; 
	}

	assert(data[0] == amf_byte_array);
	DATA_POP(1, skip);

	//size
	string_size = 0;
	cur_len = amf_decode_u29(data, len, &string_size);
	if (cur_len == 0) {
		slice->buffer = (void*)"";
		slice->len    = 0;
		return 0;
	}
	DATA_POP(cur_len, skip);

	string_size >>= 1;

	//create
	if (len < string_size)  return 0;

	if (slice) {
		slice->buffer = (void*)data;
		slice->len = string_size;
	}

	DATA_POP(string_size, skip);

	return skip;
}

size_t amf_decode_undefine(const char * data, size_t dlen)
{
	log("amf_decode_undefine\n");

	if (dlen == 0) { return 0; }
	//assert(data[0] == amf_undefine);

	return 1;
}

size_t amf_decode_null(const char * data, size_t dlen)
{
	log("amf_decode_null\n");

	if (dlen < 1) { return 0; }
	//assert(data[0] == amf_null);

	return 1;
}

size_t amf_decode_false(const char * data, size_t dlen)
{
	log("amf_decode_false\n");

	if (dlen < 1) { return 0; }
	//assert(data[0] == amf_false);

	return 1;
}

size_t amf_decode_true(const char * data, size_t dlen)
{
	log("amf_decode_true\n");

	if (dlen < 1) { return 0; }
	//assert(data[0] == amf_true);

	return 1;
}

#define ASSERT_RETURN(cond, v) do { if (!(cond)) return v; } while(0)

size_t amf_decode_array(const char * data, size_t len, size_t * sz)
{
	size_t skip = 0;
	uint32_t array_size;
	size_t cur_len;

	log("amf_decode_array\n");

	// type
	if (len == 0) return 0;
	assert(data[0] == amf_array);
	DATA_POP(1, skip);

	//size
	array_size = 0;
	cur_len = amf_decode_u29(data, len, &array_size);
	if (cur_len == 0) { return 0; }
	DATA_POP(cur_len, skip);

	// assert(array_size & 1);
	ASSERT_RETURN(array_size & 1, 0);

	array_size >>= 1;

	//name
	if (len == 0) return 0;
	// assert(data[0] == 1);
	ASSERT_RETURN(data[0] == 1, 0);

	DATA_POP(1, skip);

	if (sz) *sz = array_size;

	return skip;
}

