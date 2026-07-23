/* sys/user.h shim -- minimal emx core-dump header for building emxbind.
   The core-dump (read_core) path is not exercised by normal a.out->LX
   binding (FPC's use), but the struct must exist to compile exec.c.
   Fields reconstructed from their use in exec.c; all are 32-bit values. */
#ifndef _SYS_USER_H_SHIM
#define _SYS_USER_H_SHIM

#include "defs.h"   /* dword */

#ifndef UMAGIC
#define UMAGIC 0563   /* emx core-file magic (u_magic) */
#endif

struct user
{
  dword u_magic;         /* core-file magic (UMAGIC) */
  dword u_data_base;     /* base address of initialised data */
  dword u_data_end;      /* end address of initialised data */
  dword u_data_off;      /* file offset of data image in the core file */
  dword u_heap_base;     /* base address of the heap */
  dword u_heap_end;      /* end address of the heap */
  dword u_heap_brk;      /* current heap break */
  dword u_heap_off;      /* file offset of heap image in the core file */
  dword u_heapobjs_off;  /* file offset of the heap-objects table */
};

#endif
