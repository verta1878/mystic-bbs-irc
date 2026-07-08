// ====================================================================
// mystic_spell : optional spell-check add-on for Mystic BBS A38
// ====================================================================
//
// This file is part of an optional add-on module for Mystic BBS and is
// released under the same GNU General Public License v3 as Mystic BBS.
// Mystic BBS is Copyright 1997-2013 By James Coyle.
//
// spelltest - a standalone tester for the spell engine.  Opens a dictionary
// (paths from the command line or sensible defaults), then checks a few words
// and prints suggestions for the misspelled ones.  Proves the Hunspell binding
// and engine end to end.
//
//   spelltest [afffile] [dicfile] [wordlist]
// ====================================================================

Program spelltest;

{$IFDEF FPC}{$MODE OBJFPC}{$H+}{$ENDIF}

Uses
  SysUtils, Classes,
  spl_Hunspell, spl_Engine;

Var
  Eng  : TSpellEngine;
  Aff, Dic, WL : String;

Procedure Test (Const W: String);
Var
  Ok  : Boolean;
  Sug : TStringList;
Begin
  Ok := Eng.Check(W);
  If Ok Then
    WriteLn('  "', W, '" -> OK')
  Else Begin
    Write('  "', W, '" -> misspelled; suggestions: ');
    Sug := Eng.Suggest(W, 6);
    Try
      If Sug.Count = 0 Then Write('(none)')
      Else Write(Sug.CommaText);
    Finally
      Sug.Free;
    End;
    WriteLn;
  End;
End;

Begin
  WriteLn('Mystic spell-check engine test (mystic_spell)');
  WriteLn('---------------------------------------------');

  Aff := '/usr/share/hunspell/en_US.aff';
  Dic := '/usr/share/hunspell/en_US.dic';
  WL  := '';
  If ParamCount >= 1 Then Aff := ParamStr(1);
  If ParamCount >= 2 Then Dic := ParamStr(2);
  If ParamCount >= 3 Then WL  := ParamStr(3);

  Eng := TSpellEngine.Create;
  Try
    If Not Eng.Open(Aff, Dic) Then Begin
      WriteLn('Spell engine not ready (Hunspell library or dictionary missing).');
      WriteLn('  Hunspell loaded : ', HunspellLoaded);
      WriteLn('  aff : ', Aff, '  exists=', FileExists(Aff));
      WriteLn('  dic : ', Dic, '  exists=', FileExists(Dic));
      WriteLn('This is expected on a 32-bit build with no 32-bit Hunspell; the');
      WriteLn('engine degrades gracefully (everything reports OK).');
      Halt(0);
    End;

    WriteLn('Engine ready.  Dictionary: ', Dic);
    If WL <> '' Then Begin
      Eng.LoadWordList(WL);
      WriteLn('Loaded word list: ', WL);
    End;
    WriteLn;

    Test('hello');
    Test('mesage');       // -> message
    Test('recieve');      // -> receive
    Test('definately');   // -> definitely
    Test('sysop');
    Test('teh');          // -> the
    Test('BBS');
  Finally
    Eng.Free;
  End;
End.
