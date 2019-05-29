#ifdef __cpluscplus
extern "C" {
#endif

#include "lua.h"
#include "lauxlib.h"
#include "lualib.h"

#include "buffer.h"

size_t lua_encode_amf(lua_State * L, int index, struct buffer * buffer);
size_t lua_decode_amf(lua_State * L, const char * buff, size_t len);

#ifdef __cpluscplus
}
#endif


