// ====================================================================
// Mystic BBS Software               Copyright 1997-2013 By James Coyle
// ====================================================================
//
// This file is part of Mystic BBS.
//
// Mystic BBS is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Mystic BBS is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Mystic BBS.  If not, see <http://www.gnu.org/licenses/>.
//
// ====================================================================

// ---------------------------------------------------------------------------
// BULLETIN.MPS: Bulletin Menu Script for Mystic BBS v1.07+
// ---------------------------------------------------------------------------
// This MPE program creates a simple bulletin menu.  The following parameters
// must be passed when running this script:
//
// BULLETIN [menu name] [base bulletin name] [check]
//
// The first option [menu name] passes the name of the bulletin menu to
// display.  For example, if the text "BULLETIN" is passed, the script will
// display the display file "BULLETIN.XXX" as the menu.
//
// The second option [base bulletin name] is the base bulletin name for each
// actual bulletin.  This can be no longer than 6 characters in length.  For
// example, if "BULLET" was passed as the base bulletin name, when the user
// types in "1" and hits enter, the script will display BULLET1.XXX
//
// The next command line is optional.  If you supply the option "CHECK", the
// script will check for updated bulletins since the user's last call, then
// prompt them to read the bulletins if there are new bulletins available.
// This is handy to put as an FIRSTCMD command during the login somewhere,
// as the default Mystic BBS installation does.
//
// Feel free to make any modifications to this code that you want!
//
// ---------------------------------------------------------------------------

Uses CFG
Uses USER

Var
  CheckNew : Boolean
  MenuName : String
  Prefix   : String
  Done     : Boolean
  InStr    : String
  NewNum   : Byte
  NewStr   : String

Procedure Scan_New_Bulletins
Begin
  NewStr := '';
  NewNum := 0;

  FindFirst (PreFix + '*.*', 63);

  While DosError = 0 Do Begin
    If DirTime > UserLastOn And Upper(Copy(DirName, 1, Pos('.', DirName) - 1)) <> 'BULLETIN' Then Begin
      InStr := Copy(DirName, 7, Pos('.', DirName) - 7) + ' '

      If Pos(InStr, NewStr) = 0 Then Begin
        NewStr := NewStr + InStr;
        NewNum := NewNum + 1;
      End
    End

    FindNext;
  End;

  FindClose;
End;

Begin
  If ParamCount < 2 Then Begin
    WriteLn ('|CRERROR (BULLETIN.MPS): Invalid command line');
    Halt;
  End;

  GetThisUser;

  MenuName := CfgTextPath + ParamStr(1);
  Prefix   := CfgTextPath + ParamStr(2);
  CheckNew := False;
  Done     := False;

  If ParamCount > 2 Then
    If Upper(ParamStr(3)) = 'CHECK' Then
      CheckNew := True

  Scan_New_Bulletins

  If NewNum = 0 Then
    NewStr := 'None'

  If CheckNew Then Begin
    If NewNum = 0 Then Begin
      WriteLn ('|CL|01[|10þ|01] |09There are no new bulletins.')
      Halt
    End Else
      If Not InputYN('|CL|01[|10þ|01] |09New bulletins: |15' + Int2Str(NewNum) + '|09  Read them now? ') Then
        Halt
  End;

  DispFile (MenuName)

  Repeat
    WriteLn ('|CR|09New Bulletins    |08-> |07' + NewStr)
    Write   ('|09Command (?/List) |08-> |07')

    InStr := Input(4, 4, 12, '')

    If InStr = '?' Then
      DispFile (MenuName)
    Else
    If InStr = 'Q' Then
      Done := True
    Else
    If InStr = '' Then
      DispFile (MenuName)
    Else
      If Not DispFile (PreFix + InStr) Then
        WriteLn ('|CRERROR: Bulletin not found.')
  Until Done
End
