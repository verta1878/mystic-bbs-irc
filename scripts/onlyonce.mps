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

// ONLYONCE.MPS: Display a file only if it has been updated since the users
//               last login.  Written by g00r00
// Usage:
//    Menu command: GX
//            Data: onlyonce myfile
//
// The above example will display myfile.XXX from current text directory
// only if it has been updated since the users last login

Uses
  CFG,
  USER;

Var
  FN : String;
Begin
  GetThisUser;

  FN := JustFileName(ParamStr(1));

  If Pos(PathChar, ParamStr(1)) = 0 Then
    FN := CfgTextPath + FN;

  FindFirst (FN + '.*', 0);

  While DosError = 0 Do Begin
    If DirTime > UserLastOn Then Begin
      DispFile(FN);

      Break;
    End;

    FindNext
  End;

  FindClose;
End.
