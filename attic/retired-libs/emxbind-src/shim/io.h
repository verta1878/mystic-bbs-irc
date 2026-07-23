/* io.h shim for building emxbind on Linux (POSIX low-level I/O). */
#ifndef _IO_H_SHIM
#define _IO_H_SHIM
#include <unistd.h>
#include <fcntl.h>
#include <sys/stat.h>
#ifndef O_BINARY
#define O_BINARY 0
#endif
#ifndef O_TEXT
#define O_TEXT 0
#endif
/* emx uses setmode() to switch a handle to binary; on Linux it's a no-op. */
static inline int setmode(int h, int m){ (void)h;(void)m; return O_BINARY; }
/* filelength(handle) -> size in bytes */
static inline long filelength(int h){ struct stat s; if(fstat(h,&s)!=0) return -1L; return (long)s.st_size; }
/* chsize(handle,size) -> ftruncate */
static inline int chsize(int h, long sz){ return ftruncate(h,(off_t)sz); }
#endif
