/* list.c -- List headers
   Copyright (c) 1991-1998 Eberhard Mattes

This file is part of emxbind.

emxbind is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2, or (at your option)
any later version.

emxbind is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with emxbind; see the file COPYING.  If not, write to
the Free Software Foundation, 59 Temple Place - Suite 330,
Boston, MA 02111-1307, USA.  */


#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "defs.h"
#include "emxbind.h"

#if LIST_OPT

/* A page map entry of the LX header. */

#pragma pack(1)
struct pagemap
{
  dword number;
  word size;
  word flags;
};
#pragma pack()


/* Location of the new EXE header. */

static long new_exe;

/* Offset in fixup record table. */

static long fixup_pos;

/* Array of imported module names. */

static char **mods;

/* List of imported procedure names. */

static unsigned char *proc_names;
static long proc_names_size;

/* Object page map. */

static struct pagemap *pagemap;


/* Show an offset into the LX header. */

static char *offset (long x)
{
  static char buf[100];
  int i;

  i = sprintf (buf, "0x%.8lx", x);
  if (x != 0)
    sprintf (buf + i, " (at 0x%.8lx)", x + new_exe);
  return buf;
}    

/* Show a module name. */

static void print_mod (long mod)
{
  if (mod < 1 || mod > os2_h.impmod_count)
    printf ("#%ld", mod);
  else
    printf ("%s", mods[mod-1]);
}

static void print_proc (long ord)
{
  if (ord < 0 || ord >= proc_names_size
      || (int)proc_names[ord] + ord + 1 > proc_names_size)
    printf ("#%ld", ord);
  else
    printf ("%.*s", (int)proc_names[ord], proc_names+ord+1);
}


/* Display a listing section heading. */

static void section (const char *msg)
{
  char ul[100];
  int i;

  i = strlen (msg);
  memset (ul, '-', i);
  ul[i] = 0;
  printf ("\n%s\n%s\n\n", msg, ul);
}


/* List object I. */

static void list_obj (long i)
{
  struct object obj;
  long j;

  my_read (&obj, sizeof (obj), &inp_file);
  printf ("Object %ld", i+1);
  if (i+1 == os2_h.auto_obj) printf (" (DGROUP)");
  if (i+1 == os2_h.entry_obj) printf (" (entry)");
  if (i+1 == os2_h.stack_obj) printf (" (stack)");
  printf (":\n");
  printf ("Virtual base address: 0x%.8lx\n", obj.virt_base);
  printf ("Virtual size:         0x%.8lx\n", obj.virt_size);
  printf ("Attribute flags:      0x%.8lx", obj.attr_flags);
  if (obj.attr_flags & 0x0001) printf (" read");
  if (obj.attr_flags & 0x0002) printf (" write");
  if (obj.attr_flags & 0x0004) printf (" exec");
  if (obj.attr_flags & 0x0008) printf (" resource");
  if (obj.attr_flags & 0x0010) printf (" disardable");
  if (obj.attr_flags & 0x0020) printf (" shared");
  if (obj.attr_flags & 0x0040) printf (" preload");
  if (obj.attr_flags & 0x0080) printf (" invalid");
  switch (obj.attr_flags & 0x0700)
    {
    case 0x0100: printf (" perm/swap"); break;
    case 0x0200: printf (" perm/res"); break;
    case 0x0300: printf (" res/cont"); break;
    case 0x0400: printf (" perm/long"); break;
    }
  if (obj.attr_flags & 0x1000) printf (" alias");
  if (obj.attr_flags & 0x2000) printf (" big");
  if (obj.attr_flags & 0x4000) printf (" conforming");
  if (obj.attr_flags & 0x8000) printf (" iopl");
  fputchar ('\n');
  printf ("Page map index:       %ld\n", obj.map_first);
  printf ("Page map entries:     %ld\n", obj.map_count);
  for (j = 0; j < obj.map_count; ++j)
    printf ("  %4ld: %4ld 0x%.4x 0x%.4x\n",
            obj.map_first + j,
            (long)pagemap[obj.map_first+j-1].number,
            (int)pagemap[obj.map_first+j-1].size,
            (int)pagemap[obj.map_first+j-1].flags);
  if (i+1 < os2_h.obj_count) fputchar ('\n');
}


