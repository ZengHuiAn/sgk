
#include "lprefix.h"

#include <ctype.h>
#include <errno.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "lua.h"
#include "lauxlib.h"

#include "lobject.h"
#include "lstate.h"
#include "lundump.h"

typedef struct lArray {
	unsigned char* cache;
	int lenght;
	int capity;
}lArray;

static lArray arr;

static int writerCache(lua_State* L, const void* p, size_t size, void* u)
{
	UNUSED(L);
	if (arr.cache == NULL)
	{
		arr.capity = 1024;
		arr.cache = (unsigned char*)malloc(arr.capity);
		memset(arr.cache, 0, arr.capity);
	}
	if (arr.lenght + size >= arr.capity)
	{
		arr.capity = (arr.lenght + size) * 2;
		unsigned char* nc = (unsigned char*)realloc(arr.cache, arr.capity);
		if (nc == NULL)
		{
			return 1;
		}
		arr.cache = nc;

		memset(arr.cache + arr.lenght, 0, arr.capity - arr.lenght);
	}

	memcpy(arr.cache + arr.lenght, p, size);
	arr.lenght += size;

	return 0;
}

#define toproto(L,i) getproto(L->top+(i))


int luacrt_export(lua_State* L, char* str)
{
	int b = 0, ret = -1;
	if (L == NULL)
	{
		L = luaL_newstate();
		b = 1;
	}

	if (L != NULL)
	{
		const Proto* f;
		if (luaL_loadstring(L, str) != LUA_OK)
		{
			ret = -2;
		}
		else
		{
			f = toproto(L, -1);;
			if (arr.cache)
			{
				memset(arr.cache, 0, arr.capity); arr.lenght = 0;
			}

			lua_lock(L);
			luaU_dump(L, f, writerCache, &arr, 1);
			lua_unlock(L);
			ret = arr.lenght;
		}
		
		if (b == 1)
		{
			lua_close(L);
		}
	}

	return ret;
}

unsigned char* luacrt_byte()
{
	if (arr.cache)
	{
		return arr.cache;
	}
	return NULL;
}


void luacrt_clear()
{
	if (arr.cache)
	{
		free(arr.cache);
		arr.cache = 0;
		arr.lenght = arr.capity = 0;
	}
}