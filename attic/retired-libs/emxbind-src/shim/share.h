/* share.h shim for Linux: sopen() sharing flags collapse to open(). */
#ifndef _SHARE_H_SHIM
#define _SHARE_H_SHIM
#include <fcntl.h>
#define SH_DENYRW 0x10
#define SH_DENYWR 0x20
#define SH_DENYRD 0x30
#define SH_DENYNO 0x40
#define SH_COMPAT 0x00
/* SH_SIZE used by emx sopen as an addressing hint; harmless here. */
#ifndef SH_SIZE
#define SH_SIZE 0
#endif
/* sopen(name, oflag, shflag, ...) -> ignore shflag on Linux */
#include <stdarg.h>
static inline int sopen(const char *p, int oflag, int shflag, ...){
  (void)shflag; int mode=0; va_list ap; va_start(ap,shflag); mode=va_arg(ap,int); va_end(ap);
  return open(p, oflag, mode);
}
#endif