/* List fixup I. */

static void list_fixup (long i)
{
  long mod, ord;
  byte b, type, flags, cnt;
  word w, src;
  dword d;
  int j;

  my_read (&type, sizeof (type), &inp_file);
  my_read (&flags, sizeof (flags), &inp_file);
  fixup_pos += sizeof (type) + sizeof (flags);
  if (type & NRCHAIN)
    {
      my_read (&cnt, sizeof (cnt), &inp_file);
      fixup_pos += sizeof (cnt);
      printf ("Source=list(%3d), ", cnt);
    }
  else
    {
      my_read (&src, sizeof (src), &inp_file);
      fixup_pos += sizeof (src);
      printf ("Source=0x%.8lx, ", (i << 12) + src + TEXT_BASE);
    }
  switch (type & NRSTYP)
    {
    case NRSBYT:
      printf ("8-bit byte");
      break;
    case NRSSEG:
      printf ("16-bit selector");
      break;
    case NRSPTR:
      printf ("16:16 pointer");
      break;
    case NRSOFF:
      printf ("16-bit offset");
      break;
    case NRPTR48:
      printf ("16:32 pointer");
      break;
    case NROFF32:
      printf ("32-bit offset");
      break;
    case NRSOFF32:
      printf ("32-bit self-relative");
      break;
    default:
      printf ("unknown (0x%x)", type & NRSTYP);
      break;
    }
  if (type & NRALIAS)
    printf (", 16:16 alias");
  printf (", ");
  switch (flags & NRRTYP)
    {
    case NRRINT:
      if (flags & NR16OBJMOD)
        {
          my_read (&w, sizeof (w), &inp_file);
          fixup_pos += sizeof (w);
        }
      else
        {
          my_read (&b, sizeof (b), &inp_file);
          fixup_pos += sizeof (b);
          w = b;
        }
      printf ("internal, object %u", w);
      if ((type & NRSTYP) != NRSSEG)
        {
          if (flags & NR32BITOFF)
            {
              my_read (&d, sizeof (d), &inp_file);
              fixup_pos += sizeof (d);
              printf (", offset 0x%.8lx", d);
            }
          else
            {
              my_read (&w, sizeof (w), &inp_file);
              fixup_pos += sizeof (w);
              printf (", offset 0x%.4x", w);
            }
        }
      break;
    case NRRORD:
      if (flags & NR16OBJMOD)
        {
          my_read (&w, sizeof (w), &inp_file);
          fixup_pos += sizeof (w);
          mod = w;
        }
      else
        {
          my_read (&b, sizeof (b), &inp_file);
          fixup_pos += sizeof (b);
          mod = b;
        }
      if (flags & NR8BITORD)
        {
          my_read (&b, sizeof (b), &inp_file);
          fixup_pos += sizeof (b);
          ord = b;
        }
      else
        {
          my_read (&w, sizeof (w), &inp_file);
          fixup_pos += sizeof (w);
          ord = w;
        }
      print_mod (mod);
      printf (".%ld", ord);
      break;
    case NRRNAM:
      if (flags & NR16OBJMOD)
        {
          my_read (&w, sizeof (w), &inp_file);
          fixup_pos += sizeof (w);
          mod = w;
        }
      else
        {
          my_read (&b, sizeof (b), &inp_file);
          fixup_pos += sizeof (b);
          mod = b;
        }
      my_read (&w, sizeof (w), &inp_file);
      fixup_pos += sizeof (w);
      ord = w;
      print_mod (mod);
      printf (".");
      print_proc (ord);
      break;
    default:
      printf ("unknown (0x%x)", flags & NRRTYP);
      break;
    }
  if (flags & NRADD)
    {
      if (flags & NR32BITADD)
        {
          my_read (&d, sizeof (d), &inp_file);
          fixup_pos += sizeof (d);
          printf (" +0x%.8lx", d);
        }
      else
        {
          my_read (&w, sizeof (w), &inp_file);
          fixup_pos += sizeof (w);
          printf (" +0x%.4x", w);
        }
    }
  printf ("\n");
  if (type & NRCHAIN)
    {
      for (j = 0; j < (int)cnt; ++j)
        {
          if (j % 6 == 0)
            printf (" ");
          my_read (&src, sizeof (src), &inp_file);
          fixup_pos += sizeof (src);
          printf (" 0x%.8lx", (i << 12) + src + TEXT_BASE);
          if (j % 6 == 5)
            printf ("\n");
        }
      if (j % 6 != 0)
        printf ("\n");
    }
}


