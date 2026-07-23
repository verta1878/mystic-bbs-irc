/* sys/moddef.h -- reconstructed emx module-definition (.def) parser API.

   This header is reconstructed for building emxbind on a modern Linux host.
   The original ships in the emx binary development kit's include/ tree; it is
   NOT in the emx source ZIPs.  Every type, enum value and prototype here is
   derived from the moddef parser implementation (moddef1.c / moddef2.c /
   moddef3.c) and from emxbind's use of the API, all of which ARE in the emx
   GPL sources.  Buffer sizes are chosen generously; the parser copies with a
   bounded _strncpy against sizeof(), so any adequately large size is safe.

   emx is GPL (Copyright (c) 1990-1998 Eberhard Mattes); this reconstructed
   header is a build aid distributed under the same terms.  */

#ifndef _SYS_MODDEF_H_RECONSTRUCTED
#define _SYS_MODDEF_H_RECONSTRUCTED

#include <stdio.h>

/* Generous fixed buffer size for names copied by the parser. */
#define _MD_NAMELEN   256
#define _MD_STRLEN    512

/* Tokens / statement-type codes.  Used both as lexer tokens (keywords) and,
   for the top-level ones, as _md_stmt.type discriminators. */
typedef enum
{
  _MD_parseerror = -1,
  _MD_ALIAS = 0, _MD_BASE, _MD_CLASS, _MD_CODE, _MD_CONFORMING, _MD_CONTIGUOUS,
  _MD_DATA, _MD_DESCRIPTION, _MD_DEV386, _MD_DEVICE, _MD_DISCARDABLE,
  _MD_DOS4, _MD_DYNAMIC, _MD_EXECUTEONLY, _MD_EXECUTEREAD, _MD_EXETYPE,
  _MD_EXPANDDOWN, _MD_EXPORTS, _MD_FIXED, _MD_HEAPSIZE, _MD_HUGE,
  _MD_IMPORTS, _MD_IMPURE, _MD_INCLUDE, _MD_INITGLOBAL, _MD_INITINSTANCE,
  _MD_INVALID, _MD_IOPL, _MD_LIBRARY, _MD_LOADONCALL, _MD_MAXVAL,
  _MD_MIXED1632, _MD_MOVEABLE, _MD_MULTIPLE, _MD_NAME, _MD_NEWFILES,
  _MD_NODATA, _MD_NOEXPANDDOWN, _MD_NOIOPL, _MD_NONAME, _MD_NONCONFORMING,
  _MD_NONDISCARDABLE, _MD_NONE, _MD_NONPERMANENT, _MD_NONSHARED,
  _MD_NOTWINDOWCOMPAT, _MD_OBJECTS, _MD_OLD, _MD_ORDER, _MD_OS2,
  _MD_PERMANENT, _MD_PHYSICAL, _MD_PRELOAD, _MD_PRIVATE, _MD_PRIVATELIB,
  _MD_PROTECT, _MD_PROTMODE, _MD_PURE, _MD_READONLY, _MD_READWRITE,
  _MD_REALMODE, _MD_RESIDENT, _MD_RESIDENTNAME, _MD_SEGMENTS, _MD_SHARED,
  _MD_SINGLE, _MD_STACKSIZE, _MD_STUB, _MD_SWAPPABLE, _MD_TERMGLOBAL,
  _MD_TERMINSTANCE, _MD_UNKNOWN, _MD_VIRTUAL, _MD_WINDOWAPI,
  _MD_WINDOWCOMPAT, _MD_WINDOWS,
  /* additional lexical tokens produced by the scanner (exact names from
     the moddef implementation) */
  _MD_eof, _MD_word, _MD_number, _MD_quote, _MD_missingquote,
  _MD_ioerror, _MD_at, _MD_dot, _MD_equal
} _md_token;

/* PM application type (NAME / stmt.name.pmtype, exetype.type). */
#define _MDT_DEFAULT           0
#define _MDT_WINDOWAPI         1
#define _MDT_WINDOWCOMPAT      2
#define _MDT_NOTWINDOWCOMPAT   3

/* EXETYPE codes. */
#define _MDX_DEFAULT   0
#define _MDX_UNKNOWN   1
#define _MDX_OS2       2
#define _MDX_WINDOWS   3

/* LIBRARY / init-term flags. */
#define _MDIT_DEFAULT   0
#define _MDIT_GLOBAL    1
#define _MDIT_INSTANCE  2

/* EXPORTS / IMPORTS flags (bitmask in .flags). */
#define _MDEP_ORDINAL       0x01
#define _MDEP_RESIDENTNAME  0x02
#define _MDEP_NONAME        0x04
#define _MDEP_NODATA        0x08
#define _MDEP_PWORDS        0x10

