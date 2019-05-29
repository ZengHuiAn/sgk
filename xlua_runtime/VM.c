#include <string.h>
#include <errno.h>

#include <stdio.h>

#include "lua.h"
#include "lualib.h"
#include "lauxlib.h"

struct LuaVM {
	lua_State * L;
	int ref;

	struct LuaVM * self;
};


static struct LuaVM * PushLuaVM(lua_State * L, lua_State * vL) {
	struct LuaVM * vm = (struct LuaVM*)lua_newuserdata(L, sizeof(struct LuaVM));
	vm->L = vL;
	vm->ref = LUA_REFNIL;
	return vm;
}

static int fake_loader(lua_State * L) {
	lua_pushstring(L, "vm loader not implement");
	return 1;
}

#define RETURN_ERROR(msg) do { lua_pushboolean(L, 0); lua_pushstring(L, msg); return 2; } while(0)

static lua_CFunction default_loader = fake_loader;
static lua_CFunction default_print  = 0;

static int l_dispatch(lua_State * L);
static int l_listen(lua_State * L);

// LUALIB_API int luaopen_VM(lua_State *L);

static struct LuaVM * read_vm(lua_State * L, int index) {
	if (!lua_isuserdata(L, index)) {
		return NULL;
	}
	return (struct LuaVM*)lua_touserdata(L, index);
}

static lua_State * read_state(lua_State * L, int index) {
	struct LuaVM * pNL = read_vm(L, index);
	return pNL ? pNL->L : 0;
}


static void addLuaLoader(lua_State * L, lua_CFunction func)
{
    if (!func) return;

    // stack content after the invoking of the function
    // get loader table
    lua_getglobal(L, "package");                                  /* L: package */
#if LUA_VERSION_NUM == 503
    lua_getfield(L, -1, "searchers");                               /* L: package, loaders */
#else
    lua_getfield(L, -1, "loaders");                               /* L: package, loaders */
#endif
    
    // insert loader into index 2
    lua_pushcfunction(L, func);                                   /* L: package, loaders, func */

	int i;
    for (i = (int)(lua_rawlen(L, -2) + 1); i > 2; --i)
    {
        lua_rawgeti(L, -2, i - 1);                                /* L: package, loaders, func, function */
        // we call lua_rawgeti, so the loader table now is at -3
        lua_rawseti(L, -3, i);                                    /* L: package, loaders, func */
    }
    lua_rawseti(L, -2, 2);                                        /* L: package, loaders */
    
    // set loaders into package
    lua_setfield(L, -2, "loaders");                               /* L: package */
    
    lua_pop(L, 1);
}

static int l_vm_gc(lua_State * L) {
	struct LuaVM * vm = read_vm(L, 1);
	if (vm->L) {
		lua_close(vm->L);
		vm->L = 0;
	}
	return 0;
}

static int l_open(lua_State * L) {
	lua_State * nL = luaL_newstate();
	luaL_openlibs(nL);

	if (default_print) {
		lua_pushcfunction(nL, default_print);
		lua_setglobal(nL, "print");
	}

	if (default_loader) {
		addLuaLoader(nL, default_loader);
	}

	// set parent vm
	struct LuaVM * parent = PushLuaVM(nL, L);
	lua_setglobal(nL, "VM_PARENT");

	// set dispatch function
	lua_pushcfunction(nL, l_dispatch);
	lua_setglobal(nL, "c_dispatch");
	luaL_dostring(nL, "VMDispatch = function(...) c_dispatch(VM_PARENT, ...) end");

	// set listen function
	lua_pushcfunction(nL, l_listen);
	lua_setglobal(nL, "c_listen");
	luaL_dostring(nL, "VMListen = function(...) c_listen(VM_PARENT, ...) end");

	struct LuaVM * child = PushLuaVM(L, nL);

	parent->self = child;
	child->self = parent;

	if (lua_isstring(L, 1)) {
		char cmd[1024];
		int top = lua_gettop(nL);
		snprintf(cmd, 1024, "require '%s'", lua_tostring(L, 1));
		if (luaL_dostring(nL, cmd) != LUA_OK) {
			snprintf(cmd, 1024, "%s", lua_tostring(nL, -1));
			lua_close(nL);

			lua_pop(L, 1);
			RETURN_ERROR(cmd);
		}
		lua_settop(nL, top);
	}

	// close child on gc
	if (luaL_newmetatable(L, "__lua_vm_metatable__")) {
		lua_pushcfunction(L, l_vm_gc);
		lua_setfield(L, -2, "__gc");
	}
	lua_setmetatable(L, -2);

	return 1;
}

