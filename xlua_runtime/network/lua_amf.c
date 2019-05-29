#include "amf.h"
#include "assert.h"
#include "buffer.h"
#include "lua_amf.h"

static size_t lua_amf_encode_array(struct buffer * buffer, lua_State * L, int index) {
	size_t n = 0;

	lua_pushvalue(L, index);

	int arr_size = 0;
	int i;
	for (i = 1; i <= 100; i++) {
		lua_pushinteger(L, i);
		lua_gettable(L, -2);

		if (lua_isnil(L, -1)) {
			lua_pop(L, 1);
			break;
		}
		arr_size++;

		lua_pop(L, 1);
	}

	n += amf_encode_array(buffer, arr_size);
	for (i = 1; i <= arr_size; i++) {
		lua_pushinteger(L, i);
		lua_gettable(L, -2);

		n += lua_encode_amf(L, -1, buffer);

		lua_pop(L, 1);
	}

	lua_pop(L, 1);

	return n;
}

size_t lua_encode_amf(lua_State * L, int index, struct buffer * buffer)
{
	switch (lua_type(L, index)) {
	case LUA_TNIL:
		return amf_encode_null(buffer);
	case LUA_TBOOLEAN:
		if (lua_toboolean(L, index)) {
			return amf_encode_true(buffer);
		} else {
			return amf_encode_false(buffer);
		}
	case LUA_TNUMBER:
	{
		double num = lua_tonumber(L, -1);
		if (num != (int)num) {
			return amf_encode_double(buffer, num);
		} else if (num >= 0) {
			return amf_encode_integer(buffer, num);
		} else {
			return amf_encode_sinteger(buffer, num);
		}
	}
	case LUA_TSTRING:
	{
		size_t str_len = 0;
		const char * ptr = lua_tolstring(L, index, &str_len);
		return amf_encode_string(buffer, ptr, str_len);
	}
	case LUA_TTABLE:
		return lua_amf_encode_array(buffer, L, index);
	case LUA_TFUNCTION:
	case LUA_TUSERDATA:
	case LUA_TTHREAD:
	case LUA_TLIGHTUSERDATA:
	default:
		printf("can't encode lua type %d\n", lua_type(L, index)); 
		return amf_encode_null(buffer);
	}
}

size_t lua_decode_amf(lua_State * L, const char * buff, size_t len)
{
	switch(buff[0]) {
		case amf_undefine: 
			lua_pushnil(L);
			return amf_decode_undefine(buff, len);
		case amf_null:
			lua_pushnil(L);
			return amf_decode_null(buff, len);
		case amf_false:
			lua_pushboolean(L, 0);
			return amf_decode_false(buff, len);
		case amf_true:
			lua_pushboolean(L, 1);
			return amf_decode_true(buff, len);
		case amf_integer:
		{
			uint32_t v;
			size_t n = amf_decode_integer(buff, len, &v);
			lua_pushinteger(L, v);
			return n;
		}
		case amf_double: 
		{
			double d;
			size_t n = amf_decode_double(buff, len, &d);
			lua_pushnumber(L, d);
			return n;
		}
		case amf_string:
		{
			struct amf_slice slice;
			size_t n = amf_decode_string(buff, len, &slice);
			lua_pushlstring(L, (const char*)slice.buffer, slice.len);
			return n;
		}
		case amf_byte_array:
		{
			struct amf_slice slice;
			size_t n = amf_decode_byte_array(buff, len, &slice);
			lua_pushlstring(L, (const char*)slice.buffer, slice.len);
			return n;
		}
		case amf_sinteger:
		{
			int32_t v;
			size_t n = amf_decode_sinteger(buff, len, &v);
			lua_pushinteger(L, v);
			return n;
		}
		case amf_array:
		{
			size_t array_size = 0;
			size_t n = amf_decode_array(buff, len, &array_size);
			size_t i;
			buff += n; len -= n;

			lua_newtable(L);
			for (i = 1; i <= array_size; i++) {
				lua_pushinteger(L, i);
				size_t en = lua_decode_amf(L, buff, len);
				lua_settable(L, -3);

				buff += en;
				len -= en;
				n += en;
			}
			return n;
		}
		case amf_xml_doc:
		case amf_date:
		case amf_object:
		case amf_xml:
		default:
			lua_pushnil(L);
			return 0;
	}
}
