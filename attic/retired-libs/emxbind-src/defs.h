#ifndef _EMX_DEFS_H
#define _EMX_DEFS_H
/* defs.h -- Various definitions for emx development utilities
   Copyright (c) 1992-1998 Eberhard Mattes

This file is part of emx.

emx is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2, or (at your option)
any later version.

emx is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with emx; see the file COPYING.  If not, write to
the Free Software Foundation, 59 Temple Place - Suite 330,
Boston, MA 02111-1307, USA.  */


#define FALSE 0
#define TRUE  1

#ifdef __GNUC__
#define NORETURN2        __attribute__ ((noreturn))
#define ATTR_PRINTF(s,f) __attribute__ ((__format__ (__printf__, s, f)))
#else
#define NORETURN2
#define ATTR_PRINTF(s,f)
#endif


/* Stabs constants. */

#define N_EXT           0x01    /* Symbol is external */
#define N_ABS           0x02    /* Absolute address */
#define N_TEXT          0x04    /* In .text segment */
#define N_DATA          0x06    /* In .data segment */
#define N_BSS           0x08    /* In .bss segment */

#define N_INDR          0x0a
#define N_WEAKU         0x0d    /* Includes N_EXT! */

#define N_SETA          0x14
#define N_SETT          0x16
#define N_SETD          0x18

#define N_GSYM          0x20
#define N_FUN           0x24
#define N_STSYM         0x26
#define N_LCSYM         0x28
#define N_RSYM          0x40
#define N_SLINE         0x44
#define N_SO            0x64
#define N_LSYM          0x80
#define N_SOL           0x84
#define N_PSYM          0xa0
#define N_LBRAC         0xc0
#define N_RBRAC         0xe0

#define N_IMP1          0x68    /* Import reference (emx specific) */
#define N_IMP2          0x6a    /* Import definition (emx specific) */

/* The maximum OMF record size supported by OMF linkers.  This value
   includes the record type, length and checksum fields. */

#define MAX_REC_SIZE    1024

/* OMF record types.  To get the 32-bit variant of a record type, add
   REC32. */

#define THEADR          0x80    /* Translator module header record */
#define COMENT          0x88    /* Comment record */
#define MODEND          0x8a    /* Module end record */
#define EXTDEF          0x8c    /* External names definition record */
#define TYPDEF          0x8e    /* Type definition record */
#define PUBDEF          0x90    /* Public names definition record */
#define LINNUM          0x94    /* Line numbers record */
#define LNAMES          0x96    /* List of names record */
#define SEGDEF          0x98    /* Segment definition record */
#define GRPDEF          0x9a    /* Group definition record */
#define FIXUPP          0x9c    /* Fixup record */
#define LEDATA          0xa0    /* Logical enumerated data record */
#define LIDATA          0xa2    /* Logical iterated data record */
#define COMDEF          0xb0    /* Communal names definition record */
#define COMDAT          0xc2    /* Common block */
#define ALIAS           0xc6    /* Alias definition record */
#define LIBHDR          0xf0    /* Library header */
#define LIBEND          0xf1    /* Library end */

/* Add this constant (using the | operator) to get the 32-bit variant
   of a record type.  Some fields will contain 32-bit values instead
   of 16-bit values. */

#define REC32           0x01

/* BIND_OFFSET is the offset from the beginning of the emxbind patch
   area to the data fields of that area.  The first BIND_OFFSET bytes
   of the emxbind patch area are used for storing the emx version
   number. */

#define BIND_OFFSET         16


typedef unsigned char byte;
typedef unsigned short word;
typedef unsigned long dword;

/* The header of an a.out file. */

struct a_out_header
{
  word magic;                   /* Magic word, must be 0407 */
  byte machtype;                /* Machine type */
  byte flags;                   /* Flags */
  long text_size;               /* Length of text, in bytes */
  long data_size;               /* Length of initialized data, in bytes */
  long bss_size;                /* Length of uninitialized data, in bytes */
  long sym_size;                /* Length of symbol table, in bytes */
  long entry;                   /* Start address (entry point) */
  long trsize;                  /* Length of relocation info for text, bytes */
  long drsize;                  /* Length of relocation info for data, bytes */
};

/* This is the layout of a relocation table entry. */

struct reloc
{
  dword address;                /* Fixup location */
  dword symbolnum:24;           /* Symbol number or segment */
  dword pcrel:1;                /* Self-relative fixup if non-zero */
  dword length:2;               /* Fixup size (0: 1 byte, 1: 2, 2: 4 bytes) */
  dword ext:1;                  /* Reference to symbol or segment */
  dword unused:4;               /* Not used */
};

/* This is the layout of a symbol table entry. */

struct nlist
{
  dword string;                 /* Offset in string table */
  byte type;                    /* Type of the symbol */
  byte other;                   /* Other information */
  word desc;                    /* More information */
  dword value;                  /* Value (address) */
};

/* This is the header of a DOS executable file. */

