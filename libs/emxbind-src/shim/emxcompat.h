/* emxcompat.h -- small emx libc helpers, mapped to Linux equivalents.
   Force-included (gcc -include) when building emxbind on Linux. */
#ifndef _EMXCOMPAT_H
#define _EMXCOMPAT_H

#include <string.h>
#include <strings.h>   /* strcasecmp / strncasecmp */
#include <errno.h>

/* emx's _strncpy: like strncpy but ALWAYS null-terminates (size includes NUL). */
static inline char *_strncpy(char *d, const char *s, size_t n){
  if (n == 0) return d;
  strncpy(d, s, n-1);
  d[n-1] = '\0';
  return d;
}

/* emx case-insensitive compares. */
#ifndef stricmp
#define stricmp  strcasecmp
#endif
#ifndef strnicmp
#define strnicmp strncasecmp
#endif

/* emx's _errno(): returns pointer to errno. */
static inline int *_errno(void){ return &errno; }

#endif

/* emx getopt extension: option switch character(s). Benign on Linux. */
#ifndef _EMX_OPTSWCHAR_DEFINED
#define _EMX_OPTSWCHAR_DEFINED
extern const char *optswchar;
#endif