static int push_value(lua_State * to,  lua_State * from, int index)
{
	const char * ptr;
	size_t len;
	lua_CFunction func;

	int t = lua_type(from, index);
	switch(t) {
		case LUA_TBOOLEAN: 
			lua_pushboolean(to, lua_toboolean(from, index)); 
			return 1;
		case LUA_TLIGHTUSERDATA: 
			lua_pushlightuserdata(to, lua_touserdata(from, index)); 
			return 1;
		case LUA_TNUMBER:
			if (lua_isinteger(from, index)) {
				lua_pushinteger(to, lua_tointeger(from, index));
			} else {
				lua_pushnumber(to, lua_tonumber(from, index));
			}
			return 1;
		case LUA_TSTRING:
			ptr = lua_tolstring(from, index, &len);
			lua_pushlstring(to, ptr, len);
			return 1;
		case LUA_TNIL:
			lua_pushnil(to);
			return 1;
		case LUA_TFUNCTION:
			func = lua_tocfunction(from, index);
			if (func) {
				lua_pushcfunction(to, func);
				return 1;
			} else {
				lua_pushnil(to);
				return 0;
			}
		case LUA_TTABLE:
		case LUA_TUSERDATA:
		case LUA_TTHREAD:
		default:
			lua_pushnil(to);
			return 0;
	}
}


static int l_close(lua_State * L)
{
	struct LuaVM * vm = read_vm(L, 1);
	if (vm == 0) {
		RETURN_ERROR("VM not exists");
	}

	if (vm->L == 0) {
		return 0;
	}

	lua_close(vm->L);
	vm->L = 0;

	lua_pushboolean(L, 1);
	return 1;
}

static int l_listen(lua_State * L) {
	struct LuaVM * vm = read_vm(L, 1);
	if (vm == 0) {
		RETURN_ERROR("VM not exists");
	}

	lua_pushvalue(L, 2);
	vm->self->ref = luaL_ref(L, LUA_REGISTRYINDEX);
	
	lua_pushboolean(L, 1);
	return 1;
}

static int l_dispatch(lua_State * L) {
	struct LuaVM * vm = read_vm(L, 1);
	if (vm == 0) {
		RETURN_ERROR("VM not exists");
	}

	if (vm->L == 0) {
		RETURN_ERROR("VM is closed");
	}

	// no listener
	if (vm->ref == LUA_REFNIL) {
		lua_pushboolean(L, 1);
		return 1;
	}

	int i;
	int from = 2;
	lua_State * nL = vm->L;

	int top = lua_gettop(L);
	int nargs = top - from + 1;

	// push listener
	lua_rawgeti(nL, LUA_REGISTRYINDEX, vm->ref);

	// push params
	for (i = from; i <= top; i++) {
		push_value(nL, L, i);
	}

	// call
	if (lua_pcall(nL, nargs, 0, 0) != LUA_OK) {
		RETURN_ERROR(lua_tostring(nL, -1));
	}

	lua_pushboolean(L, 1);
	return 1;
}

static int l_dostring(lua_State * L) {
	lua_State * nL = read_state(L, 1);
	if (nL == 0) {
		RETURN_ERROR("VM not exists");
	}

	const char * str = luaL_checkstring(L, 2);
	if (!str) {
		RETURN_ERROR("string is nil");
	}

	if (luaL_dostring(nL, str) != LUA_OK) {
		RETURN_ERROR(lua_tostring(nL, -1));
	}

	lua_pushboolean(L, 1);
	return 1;
}

static int l_set(lua_State * L)
{
	lua_State * nL = read_state(L, 1);
	if (nL == 0) {
		RETURN_ERROR("VM not exists");
	}

	const char * key = luaL_checkstring(L, 2);
	if (!key) {
		RETURN_ERROR("key is nil");
	}

	push_value(nL, L, 3);
	lua_setglobal(nL, key);

	lua_pushboolean(L, 1);
	return 1;
}

static int l_get(lua_State * L)
{
	lua_State * nL = read_state(L, 1);
	if (nL == 0) {
		RETURN_ERROR("VM not exists");
	}

	const char * key = luaL_checkstring(L, 2);
	if (!key) {
		RETURN_ERROR("key is nil");
	}

	lua_getglobal(nL, key);
	push_value(L, nL, -1);
	lua_pop(nL, 1);

	return 1;
}

static int l_AddLoader(lua_State * L)
{
	lua_State * nL = read_state(L, 1);
	if (nL == 0) {
		RETURN_ERROR("VM not exists");
	}

	lua_CFunction func = lua_tocfunction(L, 2);
	addLuaLoader(nL, func);	

	lua_pushboolean(L, 1);
	return 1;
}


static luaL_Reg reg[] = {
	{"AddLoader",    l_AddLoader},

	{"open",         l_open},
	{"close",        l_close},

	{"dispatch",     l_dispatch},
	{"listen",       l_listen},

	{"dostring",     l_dostring},

	{"set",          l_set},
	{"get",          l_get},
	{0, 0},
};



#ifdef __cplusplus
extern "C" {
#endif

static const char * LIB_NAME = "VM";

LUALIB_API int lua_VM_SetDefaultLoader(lua_CFunction func)
{
	default_loader = func;	
	return 0;
}

LUALIB_API int lua_VM_SetPrint(lua_CFunction func)
{
	default_print = func;	
	return 0;
}

LUALIB_API int luaopen_VM(lua_State *L)
{
#if LUA_VERSION_NUM == 503
    luaL_newlib(L, reg);
    lua_setglobal(L, LIB_NAME);
    lua_getglobal(L, LIB_NAME);
#else
    luaL_register(L, LIB_NAME, reg);
#endif
	return 1;
}

#ifdef __cplusplus
}
#endif
