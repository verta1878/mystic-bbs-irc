// ====================================================================
// mystic_spell : optional spell-check add-on for Mystic BBS A38
// ====================================================================
//
// This file is part of an optional add-on module for Mystic BBS and is
// released under the same GNU General Public License v3 as Mystic BBS.
// Mystic BBS is Copyright 1997-2013 By James Coyle.
//
// spl_hunspell - a thin Pascal binding to the Hunspell library, loaded at
// RUNTIME (dlopen / LoadLibrary) so this unit compiles with no Hunspell
// present and fails gracefully if the library is missing.  This mirrors how
// Mystic 1.12 ships spell checking: the sysop drops the Hunspell shared
// library (libhunspell*.so / hunspell*.dll) into place.
//
// Only the handful of Hunspell C entry points we need are bound.
// ====================================================================

Unit spl_Hunspell;

{$IFDEF FPC}{$MODE OBJFPC}{$H+}{$ENDIF}

Interface

Uses
  {$IFDEF WINDOWS} Windows, {$ENDIF}
  SysUtils;

{$IFDEF UNIX}
// Modern glibc (2.34+) folds dlopen/dlsym/dlclose into libc, and FPC 2.6.2's
// legacy `dl` unit links the old standalone libdl which is now only a stub.
// Declare them directly against libc so they resolve where the symbols live.
Const
  RTLD_NOW = 2;
Function dlopen (Name: PChar; Flags: LongInt): Pointer; cdecl; external 'c';
Function dlsym (Handle: Pointer; Name: PChar): Pointer; cdecl; external 'c';
Function dlclose (Handle: Pointer): LongInt; cdecl; external 'c';
{$ENDIF}

Type
  THunHandle = Pointer;

  // Hunspell C API (the subset we use):
  //   Hunhandle* Hunspell_create(const char* affpath, const char* dpath);
  //   void       Hunspell_destroy(Hunhandle*);
  //   int        Hunspell_spell(Hunhandle*, const char* word);
  //   int        Hunspell_suggest(Hunhandle*, char*** slst, const char* word);
  //   void       Hunspell_free_list(Hunhandle*, char*** slst, int n);
  //   int        Hunspell_add(Hunhandle*, const char* word);
  TFnCreate   = Function (affpath, dpath: PChar): THunHandle; cdecl;
  TFnDestroy  = Procedure (h: THunHandle); cdecl;
  TFnSpell    = Function (h: THunHandle; word: PChar): LongInt; cdecl;
  TFnSuggest  = Function (h: THunHandle; Var slst: PPChar; word: PChar): LongInt; cdecl;
  TFnFreeList = Procedure (h: THunHandle; Var slst: PPChar; n: LongInt); cdecl;
  TFnAdd      = Function (h: THunHandle; word: PChar): LongInt; cdecl;

Var
  Hunspell_create   : TFnCreate   = Nil;
  Hunspell_destroy  : TFnDestroy  = Nil;
  Hunspell_spell    : TFnSpell    = Nil;
  Hunspell_suggest  : TFnSuggest  = Nil;
  Hunspell_free_list: TFnFreeList = Nil;
  Hunspell_add      : TFnAdd      = Nil;

// Try to load the Hunspell library.  LibName may be '' to try platform
// defaults.  Returns True if the library and all needed symbols were found.
Function LoadHunspell (Const LibName: String = ''): Boolean;
Procedure UnloadHunspell;
Function HunspellLoaded: Boolean;

Implementation

Var
  LibHandle : {$IFDEF UNIX} Pointer {$ELSE} HModule {$ENDIF} = Nil;
  Loaded    : Boolean = False;

Function Sym (Const Name: String): Pointer;
Begin
  {$IFDEF UNIX}
    Sym := dlsym(LibHandle, PChar(Name));
  {$ELSE}
    Sym := GetProcAddress(LibHandle, PChar(Name));
  {$ENDIF}
End;

Function TryOpen (Const N: String): Boolean;
Begin
  {$IFDEF UNIX}
    LibHandle := dlopen(PChar(N), RTLD_NOW);
  {$ELSE}
    LibHandle := LoadLibrary(PChar(N));
  {$ENDIF}
  TryOpen := LibHandle <> Nil;
End;

Function LoadHunspell (Const LibName: String): Boolean;

  Function DefaultNames: Boolean;
  Begin
    Result := True;
    {$IFDEF UNIX}
      If TryOpen('libhunspell-1.7.so.0') Then Exit;
      If TryOpen('libhunspell-1.6.so.0') Then Exit;
      If TryOpen('libhunspell.so')       Then Exit;
    {$ELSE}
      If TryOpen('libhunspell.dll')      Then Exit;
      If TryOpen('hunspell.dll')         Then Exit;
      If TryOpen('hunspell-1.7.dll')     Then Exit;
    {$ENDIF}
    Result := False;
  End;

Begin
  Result := False;
  If Loaded Then Begin Result := True; Exit; End;

  If LibName <> '' Then Begin
    If Not TryOpen(LibName) Then Exit;
  End Else
    If Not DefaultNames Then Exit;

  Hunspell_create    := TFnCreate  (Sym('Hunspell_create'));
  Hunspell_destroy   := TFnDestroy (Sym('Hunspell_destroy'));
  Hunspell_spell     := TFnSpell   (Sym('Hunspell_spell'));
  Hunspell_suggest   := TFnSuggest (Sym('Hunspell_suggest'));
  Hunspell_free_list := TFnFreeList(Sym('Hunspell_free_list'));
  Hunspell_add       := TFnAdd     (Sym('Hunspell_add'));

  // The create/destroy/spell/suggest set is the minimum we require.
  If (Hunspell_create = Nil) or (Hunspell_destroy = Nil) or
     (Hunspell_spell = Nil)  or (Hunspell_suggest = Nil) Then Begin
    UnloadHunspell;
    Exit;
  End;

  Loaded := True;
  Result := True;
End;

Procedure UnloadHunspell;
Begin
  If LibHandle <> Nil Then Begin
    {$IFDEF UNIX} dlclose(LibHandle); {$ELSE} FreeLibrary(LibHandle); {$ENDIF}
    LibHandle := Nil;
  End;
  Hunspell_create := Nil; Hunspell_destroy := Nil;
  Hunspell_spell := Nil;  Hunspell_suggest := Nil;
  Hunspell_free_list := Nil; Hunspell_add := Nil;
  Loaded := False;
End;

Function HunspellLoaded: Boolean;
Begin
  HunspellLoaded := Loaded;
End;

End.
