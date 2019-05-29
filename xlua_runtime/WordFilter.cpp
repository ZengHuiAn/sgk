#include <string>
#include <map>
#include <vector>

#include "utf8.h"

using namespace std;

typedef unsigned short u16char;

class CharSlot {
public:
	u16char c;
	map<u16char, struct CharSlot*> children;
	
	CharSlot(u16char c = 0) {
		this->c = c;
	}
};

static CharSlot rootFilter;
static CharSlot rootUnfilter;
static CharSlot endSlot;

static void add_to_filter(CharSlot & root, const vector<u16char> & str) {
	map<u16char, struct CharSlot*> * slot = &root.children;
	for (int i = 0; i < str.size(); i++) {
		u16char c = str[i];
		if ((*slot)[c] == 0) {
			(*slot)[c] = new CharSlot(c);
		}
		slot = &((*slot)[c]->children);
	}
	(*slot)[0] = &endSlot;
}

static void word_filter_add(const char * ptr, int len) {
	if (len == 0) {
		return;
	}

	if (ptr[0] == '-') {
		vector<u16char> utf16line;
		utf8::utf8to16(ptr+1, ptr+len, back_inserter(utf16line));
		add_to_filter(rootUnfilter, utf16line);
	} else {
		vector<u16char> utf16line;
		utf8::utf8to16(ptr, ptr+len, back_inserter(utf16line));
		add_to_filter(rootFilter, utf16line);
	}
}

static void clean_node(struct CharSlot * slot)
{
	if (!slot) {
		return;
	}

	for(map<u16char, struct CharSlot*>::iterator ite = slot->children.begin(); ite != slot->children.end(); ite ++) {
		clean_node(ite->second);
	}

	slot->children.clear();

	if (slot != &rootFilter && slot != &rootUnfilter && slot != &endSlot) {
		delete slot;
	}
}

static void word_filter_clean() {
	clean_node(&rootFilter);
	clean_node(&rootUnfilter);
};

static void word_filter_init(const char * ptr, int len)
{
	word_filter_clean();

	vector< vector<u16char> > stringsFilter;
	vector< vector<u16char> > stringsUnFilter;

	const char * end = ptr + len;
	
	while(ptr < end) {
		int i;
		for (i = 0; true; i++) {
			if (ptr[i] == '\r' || ptr[i] == '\n' || ptr[i] == 0 || (ptr + i) >= end) {
				word_filter_add(ptr, i);
				ptr += i + 1;
				break;
			}
		}
	}
}

static int match(const vector<u16char> & input, int pos, struct CharSlot * slot)
{
	if (pos >= input.size() || pos < 0) {
		return 0;
	}

	u16char c = input[pos];
	struct CharSlot * next = slot->children[c];
	if (next == 0) {
		return 0;
	} else if (next->children.empty()) {
		return 1;
	} else {
		int n = match(input, pos + 1, next);
		if (n == 0 && next->children[0]) {
			return 1;
		} else {
			return n ? (n + 1) : 0;
		}
	}
}

vector<u16char> word_filter_check(const vector<u16char> & input, bool * hit)
{
	vector<u16char> output = input;
	for (int i = 0; i < input.size(); i++) {
		int n = match(input, i, &rootUnfilter);
		if (n > 0) {
			i += n-1;
			continue;
		}

		n = match(input, i, &rootFilter);
		if (n <= 0) {
			continue;
		} else {
			for (int j = 0; j < n; j++) {
				output[i + j] = '*';
			}
			i += n-1;
			if (hit) *hit = true;
		}
	}
	return output;
}

static string word_filter_check_utf8(const char * ptr, size_t len, bool * hit) {
	const char * end_it = utf8::find_invalid(ptr, ptr + len);

	// if (end_it != ptr + len) { }

	vector<u16char> utf16line;
        utf8::utf8to16(ptr, end_it, back_inserter(utf16line));

	utf16line = word_filter_check(utf16line, hit);

        // And back to utf-8
        string output; 
        utf8::utf16to8(utf16line.begin(), utf16line.end(), back_inserter(output));

	return output;
}


#if 1

#ifdef __cplusplus
extern "C" {
#endif

#include "lua.h"
#include "lualib.h"
#include "lauxlib.h"


static int l_init(lua_State * L) {
	const char * str = luaL_checkstring(L, 1);
	word_filter_init(str, strlen(str));
	return 0;
}

static int l_add(lua_State * L) {
	const char * str = luaL_checkstring(L, 1);
	word_filter_add(str, strlen(str));
	return 0;
}

static int l_check(lua_State * L) {
	const char * str = luaL_checkstring(L, 1);

	bool hit = false;;

	string output = word_filter_check_utf8(str, strlen(str), &hit);

	lua_pushstring(L, output.c_str());
	lua_pushboolean(L, hit ? 1 : 0);

	return 2;
}

static const luaL_Reg LIB[] = {
	{"init",  l_init},
	{"add",   l_add},
	{"check", l_check},
	{NULL, NULL}
};

LUA_API int luaopen_WordFilter(lua_State *L) {
#if LUA_VERSION_NUM == 503
	luaL_newlib(L, LIB);
	lua_setglobal(L, "WordFilter");
#else
	luaL_register(L, "WordFilter", LIB);
	lua_pop(L, 1);
#endif
	return 0;
}


#ifdef __cplusplus
}
#endif

#else

#include <stdio.h>
#include <string.h>
#include <stdlib.h>

int main() {
        const char * filters = "中国\n-曹操\n操";

        word_filter_init(filters, strlen(filters));

        const char * msg = "曹操是个中国人";

        bool hit = false;
	string output = word_filter_check_utf8(msg, strlen(msg), &hit);
        printf("%s : %s\n", hit ? "Y" : "N", output.c_str());
}
#endif
