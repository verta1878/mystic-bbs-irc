// ====================================================================
// mystic_spell : optional spell-check add-on for Mystic BBS A38
// ====================================================================
//
// This file is part of an optional add-on module for Mystic BBS and is
// released under the same GNU General Public License v3 as Mystic BBS.
// Mystic BBS is Copyright 1997-2013 By James Coyle.
//
// spl_engine - TSpellEngine: a small, safe wrapper over the Hunspell binding.
// Opens a primary dictionary (.aff + .dic), optionally loads a WORDLIST.TXT of
// extra BBS terms/acronyms, and answers Check(word) / Suggest(word).  If
// Hunspell or the dictionaries are missing, the engine reports Ready=False and
// treats everything as spelled correctly (so a caller degrades gracefully),
// mirroring Mystic 1.12: no dictionaries => spell checking simply off.
// ====================================================================

Unit spl_Engine;

{$IFDEF FPC}{$MODE OBJFPC}{$H+}{$ENDIF}

Interface

Uses
  SysUtils, Classes,
  spl_Hunspell;

Type
  TSpellEngine = Class
  Private
    FHandle : THunHandle;
    FReady  : Boolean;
  Public
    Constructor Create;
    Destructor  Destroy; Override;

    // Load Hunspell (LibName '' = platform default) and the .aff/.dic pair.
    // AffFile/DicFile are full paths.  Returns True on success.
    Function  Open (Const AffFile, DicFile: String;
                    Const LibName: String = ''): Boolean;

    // Add every word from a WORDLIST.TXT (one per line; ';' comment lines and
    // blanks skipped) into the runtime dictionary.  Safe if the file is absent.
    Procedure LoadWordList (Const FileName: String);

    // True if the word is spelled correctly (or if the engine is not ready).
    Function  Check (Const Word: String): Boolean;

    // Return up to Max suggestions for a (probably misspelled) word.
    Function  Suggest (Const Word: String; Max: LongInt = 8): TStringList;

    Property Ready : Boolean Read FReady;
  End;

Implementation

Constructor TSpellEngine.Create;
Begin
  Inherited Create;
  FHandle := Nil;
  FReady  := False;
End;

Destructor TSpellEngine.Destroy;
Begin
  If (FHandle <> Nil) and Assigned(Hunspell_destroy) Then
    Hunspell_destroy(FHandle);
  FHandle := Nil;
  Inherited Destroy;
End;

Function TSpellEngine.Open (Const AffFile, DicFile, LibName: String): Boolean;
Begin
  Result := False;
  FReady := False;

  If Not LoadHunspell(LibName) Then Exit;          // no library => off
  If Not FileExists(AffFile) Then Exit;
  If Not FileExists(DicFile) Then Exit;

  FHandle := Hunspell_create(PChar(AffFile), PChar(DicFile));
  If FHandle = Nil Then Exit;

  FReady := True;
  Result := True;
End;

Procedure TSpellEngine.LoadWordList (Const FileName: String);
Var
  L : TStringList;
  I : LongInt;
  S : String;
Begin
  If (Not FReady) or (Not Assigned(Hunspell_add)) Then Exit;
  If Not FileExists(FileName) Then Exit;

  L := TStringList.Create;
  Try
    L.LoadFromFile(FileName);
    For I := 0 to L.Count - 1 Do Begin
      S := Trim(L[I]);
      If (S = '') or (S[1] = ';') Then Continue;
      Hunspell_add(FHandle, PChar(S));
    End;
  Finally
    L.Free;
  End;
End;

Function TSpellEngine.Check (Const Word: String): Boolean;
Begin
  If (Not FReady) or (Word = '') Then Begin Check := True; Exit; End;
  // Hunspell_spell returns non-zero if the word is correct.
  Check := Hunspell_spell(FHandle, PChar(Word)) <> 0;
End;

Function TSpellEngine.Suggest (Const Word: String; Max: LongInt): TStringList;
Var
  Slst : PPChar;
  N, I : LongInt;
  P    : PPChar;
Begin
  Result := TStringList.Create;
  If (Not FReady) or (Word = '') Then Exit;

  Slst := Nil;
  N := Hunspell_suggest(FHandle, Slst, PChar(Word));
  If (N > 0) and (Slst <> Nil) Then Begin
    P := Slst;
    For I := 0 to N - 1 Do Begin
      If Result.Count >= Max Then Break;
      If P^ <> Nil Then Result.Add(StrPas(P^));
      Inc(P);
    End;
    If Assigned(Hunspell_free_list) Then
      Hunspell_free_list(FHandle, Slst, N);
  End;
End;

End.
