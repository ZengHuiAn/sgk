#ifndef _A_GAME_COMM_BUFFER_H_
#define _A_GAME_COMM_BUFFER_H_


#ifdef __cpluscplus
extern "C" {
#endif

#include <stdlib.h>

struct buffer;

struct buffer * _agB_new(size_t size);
void            _agB_free(struct buffer * buf);

size_t _agB_size(struct buffer * buf);

void * _agB_peek  (struct buffer * buf, size_t len);
void * _agB_read  (struct buffer * buf, size_t len);
void * _agB_buffer(struct buffer * buf, size_t len);
void * _agB_prepare(struct buffer * buf, size_t len);
int    _agB_write (struct buffer * buf, const void * data, size_t len);

char   _agB_getc(struct buffer * buf);
int    _agB_putc(struct buffer * buf, char c);

void   _agB_statistic();


#ifdef __cpluscplus
}
#endif

#endif