// ====================================================================
// mystic_crypt : optional cryptlib (SSH/TLS) example for Mystic BBS A38
// ====================================================================
//
// This file is part of an optional add-on module for Mystic BBS and is
// released under the same GNU General Public License v3 as Mystic BBS.
// Mystic BBS is Copyright 1997-2013 By James Coyle.
//
// cl_bind - a minimal cryptlib binding, loaded at RUNTIME (dlopen /
// LoadLibrary) so this unit compiles with no cryptlib present and fails
// gracefully if the library is missing.  Same drop-in-the-library model as
// Hunspell/SDL and the way stock Mystic loads cl32.dll.
//
// Entry-point names are taken from the stock Mystic binary, so a real
// cl32.dll / libcl is a drop-in.  Only the session subset is bound.
// ====================================================================

Unit cl_Bind;

{$IFDEF FPC}{$MODE OBJFPC}{$H+}{$ENDIF}

Interface

Uses
  {$IFDEF WINDOWS} Windows, {$ENDIF}
  {$IFDEF OS2} DosCalls, {$ENDIF}
  SysUtils;

{$IFDEF UNIX}
Const
  RTLD_NOW = 2;
Function dlopen (Name: PChar; Flags: LongInt): Pointer; cdecl; external 'c';
Function dlsym (Handle: Pointer; Name: PChar): Pointer; cdecl; external 'c';
Function dlclose (Handle: Pointer): LongInt; cdecl; external 'c';
{$ENDIF}

Type
  // cryptlib handles are ints; attributes and status are ints too.
  TCryptHandle = LongInt;

  // C prototypes (cdecl) for the session subset:
  //   int cryptInit(void);
  //   int cryptEnd(void);
  //   int cryptCreateSession(CRYPT_SESSION*, CRYPT_USER, CRYPT_SESSION_TYPE);
  //   int cryptDestroySession(CRYPT_SESSION);
  //   int cryptSetAttribute(CRYPT_HANDLE, CRYPT_ATTRIBUTE_TYPE, int);
  //   int cryptSetAttributeString(CRYPT_HANDLE, CRYPT_ATTRIBUTE_TYPE, const void*, int);
  //   int cryptGetAttribute(CRYPT_HANDLE, CRYPT_ATTRIBUTE_TYPE, int*);
  //   int cryptPushData(CRYPT_HANDLE, const void*, int, int*);
  //   int cryptPopData (CRYPT_HANDLE, void*, int, int*);
  TFnInit       = Function : LongInt; cdecl;
  TFnEnd        = Function : LongInt; cdecl;
  TFnCreateSess = Function (Var sess: TCryptHandle; user: TCryptHandle; stype: LongInt): LongInt; cdecl;
  TFnDestroySess= Function (sess: TCryptHandle): LongInt; cdecl;
  TFnSetAttr    = Function (h: TCryptHandle; attr, value: LongInt): LongInt; cdecl;
  TFnSetAttrStr = Function (h: TCryptHandle; attr: LongInt; value: Pointer; len: LongInt): LongInt; cdecl;
  TFnGetAttr    = Function (h: TCryptHandle; attr: LongInt; Var value: LongInt): LongInt; cdecl;
  TFnPushData   = Function (h: TCryptHandle; buf: Pointer; len: LongInt; Var copied: LongInt): LongInt; cdecl;
  TFnPopData    = Function (h: TCryptHandle; buf: Pointer; len: LongInt; Var copied: LongInt): LongInt; cdecl;

Var
  cryptInit             : TFnInit        = Nil;
  cryptEnd              : TFnEnd         = Nil;
  cryptCreateSession    : TFnCreateSess  = Nil;
  cryptDestroySession   : TFnDestroySess = Nil;
  cryptSetAttribute     : TFnSetAttr     = Nil;
  cryptSetAttributeString: TFnSetAttrStr = Nil;
  cryptGetAttribute     : TFnGetAttr     = Nil;
  cryptPushData         : TFnPushData    = Nil;
  cryptPopData          : TFnPopData     = Nil;

Function LoadCryptlib (Const LibName: String = ''): Boolean;
Procedure UnloadCryptlib;
Function CryptlibLoaded: Boolean;

Implementation

