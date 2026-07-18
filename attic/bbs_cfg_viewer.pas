Unit bbs_cfg_viewer;

// ====================================================================
// This file is part of mystic-bbs-irc and is released under the
// GNU General Public License v3. See COPYING for details.
// ====================================================================
//
// FilePickerDialog - shared file browser dialog for mystic -cfg
// Used by TEditorANSI (file mode Open, ANSI editor Open)

{$I M_OPS.PAS}

Interface

Uses
  m_Types,
  m_Strings,
  m_FileIO,
  BBS_Records,
  BBS_Core,
  BBS_IO,
  BBS_Common,
  BBS_Ansi_MenuBox,
  BBS_Ansi_MenuForm,
  DOS;

Function FilePickerDialog (APath, AMask: String) : String;

Implementation

Uses
  BBS_DataBase;

Function FilePickerDialog (APath, AMask: String) : String;
Var
  Box     : TAnsiMenuBox;
  Img     : TConsoleImageRec;
  DirInfo : SearchRec;
  FName   : Array[1..50] of String[80];
  FSize   : Array[1..50] of LongInt;
  FIsDir  : Array[1..50] of Boolean;
  Count   : Integer;
  Pick    : Integer;
  Top     : Integer;
  MaxShow : Integer;
  Row     : Integer;
  Ch      : Char;
  CurPath : String;
  Done    : Boolean;

  Procedure ScanDir;
  Begin
    Count := 0;
    Inc(Count); FName[Count] := '..'; FSize[Count] := 0; FIsDir[Count] := True;
    FindFirst(CurPath + '*.*', $10, DirInfo);
    While (DosError = 0) and (Count < 40) Do Begin
      If (DirInfo.Attr And $10 <> 0) and (DirInfo.Name <> '.') and (DirInfo.Name <> '..') Then Begin
        Inc(Count);
        FName[Count] := DirInfo.Name + PathChar;
        FSize[Count] := 0;
        FIsDir[Count] := True;
      End;
      FindNext(DirInfo);
    End;
    FindClose(DirInfo);
    FindFirst(CurPath + AMask, $27, DirInfo);
    While (DosError = 0) and (Count < 50) Do Begin
      If DirInfo.Attr And $10 = 0 Then Begin
        Inc(Count);
        FName[Count] := DirInfo.Name;
        FSize[Count] := DirInfo.Size;
        FIsDir[Count] := False;
      End;
      FindNext(DirInfo);
    End;
    FindClose(DirInfo);
  End;

  Procedure DrawList;
  Var K, Attr: Integer;
      SizeStr: String;
  Begin
    WriteXY(10, 5, 11, strPadR(' ' + CurPath + AMask, 42, ' '));
    For K := 1 to MaxShow Do Begin
      If Top + K <= Count Then Begin
        If Top + K = Pick Then Attr := 112
        Else If FIsDir[Top + K] Then Attr := 11
        Else Attr := 7;
        If FIsDir[Top + K] Then
          SizeStr := '   <DIR>'
        Else
          SizeStr := strPadL(strI2S(FSize[Top + K]), 8, ' ');
        WriteXY(10, 5 + K, Attr, strPadR(' ' + FName[Top + K], 33, ' ') + SizeStr + ' ');
      End Else
        WriteXY(10, 5 + K, 7, strRep(' ', 42));
    End;
  End;

Begin
  Result  := '';
  CurPath := APath;
  MaxShow := 15;
  Done    := False;

  Console.GetScreenImage(8, 4, 54, 5 + MaxShow + 1, Img);
  Box := TAnsiMenuBox.Create;
  Box.Open(8, 4, 54, 5 + MaxShow + 1);

  ScanDir;
  Pick := 1;
  Top  := 0;
  DrawList;

  Repeat
    Ch := Session.io.GetKey;
    Case Ch of
      #27 : Begin Done := True; End;
      #00 : Case Session.io.GetKey of
              #72 : If Pick > 1 Then Begin Dec(Pick); If Pick <= Top Then Dec(Top); DrawList; End;
              #80 : If Pick < Count Then Begin Inc(Pick); If Pick > Top + MaxShow Then Inc(Top); DrawList; End;
              #73 : Begin Pick := Pick - MaxShow; If Pick < 1 Then Pick := 1; Top := Pick - 1; If Top < 0 Then Top := 0; DrawList; End;
              #81 : Begin Pick := Pick + MaxShow; If Pick > Count Then Pick := Count; Top := Pick - MaxShow; If Top < 0 Then Top := 0; DrawList; End;
            End;
      #13 : Begin
              If (Pick >= 1) and (Pick <= Count) Then Begin
                If FIsDir[Pick] Then Begin
                  If FName[Pick] = '..' Then Begin
                    If Length(CurPath) > 1 Then Begin
                      Delete(CurPath, Length(CurPath), 1);
                      While (Length(CurPath) > 0) and
                            (CurPath[Length(CurPath)] <> PathChar) Do
                        Delete(CurPath, Length(CurPath), 1);
                    End;
                  End Else
                    CurPath := CurPath + Copy(FName[Pick], 1, Length(FName[Pick]) - 1) + PathChar;
                  ScanDir; Pick := 1; Top := 0; DrawList;
                End Else Begin
                  Result := CurPath + FName[Pick];
                  Done := True;
                End;
              End;
            End;
    End;
  Until Done;

  Box.Close;
  Box.Free;
  Session.io.RemoteRestore(Img);
End;

End.
