
#include "miniz.h"
#include "stream.h"
#include <stdarg.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef struct zip_stream {
	mz_uint64 postion;
	mz_uint64 offset;
	mz_zip_archive * archive;
	mz_zip_archive_file_stat * status;
	char* logfile;
}zip_stream;

/*
static void logd(zip_stream * stream, const char* str)
{
	FILE* f = MZ_FOPEN(stream->logfile, "a+");
	if (!f)
	{
		return;
	}
	fwrite(str, 1, strlen(str), f);
	fclose(f);
}

#define LOGF(stream, format, ...) { \
	char buf[1024] = {0};\
	sprintf_s(buf, 1024, format, __VA_ARGS__); \
	logd((stream), buf); \
}
*/

static void logd(zip_stream * stream, const char* format, ...)
{
	return ;
#if _WIN32
	va_list args = NULL;
#else
	va_list args;
#endif
	char buf[1024];
	FILE * f;
	int ret = 0;

	if (!stream || !stream->logfile)
	{
		return;
	}

	va_start(args, format);
	vsnprintf(buf, 1024, format, args);
	va_end(args);

#if _WIN32
	ret = fopen_s(&f, stream->logfile, "a+");
#else
	f = fopen(stream->logfile, "a+");
#endif

	assert(strlen(stream->logfile) != 0);
	assert(ret == 0);

	fwrite(buf, 1, strlen(buf), f);
	fclose(f);
}

LUALIB_API void zip_stream_set_log_file(zip_stream * stream, const char* file)
{
	int l = strlen(file)+1;
	stream->logfile = (char*)malloc(l*sizeof(char));
#if _WIN32
	strcpy_s(stream->logfile, sizeof(char)*l, file);
#else
	strcpy(stream->logfile, file);
#endif
}

LUALIB_API struct mz_zip_archive_tag * zip_archive_create(const char* filename)
{
	mz_zip_archive * archive = (mz_zip_archive*)malloc(sizeof(mz_zip_archive));
	memset(archive, 0, sizeof(mz_zip_archive));
	if (!mz_zip_reader_init_file(archive, filename, 0 | MZ_ZIP_FLAG_DO_NOT_SORT_CENTRAL_DIRECTORY))
	{
		zip_archive_delete(archive);
		archive = NULL;
	}

	return archive;
}

LUALIB_API void zip_archive_delete(struct mz_zip_archive_tag * archive)
{
	if (archive)
	{
        mz_zip_reader_end(archive);
		free(archive);
	}
}

LUALIB_API int zip_stream_locate(void * archive, const char* filename)
{
	return mz_zip_reader_locate_file((mz_zip_archive*)archive, filename, NULL, 0);
}

LUALIB_API struct zip_stream * zip_stream_create(void * archive, const char* filename)
{
	mz_uint32 local_header_u32[(MZ_ZIP_LOCAL_DIR_HEADER_SIZE + sizeof(mz_uint32) - 1) / sizeof(mz_uint32)]; 
	mz_uint8 *pLocal_header = (mz_uint8 *)local_header_u32;

	struct zip_stream * stream = (struct zip_stream*)malloc(sizeof(struct zip_stream));
	memset(stream, 0, sizeof(struct zip_stream));
	stream->status = (mz_zip_archive_file_stat*)malloc(sizeof(mz_zip_archive_file_stat));
	memset(stream->status, 0, sizeof(mz_zip_archive_file_stat));
	int compelete = 0;
	do
	{
		stream->postion = 0;

		int index = mz_zip_reader_locate_file((mz_zip_archive*)archive, filename, NULL, 0);
		stream->archive = (mz_zip_archive*)archive;
		if (!mz_zip_reader_file_stat((mz_zip_archive*)archive, index, stream->status) || stream->status->m_method)
			break;
		stream->offset = stream->status->m_local_header_ofs;
		if (stream->archive->m_pRead(stream->archive->m_pIO_opaque, stream->offset, pLocal_header, MZ_ZIP_LOCAL_DIR_HEADER_SIZE) != MZ_ZIP_LOCAL_DIR_HEADER_SIZE)
			break;
		if (MZ_READ_LE32(pLocal_header) != MZ_ZIP_LOCAL_DIR_HEADER_SIG)
			break;
		stream->offset += MZ_ZIP_LOCAL_DIR_HEADER_SIZE + MZ_READ_LE16(pLocal_header + MZ_ZIP_LDH_FILENAME_LEN_OFS) + MZ_READ_LE16(pLocal_header + MZ_ZIP_LDH_EXTRA_LEN_OFS);
		compelete = 1;
	} while (0);

	if (compelete == 0)
	{
		zip_stream_delete(stream);
		stream = NULL;
	}

	return stream;
}

LUALIB_API void zip_stream_delete(struct zip_stream * stream)
{
	if (stream && stream->status)
	{
		free(stream->status);
	}

	if (stream)
	{
		free(stream);
	}
}

LUALIB_API int zip_stream_read(struct zip_stream * stream, char * buffer, int offset, int count)
{
	if (!stream || !buffer)
	{
		return 0;
	}

	mz_uint64 c = stream->postion + offset;
	mz_uint64 last = stream->status->m_uncomp_size - c;
	int readcount = 0;
	if (last >= count)
	{
		readcount = count;
		if (!stream->archive->m_pRead(stream->archive->m_pIO_opaque, stream->offset + c, buffer, (size_t)count))
			readcount = 0;
	}
	else if(last > 0 )
	{
		readcount = (int)last;
		if (!stream->archive->m_pRead(stream->archive->m_pIO_opaque, stream->offset + c, buffer, (size_t)last))
			readcount = 0;
	}
	stream->postion += readcount;

	return readcount;
}

LUALIB_API unsigned long long zip_stream_seek(struct zip_stream * stream, long long offset, int origin)
{
	logd(stream, "offset: %ld, origin:%d", offset, origin);
	if (!stream)
	{
		return 0;
	}

	if (origin == 1)
	{
		stream->postion += offset;
	}else if (origin == 2)
	{
		stream->postion = stream->status->m_uncomp_size + offset;
	}
	else
	{
		stream->postion = offset;
	}

	logd(stream, ",seek over, position %ld\n", stream->postion);
	return stream->postion;
}

LUALIB_API unsigned long long zip_stream_length(struct zip_stream * stream)
{
	if (!stream)
	{
		return 0;
	}
	return stream->status->m_uncomp_size;
}

LUALIB_API unsigned long long zip_stream_postion(struct zip_stream * stream)
{
	if (!stream)
	{
		return 0;
	}
	return stream->postion;
}

#ifdef __cplusplus
}
#endif
