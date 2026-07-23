/* cmd.c -- Handle commands
   Copyright (c) 1991-1995 Eberhard Mattes

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


/* Alter the emx options of a bound executable. */

static void alter (void)
{
  set_options ();
  my_seek (&inp_file, patch_pos);
  my_write (&dos_bind_h, sizeof (dos_bind_h), &inp_file);
  my_seek (&inp_file, a_in_pos + a_in_data);
  my_write (&os2_bind_h, sizeof (os2_bind_h), &inp_file);
}


/* Perform initializations for the bind operation. */

static void init_bind (void)
{
  if (dll_flag)
    {
      relocatable = TRUE;
      stack_size = 0;
    }
}


/* Change the application type. */

static void exe_type (void)
{
  read_os2_header ();
  exe_flags ();
  my_change (&out_file, &inp_file);
  my_seek (&out_file, inp_os2_pos);
  my_write (&os2_h, sizeof (os2_h), &out_file);
}


/* Show the emx options of a bound executable. */

static void show (void)
{
  if (dos_bind_h.options[0] != 0)
    printf ("emx options for MS-DOS: %s\n", (char *)dos_bind_h.options);
  if (os2_bind_h.options[0] != 0)
    printf ("emx options for OS/2:   %s\n", (char *)os2_bind_h.options);
}


/* Strip the symbols from a bound executable. */

static void strip_symbols (void)
{
  long size, pos, str_len;

  pos = a_in_pos + a_in_sym;
  size = my_size (&inp_file);
  if (pos + sizeof (str_len) <= size)
    {
      my_seek (&inp_file, pos);
      str_len = 4;
      my_write (&str_len, sizeof (str_len), &inp_file);
      my_trunc (&inp_file);
      a_in_h.sym_size = 0;
      my_seek (&inp_file, a_in_pos);
      my_write (&a_in_h, sizeof (a_in_h), &inp_file);
    }
}


/* Update emxl.exe or emx.exe in a bound executable. */

static void update (void)
{
  long size, i;
  byte *buf;

  read_os2_header ();
  set_exe_header ();
  i = (inp_os2_pos & 0xfff) - (os2_hdr_pos & 0xfff);
  if (i != 0)
    {
      if (i < 0)
	i += 0x1000;
      os2_hdr_pos += i; fill2 += i;
    }
  out_h2.new_lo = LOWORD (os2_hdr_pos);
  out_h2.new_hi = HIWORD (os2_hdr_pos);
  size = my_size (&inp_file) - inp_os2_pos - sizeof (os2_h);
  a_out_pos = a_in_pos - inp_os2_pos + os2_hdr_pos;
  os2_h.enum_offset += os2_hdr_pos - inp_os2_pos;
  if (os2_h.nonresname_size != 0)
    os2_h.nonresname_offset += os2_hdr_pos - inp_os2_pos;
  dos_bind_h.hdr_loc_lo = LOWORD (a_out_pos);
  dos_bind_h.hdr_loc_hi = HIWORD (a_out_pos);
  os2_bind_h.heap_off += os2_hdr_pos - inp_os2_pos;
  memmove (dos_bind_h.hdr, emx_bind_h.hdr, sizeof (dos_bind_h.hdr));
  buf = xmalloc (size);
  my_seek (&inp_file, inp_os2_pos + sizeof (os2_h));
  my_read (buf, size, &inp_file);
  my_change (&out_file, &inp_file);
  write_header ();
  my_write (&os2_h, sizeof (os2_h), &out_file);
  my_write (buf, size, &out_file);
  my_trunc (&out_file);
  write_bind_header ();
}


/* Extract the a.out subfile of a bound executable. */

static void extract (void)
{
  long hdr_loc, size;

  hdr_loc = COMBINE (dos_bind_h.hdr_loc_lo, dos_bind_h.hdr_loc_hi);
  size = my_size (&inp_file) - hdr_loc;
  my_seek (&inp_file, hdr_loc);
  copy (&inp_file, size);
}


void cmd (int mode)
{
  switch (mode)
    {
    case 'a':

      /* Alter emxbind options. */

      check_bound ();
      alter ();
      break;

    case 'b':

      /* Bind an a.out file into an .exe file. */

      init_bind ();
      init_os2_header ();
      read_emx ();
      read_a_out_header ();
      if (opt_c != NULL)
	read_core ();
      read_res ();
      os2_fixup ();
      relocations ();
      sort_fixup ();
      set_exe_header ();
      set_os2_header ();
      set_dos_bind_header ();
      write_header ();
      write_res ();
      copy_a_out ();
      write_nonres ();
      write_bind_header ();
      if (opt_m != NULL)
        write_map (opt_m);
      break;

    case 'e':

      /* Set the OS/2 application type. */

      check_bound ();
      exe_type ();
      break;

#if LIST_OPT
    case 'L':

      /* List the headers. */

      check_bound ();
      list ();
      break;
#endif
    case 'i':

      /* Show the emxbind options. */

      check_bound ();
      show ();
      break;

    case 's':

      /* Strip symbols. */

      check_bound ();
      strip_symbols ();
      break;

    case 'u':

      /* Update emxl.exe or emx.exe in a bound executable. */

      read_emx ();

      /* Call check_bound() *after* read_emx() as it needs dos_bind_h! */

      check_bound ();
      update ();
      break;

    case 'x':

      /* Extract the a.out file of a bound executable. */

      check_bound ();
      extract ();
      break;

    default:
      abort ();
    }
}