/* IMPORTS flags (bitmask in stmt.import.flags). */
#define _MDIP_ORDINAL       0x01

/* SEGMENTS attributes (bitmask in stmt.segment.attr). */
#define _MDS_NONE            0x00000000UL
#define _MDS_INVALID        0xffffffffUL
#define _MDS_ALIAS          0x00000001UL
#define _MDS_CONFORMING     0x00000002UL
#define _MDS_DISCARDABLE    0x00000004UL
#define _MDS_EXECUTEONLY    0x00000008UL
#define _MDS_EXECUTEREAD    0x00000010UL
#define _MDS_FIXED          0x00000020UL
#define _MDS_IOPL           0x00000040UL
#define _MDS_LOADONCALL     0x00000080UL
#define _MDS_MIXED1632      0x00000100UL
#define _MDS_MOVEABLE       0x00000200UL
#define _MDS_MULTIPLE       0x00000400UL
#define _MDS_NOIOPL         0x00000800UL
#define _MDS_NONCONFORMING  0x00001000UL
#define _MDS_NONDISCARDABLE 0x00002000UL
#define _MDS_NONSHARED      0x00004000UL
#define _MDS_PRELOAD        0x00008000UL
#define _MDS_READONLY       0x00010000UL
#define _MDS_READWRITE      0x00020000UL
#define _MDS_SHARED         0x00040000UL
#define _MDS_SINGLE         0x00080000UL

/* Parser error codes (complete set, from the moddef errmsg table). */
typedef enum
{
  _MDE_NONE = 0,
  _MDE_EMPTY,
  _MDE_IO_ERROR,
  _MDE_MISSING_QUOTE,
  _MDE_NAME_EXPECTED,
  _MDE_STRING_EXPECTED,
  _MDE_NUMBER_EXPECTED,
  _MDE_EQUAL_EXPECTED,
  _MDE_DOT_EXPECTED,
  _MDE_DEVICE_EXPECTED,
  _MDE_STRING_TOO_LONG,
  _MDE_INVALID_ORDINAL,
  _MDE_INVALID_STMT,
  _MDE_EOF
} _md_error;

/* A parsed statement.  emxbind reads .type then the matching union member. */
typedef struct
{
  _md_token type;                 /* which statement (one of the _MD_* codes) */

  union
  {
    struct { char name[_MD_NAMELEN]; int pmtype; int newfiles; } name;
    struct { char string[_MD_STRLEN]; } descr;
    struct { char name[_MD_NAMELEN]; int init, term; } library;
    struct { char name[_MD_NAMELEN]; } device;
    struct { char name[_MD_NAMELEN]; int none; } stub;
    struct { char name[_MD_NAMELEN]; } old;
    struct { long addr; } base;
    struct { unsigned long size; int maxval; } stacksize;
    struct { unsigned long size; int maxval; } heapsize;
    struct { int type; int major_version, minor_version; } exetype;
    struct
    {
      char entryname[_MD_NAMELEN];
      char internalname[_MD_NAMELEN];
      unsigned ordinal;
      unsigned pwords;
      unsigned flags;
    } export;
    struct
    {
      char modulename[_MD_NAMELEN];
      char entryname[_MD_NAMELEN];
      char internalname[_MD_NAMELEN];
      unsigned ordinal;
      unsigned flags;
    } import;
    struct
    {
      char segname[_MD_NAMELEN];
      char classname[_MD_NAMELEN];
      unsigned long attr;
    } segment;
    struct { _md_error code; _md_token stmt; } error;
  };
} _md_stmt;

/* Opaque parser handle (fully defined in moddef1.c). */
struct _md;

/* Callback invoked for each parsed statement. */
typedef int _md_callback (struct _md *md, const _md_stmt *stmt,
                          _md_token token, void *arg);

/* Public API (implemented in moddef1.c / moddef2.c / moddef3.c). */
struct _md   *_md_open        (const char *fname);
struct _md   *_md_use_file    (FILE *f);
int           _md_close       (struct _md *md);
int           _md_parse       (struct _md *md, _md_callback *callback, void *arg);
_md_token     _md_next_token  (struct _md *md);
_md_token     _md_get_token   (const struct _md *md);
long          _md_get_number  (const struct _md *md);
const char   *_md_get_string  (const struct _md *md);
long          _md_get_linenumber (const struct _md *md);
const char   *_md_errmsg      (_md_error code);

#endif /* _SYS_MODDEF_H_RECONSTRUCTED */
