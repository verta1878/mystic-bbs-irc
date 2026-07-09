const char *optswchar = "-";

/* --- emx filename/path helpers, implemented for Linux --------------------- */
#include <stdio.h>
#include <string.h>
#include <strings.h>
#include <stdlib.h>
#include <unistd.h>

/* _fsopen: fopen with a share flag (share flag ignored on Linux). */
FILE *_fsopen(const char *name, const char *mode, int shflag){
  (void)shflag;
  return fopen(name, mode);
}

/* Return pointer to the base name (after last / or \). */
static char *base_of(char *p){
  char *b = p, *s;
  for (s = p; *s; s++) if (*s=='/'||*s=='\\') b = s+1;
  return b;
}

/* _remext: remove the filename extension in place. */
void _remext(char *path){
  char *b = base_of(path);
  char *dot = strrchr(b, '.');
  if (dot && dot != b) *dot = '\0';
}

/* _defext: add extension `ext` (no dot) if the file has none. */
void _defext(char *path, const char *ext){
  char *b = base_of(path);
  if (strchr(b, '.') == NULL){
    strcat(path, ".");
    strcat(path, ext);
  }
}

/* _path: search PATH for `name`; on success copy full path to dst, return 0. */
int _path(char *dst, const char *name){
  const char *pe = getenv("PATH");
  char trial[1024];
  if (access(name, F_OK) == 0){ strcpy(dst, name); return 0; }
  if (!pe) return -1;
  while (*pe){
    const char *colon = strchr(pe, ':');
    size_t len = colon ? (size_t)(colon - pe) : strlen(pe);
    if (len > 0 && len < sizeof(trial)-strlen(name)-2){
      memcpy(trial, pe, len);
      trial[len] = '/';
      strcpy(trial+len+1, name);
      if (access(trial, F_OK) == 0){ strcpy(dst, trial); return 0; }
    }
    if (!colon) break;
    pe = colon + 1;
  }
  return -1;
}

/* _fncmp: compare two file names (case-insensitive; treat \ and / alike). */
int _fncmp(const char *a, const char *b){
  for (;;){
    char ca = *a++, cb = *b++;
    if (ca=='\\') ca='/';
    if (cb=='\\') cb='/';
    if (ca>='A'&&ca<='Z') ca += 32;
    if (cb>='A'&&cb<='Z') cb += 32;
    if (ca != cb) return (unsigned char)ca - (unsigned char)cb;
    if (ca == '\0') return 0;
  }
}