struct exe1_header
{
  word magic;                   /* Magic number, "MZ" (0x5a4d) */
  word last_page;               /* Number of bytes in last page */
  word pages;                   /* Size of the file in 512-byte pages */
  word reloc_size;              /* Number of relocation entries */
  word hdr_size;                /* Size of header in 16-byte paragraphs */
  word min_alloc;               /* Minimum allocation (paragraphs) */
  word max_alloc;               /* Maximum allocation (paragraphs) */
  word ss, sp;                  /* Initial stack pointer */
  word chksum;                  /* Checksum */
  word ip, cs;                  /* Entry point */
  word reloc_ptr;               /* Location of the relocation table */
  word ovl;                     /* Overlay number */
};

/* This is an additional header of a DOS executable file.  It contains
   a pointer to the new EXE header. */

struct exe2_header
{
  word res1[16];                /* Reserved */
  word new_lo;                  /* Low word of the location of the header */
  word new_hi;                  /* High word of the location of the header */
};

/* This is the layout of the OS/2 LX header. */

struct os2_header
{
  word magic;                   /* Magic number, "LX" (0x584c) */
  byte byte_order;              /* Byte order */
  byte word_order;              /* Word order */
  dword level;                  /* Format level */
  word cpu;                     /* CPU type */
  word os;                      /* Operating system type */
  dword ver;                    /* Module version */
  dword mod_flags;              /* Module flags */
  dword mod_pages;              /* Number of pages in the EXE file */
  dword entry_obj;              /* Object number for EIP */
  dword entry_eip;              /* Entry point */
  dword stack_obj;              /* Object number for ESP */
  dword stack_esp;              /* Stack */
  dword pagesize;               /* System page size */
  dword pageshift;              /* Page offset shift */
  dword fixup_size;             /* Fixup section size */
  dword fixup_checksum;         /* Fixup section checksum */
  dword loader_size;            /* Loader section size */
  dword loader_checksum;        /* Loader section checksum */
  dword obj_offset;             /* Object table offset */
  dword obj_count;              /* Number of objects in module */
  dword pagemap_offset;         /* Object page table offset */
  dword itermap_offset;         /* Object iterated pages offset */
  dword rsctab_offset;          /* Resource table offset */
  dword rsctab_count;           /* Number of resource table entries */
  dword resname_offset;         /* Resident name table offset */
  dword entry_offset;           /* Entry table offset */
  dword moddir_offset;          /* Module directives offset */
  dword moddir_count;           /* Number of module directives */
  dword fixpage_offset;         /* Fixup page table offset */
  dword fixrecord_offset;       /* Fixup record table offset */
  dword impmod_offset;          /* Import module table offset */
  dword impmod_count;           /* Number of import module table entries */
  dword impprocname_offset;     /* Import procedure table offset */
  dword page_checksum_offset;   /* Per page checksum table offset */
  dword enum_offset;            /* Data pages offset */
  dword preload_count;          /* Number of preload pages */
  dword nonresname_offset;      /* Non-resident name table offset */
  dword nonresname_size;        /* Non-resident name table size */
  dword nonresname_checksum;    /* Non-resident name table checksum */
  dword auto_obj;               /* Auto data segment object number */
  dword debug_offset;           /* Debug information offset */
  dword debug_size;             /* Debug information size */
  dword instance_preload;       /* Number of instance preload pages */
  dword instance_demand;        /* Number of instance load-on-demand pages */
  dword heap_size;              /* Heap size */
  dword stack_size;             /* Stack size */
  dword reserved[5];            /* Reserved */
};

/* This is the layout of an object table entry. */

struct object
{
  dword virt_size;              /* Virtual size */
  dword virt_base;              /* Relocation base address */
  dword attr_flags;             /* Object attributes and flags */
  dword map_first;              /* Page table index */
  dword map_count;              /* Number of page table entries */
  dword reserved;               /* Reserved */
};

/* This is the layout of the emxbind patch area for DOS.  It is
   located at the beginning of the loadable image. */

struct dos_bind_header
{
  byte hdr[BIND_OFFSET];        /* emx version number */
  byte bind_flag;               /* Non-zero if this program is bound */
  byte fill_1;                  /* Padding for proper alignment */
  word hdr_loc_lo;              /* Location of the a.out header */
  word hdr_loc_hi;              /* (split into two words due to alignment) */
  byte options[64];             /* emx options to be used under DOS */
};

/* This is the layout of the emxbind patch area for OS/2.  It is
   located at the beginning of the data segment.  This table contains
   information required for dumping core and for forking. */

struct os2_bind_header
{
  dword text_base;              /* Base address of the text segment */
  dword text_end;               /* End address of the text segment */
  dword data_base;              /* Base address of initialized data */
  dword data_end;               /* End address of initialized data */
  dword bss_base;               /* Base address of uninitialized data */
  dword bss_end;                /* End address of uninitialized data */
  dword heap_base;              /* Base address of the heap */
  dword heap_end;               /* End address of the heap */
  dword heap_brk;               /* End address of the used heap space */
  dword heap_off;               /* Location of heap data in the executable */
  dword os2_dll;                /* Address of the import table for (I1) */
  dword stack_base;             /* Base address of the stack */
  dword stack_end;              /* End address of the stack */
  dword flags;                  /* Flags (DLL) and interface number */
  dword reserved[2];            /* Not yet used */
  byte options[64];             /* emx options to be used under OS/2 */
};

#pragma pack(1)

struct omf_rec
{
  byte rec_type;
  word rec_len;
};

#pragma pack()
#endif
