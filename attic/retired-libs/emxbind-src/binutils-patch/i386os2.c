/* BFD back-end for i386 a.out binaries.
   Copyright (C) 1990-2018 Free Software Foundation, Inc.

   This file is part of BFD, the Binary File Descriptor library.

   This program is free software; you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation; either version 3 of the License, or
   (at your option) any later version.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program; if not, write to the Free Software
   Foundation, Inc., 51 Franklin Street - Fifth Floor, Boston,
   MA 02110-1301, USA.  */


/* The only 386 aout system we have here is GO32 from DJ.
   These numbers make BFD work with that. If your aout 386 system
   doesn't work with these, we'll have to split them into different
   files.  Send me (sac@cygnus.com) the runes to make it work on your
   system, and I'll stick it in for the next release.  */

#define N_HEADER_IN_TEXT(x)	0
#define N_TXTOFF(x)		0x400
#define N_TXTADDR(x)		0x10000
#define N_TXTSIZE(x)		((x)->a_text)
#define TARGET_PAGE_SIZE	4096
#define SEGMENT_SIZE		0x10000
#define ZMAGIC_DISK_BLOCK_SIZE	0x400
#define DEFAULT_ARCH		bfd_arch_i386

/* Do not "beautify" the CONCAT* macro args.  Traditional C will not
   remove whitespace added here, and thus will fail to concatenate
   the tokens.  */
#define MY(OP) CONCAT2 (i386_os2_,OP)
#define TARGETNAME "a.out-emx"
#define NO_WRITE_HEADER_KLUDGE 1

#include "sysdep.h"
#include "bfd.h"
#include "libbfd.h"
#include "aout/aout64.h"
#include "libaout.h"

/* Set the machine type correctly.  */

static bfd_boolean
i386os2_write_object_contents (bfd *abfd)
{
  struct external_exec exec_bytes;
  struct internal_exec *execp = exec_hdr (abfd);

  N_SET_MACHTYPE (execp, M_386);

  obj_reloc_entry_size (abfd) = RELOC_STD_SIZE;

  /* emx/OS2: FPC's prt0 bakes an os2_bind_header whose text_end/data_base are
     computed from the UNPADDED text size.  BFD pads .text up to a page in
     a_text; record the unpadded size (rawsize) in the header so emxbind's
     startup-data check (text_end == TEXT_BASE + a_text) matches.  Data layout
     is unaffected (it keys off the page-aligned filepos, not a_text).  */
  if (obj_textsec (abfd) != NULL && obj_textsec (abfd)->rawsize != 0)
    execp->a_text = obj_textsec (abfd)->rawsize;

  WRITE_HEADERS (abfd, execp);

  return TRUE;
}

#define MY_write_object_contents  i386os2_write_object_contents
#define MY_backend_data		  & MY (backend_data)

static const struct aout_backend_data MY (backend_data);

#include "aout-target.h"

static const struct aout_backend_data MY (backend_data) =
{
  0,				/* Zmagic contiguous.  */
  0,				/* Text incl header (0 -> use zmagic_disk_block_size = 0x400).  */
  0,				/* Entry is text address.  */
  0,				/* Exec_hdr_flags.  */
  0,				/* Text vma?  */
  MY (set_sizes),
  1,				/* Exec header not counted.  */
  0,				/* Add_dynamic_symbols.  */
  0,				/* Add_one_symbol.  */
  0,				/* Link_dynamic_object.  */
  0,				/* Write_dynamic_symbol.  */
  0,				/* Check_dynamic_reloc.  */
  0				/* Finish_dynamic_link.  */
};