/* List the LX header. */

static void list_lx (void)
{
  long i, j;
  byte buf[257];
  dword *fixpage;
#pragma pack(1)
  struct
    {
      word type;
      word id;
      dword length;
      word obj;
      dword offset;
    } exeres;
#pragma pack(4)
  byte b;

  section ("LX header:");
  my_seek (&inp_file, new_exe);
  my_read (&os2_h, sizeof (os2_h), &inp_file);
  printf ("Module flags:                       0x%.8lx\n", os2_h.mod_flags);
  printf ("Module pages:                       %ld\n", os2_h.mod_pages);
  printf ("Entry point:                        %ld#0x%.8lx\n", os2_h.entry_obj, os2_h.entry_eip);
  printf ("Initial stack pointer:              %ld#0x%.8lx\n", os2_h.stack_obj, os2_h.stack_esp);
  printf ("Page size in EXE file:              0x%.8lx\n", os2_h.pagesize);
  printf ("Fixup section size:                 0x%.8lx\n", os2_h.fixup_size);
  printf ("Fixup section checksum:             0x%.8lx\n", os2_h.fixup_checksum);
  printf ("Loader section size:                0x%.8lx\n", os2_h.loader_size);
  printf ("Loader section checksum:            0x%.8lx\n", os2_h.loader_checksum);
  printf ("Object table offset:                %s\n", offset (os2_h.obj_offset));
  printf ("Number of objects:                  %ld\n", os2_h.obj_count);
  printf ("Object page map offset:             %s\n", offset (os2_h.pagemap_offset));
  printf ("Iterated data map offset:           %s\n", offset (os2_h.itermap_offset));
  printf ("Resource table offset:              %s\n", offset (os2_h.rsctab_offset));
  printf ("Resource table entries:             %ld\n", os2_h.rsctab_count);
  printf ("Resident name table offset:         %s\n", offset (os2_h.resname_offset));
  printf ("Entry table offset:                 %s\n", offset (os2_h.entry_offset));
  printf ("Module directives table offset:     %s\n", offset (os2_h.moddir_offset));
  printf ("Module directives table entries:    %ld\n", os2_h.moddir_count);
  printf ("Fixup page table offset:            %s\n", offset (os2_h.fixpage_offset));
  printf ("Fixup record table offset:          %s\n", offset (os2_h.fixrecord_offset));
  printf ("Import module name table offset:    %s\n", offset (os2_h.impmod_offset));
  printf ("Import module name table entries:   %ld\n", os2_h.impmod_count);
  printf ("Import procedure name table offset: %s\n", offset (os2_h.impprocname_offset));
  printf ("Per-page checksum table offset:     %s\n", offset (os2_h.page_checksum_offset));
  printf ("Enumerated data pages offset:       %s\n", offset (os2_h.enum_offset));
  printf ("Preload pages:                      %ld\n", os2_h.preload_count);
  printf ("Non-resident names table offset:    %s (0x%.8lx bytes)\n", offset (os2_h.nonresname_offset), os2_h.nonresname_size);
  printf ("Non-resident names table checksum:  0x%.8lx\n", os2_h.nonresname_checksum);
  printf ("Automatic data object:              %ld\n", os2_h.auto_obj);
  printf ("Debugging information offset:       %s (0x%.8lx bytes)\n", offset (os2_h.debug_offset), os2_h.debug_size);
  printf ("Instance pages in preload section:  %ld\n", os2_h.instance_preload);
  printf ("Instance pages in demand section:   %ld\n", os2_h.instance_demand);
  printf ("Heap size:                          0x%.8lx\n", os2_h.heap_size);

  j = sizeof (struct pagemap) * os2_h.mod_pages;
  pagemap = xmalloc (j);
  my_seek (&inp_file, new_exe + os2_h.pagemap_offset);
  my_read (pagemap, j, &inp_file);

  section ("Objects:");
  my_seek (&inp_file, new_exe + os2_h.obj_offset);
  for (i = 0; i < os2_h.obj_count; ++i)
    list_obj (i);

  fixpage = xmalloc (sizeof (dword) * (os2_h.mod_pages + 1));
  mods = xmalloc (sizeof (char *) * os2_h.impmod_count);
  my_seek (&inp_file, new_exe + os2_h.fixpage_offset);
  my_read (fixpage, sizeof (dword) * (os2_h.mod_pages + 1), &inp_file);
  my_seek (&inp_file, new_exe + os2_h.impmod_offset);
  for (i = 0; i < os2_h.impmod_count; ++i)
    {
      my_read (&b, 1, &inp_file);
      my_read (buf, b, &inp_file);
      buf[b] = 0;
      mods[i] = xstrdup ((char *)buf);
    }
  proc_names_size = os2_h.fixup_size - (os2_h.impprocname_offset
                                        - os2_h.fixpage_offset);
  proc_names = xmalloc (proc_names_size);
  my_seek (&inp_file, new_exe + os2_h.impprocname_offset);
  my_read (proc_names, proc_names_size, &inp_file);
  if (os2_h.rsctab_count != 0)
    {
      section ("Resources:");
      my_seek (&inp_file, new_exe + os2_h.rsctab_offset);
      for (i = 0; i < os2_h.rsctab_count; ++i)
	{
	  my_read (&exeres, sizeof (exeres), &inp_file);
	  printf ("id:%5d, type:%3d, size:%5ld, object:%2d, offset: 0x%.8lx\n",
                  exeres.id, exeres.type, exeres.length, exeres.obj,
                  exeres.offset);
	}
    }
  if (os2_h.impmod_count != 0)
    {
      section ("Imported modules:");
      for (i = 0; i < os2_h.impmod_count; ++i)
        printf ("%2ld: %s\n", i + 1, mods[i]);
    }

  if (proc_names_size != 0)
    {
      section ("Imported procedures:");
      i = 0;
      while (i < proc_names_size && proc_names[i] + i + 1 <= proc_names_size)
        {
          printf ("%6ld: %.*s\n", i, (int)proc_names[i], proc_names + i + 1);
          i += proc_names[i] + 1;
        }
    }

  section ("Fixup page table:");

  for (i = 0; i < os2_h.mod_pages; ++i)
    printf ("Page %4ld: 0x%.8lx - 0x%.8lx\n",
            i, fixpage[i], fixpage[i+1]);

  section ("Fixup record table:");
  fixup_pos = 0;
  for (i = 0; i < os2_h.mod_pages; ++i)
    if (fixpage[i+1] > fixpage[i])
      {
	fixup_pos = fixpage[i];
	my_seek (&inp_file, new_exe + os2_h.fixrecord_offset + fixup_pos);
	while (fixup_pos < fixpage[i+1])
          list_fixup (i);
      }

  section ("OS/2 emxbind header:");
  printf ("Text base:   0x%.8lx\n", os2_bind_h.text_base);
  printf ("Text end:    0x%.8lx\n", os2_bind_h.text_end);
  printf ("Data base:   0x%.8lx\n", os2_bind_h.data_base);
  printf ("Data end:    0x%.8lx\n", os2_bind_h.data_end);
  printf ("Bss base:    0x%.8lx\n", os2_bind_h.bss_base);
  printf ("Bss end:     0x%.8lx\n", os2_bind_h.bss_end);
  printf ("Heap base:   0x%.8lx\n", os2_bind_h.heap_base);
  printf ("Heap end:    0x%.8lx\n", os2_bind_h.heap_end);
  printf ("Heap brk:    0x%.8lx\n", os2_bind_h.heap_brk);
  printf ("Heap offset: 0x%.8lx\n", os2_bind_h.heap_off);
  printf ("Stack base:  0x%.8lx\n", os2_bind_h.stack_base);
  printf ("Stack end:   0x%.8lx\n", os2_bind_h.stack_end);
  printf ("OS/2 DLL:    0x%.8lx\n", os2_bind_h.os2_dll);
  printf ("Flags:       0x%.8lx\n", os2_bind_h.flags);
  printf ("Options:     %s\n", (char *)os2_bind_h.options);
}


