#ifndef _ZIP_STREAM_H_
#define _ZIP_STREAM_H_

#ifdef __cplusplus
extern "C" {
#endif

#include "lua.h"
#include "lauxlib.h"
#include "lualib.h"

	struct zip_stream;
	struct mz_zip_archive_tag;

	LUALIB_API void zip_stream_set_log_file(struct zip_stream * stream, const char* file);

	LUALIB_API struct mz_zip_archive_tag * zip_archive_create(const char* filename);
	LUALIB_API void zip_archive_delete(struct mz_zip_archive_tag * archive);

	LUALIB_API struct zip_stream * zip_stream_create(void * archive, const char* filename);
	LUALIB_API void zip_stream_delete(struct zip_stream * stream);

	LUALIB_API int zip_stream_read(struct zip_stream * stream, char * buffer, int offset, int count);
	LUALIB_API unsigned long long zip_stream_seek(struct zip_stream * stream, long long offset, int origin);
	LUALIB_API unsigned long long zip_stream_length(struct zip_stream * stream);
	LUALIB_API unsigned long long zip_stream_postion(struct zip_stream * stream);

#ifdef __cplusplus
}
#endif

#endif
