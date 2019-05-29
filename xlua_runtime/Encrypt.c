#include <assert.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#ifdef __cplusplus
extern "C" {
#endif

#include "lua.h"
#include "lauxlib.h"
#include "lualib.h"

static const char* KEY = "&EOQaSQCdh62%lv5gf1h4G#9R9ygJ7HWRe8nTN!XXmeu6m5Yh%CecgOb2EPLeXPR";
static const int t = 10;
LUALIB_API void decode(char* buffer, int pos, int count)
{
	int i = pos % t;
	int len = strlen(KEY);
	i = i > 0 ? t - i : i;
	
	while(i < count)
	{
		buffer[i] ^= KEY[(pos + i) % len];
		i += t;
	}
}

LUALIB_API void encode(char* buffer, int pos, int count)
{
	int i = pos % t;
	int len = strlen(KEY);
	i = i > 0 ? t - i : i;
	
	while(i < count)
	{
		buffer[i] ^= KEY[(pos + i) % len];
		i += t;
	}
}

/*
int main()
{
	char str[] = "1234567890";
	
	encode(str, 0, strlen(str));
	printf("encode %s\n", str);
	
	decode(str, 0, strlen(str));
	printf("decode %s\n", str);
	
	return 0;
}
*/

#ifdef __cplusplus
}
#endif