/* List the headers. */

void list (void)
{
  long dos_image, dos_size;
  byte buf[2];

  section ("MS-DOS exe header:");
  dos_image = (long)inp_h1.hdr_size << 4;
  dos_size = ((long)inp_h1.pages << 9) - dos_image;
  if (inp_h1.last_page != 0)
    dos_size += inp_h1.last_page - 512;
  printf ("Real-mode image at:       0x%.4lx (0x%.4lx bytes)\n", dos_image, dos_size);
  printf ("Relocation table at:      0x%.4x\n", (int)inp_h1.reloc_ptr);
  printf ("Relocation table entries: %d\n", (int)inp_h1.reloc_size);
  printf ("Minimum allocation:       0x%.4x paragraphs\n", (int)inp_h1.min_alloc);
  printf ("Maximum allocation:       0x%.4x paragraphs\n", (int)inp_h1.max_alloc);
  printf ("Initial stack pointer:    0x%.4x:0x%.4x\n", (int)inp_h1.ss, (int)inp_h1.sp);
  printf ("Entry point:              0x%.4x:0x%.4x\n", (int)inp_h1.cs, (int)inp_h1.ip);
  printf ("Checksum:                 0x%.4x\n", (int)inp_h1.chksum);
  if (inp_h1.reloc_ptr < sizeof (inp_h1) + sizeof (inp_h2))
    {
      puts ("Old executable");
      return;
    }
  my_seek (&inp_file, sizeof (inp_h1));
  my_read (&inp_h2, sizeof (inp_h2), &inp_file);
  new_exe = COMBINE (inp_h2.new_lo, inp_h2.new_hi);
  printf ("New EXE header at:        0x%lx\n", new_exe);
  my_seek (&inp_file, new_exe);
  my_read (buf, 2, &inp_file);
  if (buf[0] >= 'A' && buf[0] <= 'Z' && buf[1] >= 'A' && buf[1] <= 'Z')
    printf ("New executable type:      %c%c\n", buf[0], buf[1]);
  if (is_bound)
    {
      section ("MS-DOS emxbind header:");
      printf ("Version:                  %s\n", (char *)dos_bind_h.hdr);
      printf ("Bound:                    %s\n", (dos_bind_h.bind_flag != 0 ? "Yes" : "No"));
      printf ("a.out header offset:      0x%.8lx\n", (long)a_in_pos);
      printf ("Options:                  %s\n",
		    (char *)dos_bind_h.options);
      section ("a.out header:");
      printf ("Magic word:               0x%.4x\n", (int)a_in_h.magic);
      printf ("Machine type:             0x%.2x\n", (int)a_in_h.machtype);
      printf ("Flags:                    0x%.2x\n", (int)a_in_h.flags);
      printf ("Text size:                0x%.8lx\n", a_in_h.text_size);
      printf ("Data size:                0x%.8lx\n", a_in_h.data_size);
      printf ("Bss size:                 0x%.8lx\n", a_in_h.bss_size);
      printf ("Symbols size:             0x%.8lx\n", a_in_h.sym_size);
      printf ("Entry point:              0x%.8lx\n", a_in_h.entry);
      printf ("Text relocation size:     0x%.8lx\n", a_in_h.trsize);
      printf ("Data relocation size:     0x%.8lx\n", a_in_h.drsize);
    }
  if (buf[0] == 'L' && buf[1] == 'X')
    list_lx ();
}

#endif /* LIST_OPT */