Var
  {$IFDEF UNIX} LibHandle : Pointer = Nil;
  {$ELSE} {$IFDEF OS2} LibHandle : THandle = 0;
  {$ELSE} LibHandle : HModule = 0; {$ENDIF} {$ENDIF}
  Loaded : Boolean = False;

Function LibOpen: Boolean;
Begin
  {$IFDEF UNIX} LibOpen := LibHandle <> Nil; {$ELSE} LibOpen := LibHandle <> 0; {$ENDIF}
End;

Function Sym (Const Name: String): Pointer;
Begin
  {$IFDEF UNIX} Sym := dlsym(LibHandle, PChar(Name));
  {$ELSE}
    {$IFDEF OS2}
      If DosQueryProcAddr(LibHandle, 0, PChar(Name), Sym) <> 0 Then Sym := Nil;
    {$ELSE}
      Sym := GetProcAddress(LibHandle, PChar(Name));
    {$ENDIF}
  {$ENDIF}
End;

Function TryOpen (Const N: String): Boolean;
{$IFDEF OS2}
Var
  FailName : Array[0..259] of Char;
{$ENDIF}
Begin
  {$IFDEF UNIX}
    LibHandle := dlopen(PChar(N), RTLD_NOW);
  {$ELSE}
    {$IFDEF OS2}
      If DosLoadModule(FailName, SizeOf(FailName), PChar(N), LibHandle) <> 0 Then
        LibHandle := 0;
    {$ELSE}
      LibHandle := LoadLibrary(PChar(N));
    {$ENDIF}
  {$ENDIF}
  TryOpen := LibOpen;
End;

Function LoadCryptlib (Const LibName: String): Boolean;

  Function DefaultNames: Boolean;
  Begin
    Result := True;
    {$IFDEF UNIX}
      {$IFDEF DARWIN}
        If TryOpen('libcl.dylib')  Then Exit;
      {$ELSE}
        If TryOpen('libcl.so')     Then Exit;
        If TryOpen('libcl.so.3')   Then Exit;
      {$ENDIF}
    {$ELSE}
      // Windows: stock Mystic uses cl32.dll (matches the Mystic install).
      If TryOpen('cl32.dll')       Then Exit;
      If TryOpen('libcl32.dll')    Then Exit;
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

  cryptInit              := TFnInit        (Sym('cryptInit'));
  cryptEnd               := TFnEnd         (Sym('cryptEnd'));
  cryptCreateSession     := TFnCreateSess  (Sym('cryptCreateSession'));
  cryptDestroySession    := TFnDestroySess (Sym('cryptDestroySession'));
  cryptSetAttribute      := TFnSetAttr     (Sym('cryptSetAttribute'));
  cryptSetAttributeString:= TFnSetAttrStr  (Sym('cryptSetAttributeString'));
  cryptGetAttribute      := TFnGetAttr     (Sym('cryptGetAttribute'));
  cryptPushData          := TFnPushData    (Sym('cryptPushData'));
  cryptPopData           := TFnPopData     (Sym('cryptPopData'));

  If (cryptInit = Nil) or (cryptCreateSession = Nil) or (cryptSetAttribute = Nil) or
     (cryptPushData = Nil) or (cryptPopData = Nil) or (cryptDestroySession = Nil) Then Begin
    UnloadCryptlib;
    Exit;
  End;

  Loaded := True;
  Result := True;
End;

Procedure UnloadCryptlib;
Begin
  If LibOpen Then Begin
    {$IFDEF UNIX} dlclose(LibHandle); LibHandle := Nil;
    {$ELSE}
      {$IFDEF OS2} DosFreeModule(LibHandle); {$ELSE} FreeLibrary(LibHandle); {$ENDIF}
      LibHandle := 0;
    {$ENDIF}
  End;
  cryptInit := Nil; cryptEnd := Nil;
  cryptCreateSession := Nil; cryptDestroySession := Nil;
  cryptSetAttribute := Nil; cryptSetAttributeString := Nil;
  cryptGetAttribute := Nil; cryptPushData := Nil; cryptPopData := Nil;
  Loaded := False;
End;

Function CryptlibLoaded: Boolean;
Begin CryptlibLoaded := Loaded; End;

End.
