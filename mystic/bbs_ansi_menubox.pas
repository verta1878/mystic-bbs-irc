Unit BBS_Ansi_MenuBox;

{$I M_OPS.PAS}

Interface

Uses
  m_Types,
  BBS_Records;

Procedure WriteXY          (X, Y, A: Byte; S: String);
Procedure WriteXYPipe      (X, Y, A: Byte; SZ: SmallInt; S: String);
Function  InXY             (X, Y, Field, Max, Mode: Byte; Default: String) : String;
Function  InBox            (Header, Text, Def: String; Len, MaxLen: Byte) : String;
Procedure VerticalLine     (X, Y1, Y2 : Byte);
Procedure ThemeMessageBox  (Theme: RecTheme; BoxType: Byte; Title, Text: String);
Function  ShowMsgBox       (BoxType: Byte; Str: String) : Boolean;
Procedure DefListBoxSearch (Var Owner: Pointer; Str: String);

Const
  BoxFrameType : Array[1..8] of String[8] =
        ('⁄ƒø≥≥¿ƒŸ',
         '…Õª∫∫»Õº',
         '÷ƒ∑∫∫”ƒΩ',
         '’Õ∏≥≥‘Õæ',
         '€ﬂ€€€€‹€',
         '€ﬂ‹€€ﬂ‹€',
         '        ',
         '.-.||`-''');

Type
  TAnsiMenuBox = Class
    Image      : TConsoleImageRec;
    HideImage  : ^TConsoleImageRec;
    FrameType  : Byte;
    BoxAttr    : Byte;
    Box3D      : Boolean;
    BoxAttr2   : Byte;
    BoxAttr3   : Byte;
    BoxAttr4   : Byte;
    Shadow     : Boolean;
    ShadowAttr : Byte;
    HeadAttr   : Byte;
    HeadType   : Byte;
    Header     : String;
    WasOpened  : Boolean;

    Constructor Create;
    Destructor  Destroy; Override;
    Procedure   Open (X1, Y1, X2, Y2: Integer);
    Procedure   Close;
    Procedure   Hide;
    Procedure   Show;
  End;

  TAnsiListBoxStatusProc = Procedure (Num: Word; Str: String);
  TAnsiListBoxSearchProc = Procedure (Var Owner: Pointer; Str: String);
  TAnsiListBoxUpdateProc = Procedure (X, Y, W: Byte; IsHi: Boolean; BarName: String; Tagged: Byte);

  TAnsiListBoxDataPTR = ^TAnsiListBoxDataRec;
  TAnsiListBoxDataRec = Record
    Name    : String;
    Tagged  : Byte;                     { 0 = false, 1 = true, 2 = never }
  End;

  TAnsiListBoxSort = (sortAscending, sortDecending);

  TAnsiListBoxSortDepth = Record
    Column : Byte;
    Mode   : TAnsiListBoxSort;
  End;

  TAnsiListBox = Class
    List        : Array[1..10000] of ^TAnsiListBoxDataRec;
    Box         : TAnsiMenuBox;
    HiAttr      : Byte;
    LoAttr      : Byte;
    Format      : Byte;
    LoChars     : String;
    HiChars     : String;
    ExitCode    : Char;
    Picked      : Integer;
    TopPage     : Integer;
    NoWindow    : Boolean;
    ListMax     : LongInt;
    AllowTag    : Boolean;
    TagChar     : Char;
    TagKey      : Char;
    TagPos      : Byte;
    TagAttr     : Byte;
    Marked      : Word;
    StatusProc  : TAnsiListBoxStatusProc;
    Width       : Integer;
    WinSize     : Integer;
    X1          : Byte;
    Y1          : Byte;
    NoInput     : Boolean;
    SearchProc  : TAnsiListBoxSearchProc;
    UpdateProc  : TAnsiListBoxUpdateProc;
    SearchX     : Byte;
    SearchY     : Byte;
    SearchA     : Byte;
    SearchStr   : String;
    SortDepth   : Array[1..4] of TAnsiListBoxSortDepth;
    PercentBar  : RecPercent;

    Constructor Create;
    Destructor  Destroy;       Override;
    Procedure   SetStatusProc  (P: TAnsiListBoxStatusProc);
    Procedure   SetSearchProc  (P: TAnsiListBoxSearchProc);
    Procedure   SetUpdateProc  (P: TAnsiListBoxUpdateProc);
    Procedure   Open           (BX1, BY1, BX2, BY2: Byte);
    Procedure   Close;
    Procedure   Add            (Str: String; B: Byte);
    Procedure   Insert         (RecPos: Word; Str: String; B: Byte);
    Procedure   Delete         (RecPos: Word);
    Procedure   Get            (Num: Word; Var Str: String; Var B: Boolean);
    Procedure   Clear;
    Procedure   Sort           (Left, Right: LongInt);
    Procedure   Focus          (RecPos: Word; Refresh: Boolean);
    Procedure   UpdatePercent;
    Procedure   UpdateBar      (X, Y: Byte; RecPos: Word; IsHi: Boolean);
    Procedure   Update;
    Function    HasMore        (Up: Boolean) : LongInt;
    Procedure   CalculateMove  (Up, Refresh: Boolean);
  End;



Implementation

Uses
  m_Strings,
  BBS_Core,
  BBS_DataBase,
  BBS_Ansi_MenuInput;

Procedure WriteXY (X, Y, A: Byte; S: String);
Begin
  Session.io.AnsiGotoXY (X, Y);
  Session.io.AnsiColor  (A);
  Session.io.OutRaw     (S);
End;

Procedure WriteXYPipe (X, Y, A: Byte; SZ: SmallInt; S: String);
Var
  Count : Byte;
  Code  : String[2];
Begin
  Session.io.AnsiGotoXY (X, Y);
  Session.io.AnsiColor  (A);

  Count := 1;

  While Count <= Length(S) Do Begin
    If S[Count] = '|' Then Begin
      Code := Copy(S, Count + 1, 2);

      If (Code[2] in ['0'..'9']) Then Begin
        Case Code[1] of
          '0'..
          '2' : Begin
                  Inc (Count, 2);

                  Session.io.BufAddStr(Session.io.Pipe2Ansi(strS2I(Code)));
                End;
          'T' : Begin
                  Inc (Count, 2);

                  Session.io.BufAddStr(Session.io.Attr2Ansi(Session.Theme.Colors[strS2I(Code[2])]));
                End;
        Else
          Session.io.BufAddChar(S[Count]);
          Dec (SZ);
        End;
      End Else Begin
        Session.io.BufAddChar(S[Count]);
        Dec (SZ);
      End;
    End Else Begin
      Session.io.BufAddChar(S[Count]);
      Dec (SZ);
    End;

    If SZ = 0 Then Break;

    Inc (Count);
  End;

  If SZ > 0 Then Begin
    Session.io.AnsiColor (7);
    Session.io.BufAddStr (strRep(' ', SZ));
  End;

  Session.io.BufFlush;
End;

Function DefListBoxString (InData: String; IsHi: Boolean) : String;
Begin
  Result := '';
End;

Procedure DefListBoxSearch (Var Owner: Pointer; Str: String);
Begin
  If Str = '' Then
    Str := strRep(BoxFrameType[TAnsiListBox(Owner).Box.FrameType][7], 17)
  Else Begin
    If Length(Str) > 15 Then
      Str := Copy(Str, Length(Str) - 15 + 1, 255);

    Str := '[' + strLower(Str) + ']';

    While Length(Str) < 17 Do
      Str := Str + BoxFrameType[TAnsiListBox(Owner).Box.FrameType][7];
  End;

  WriteXY (TAnsiListBox(Owner).SearchX,
           TAnsiListBox(Owner).SearchY,
           TAnsiListBox(Owner).SearchA,
           Str);
End;

Function InBox (Header, Text, Def: String; Len, MaxLen: Byte) : String;
Var
  Box     : TAnsiMenuBox;
  Input   : TAnsiMenuInput;
  Offset  : Byte;
  Str     : String;
  WinSize : Byte;
Begin
  If Len > Length(Text) Then
    Offset := Len
  Else
    Offset := Length(Text);

  WinSize := (80 - Offset + 2) DIV 2;

  Box   := TAnsiMenuBox.Create;
  Input := TAnsiMenuInput.Create;

  Box.Header    := ' ' + Header + ' ';
  Input.LoChars := #13#27;

  Box.Open (WinSize, 10, WinSize + Offset + 3, 15);

  WriteXY (WinSize + 2, 12, 112, Text);

  Str := Input.GetStr(WinSize + 2, 13, Len, MaxLen, 1, Def);

  Box.Close;

  If Input.ExitCode = #27 Then Str := '';

  Input.Free;
  Box.Free;

  Result := Str;
End;

Function InXY (X, Y, Field, Max, Mode: Byte; Default: String) : String;
Begin
  Session.io.AnsiGotoXY (X, Y);

  InXY := Session.io.GetInput (Field, Max, Mode, Default);
End;

Procedure VerticalLine (X, Y1, Y2: Byte);
Var
  Count : Byte;
Begin
  For Count := Y1 to Y2 Do
    WriteXY (X, Count, 112, #179);
End;

// Rework this.  We want to combine with ShowMsgBox?
// Can we expand on this to use Yes/No prompts
// And also the CommandWindow from the CFG would be a create MCI code

Procedure ThemeMessageBox (Theme: RecTheme; BoxType: Byte; Title, Text: String);
Var
  Len    : Byte;
  Len2   : Byte;
  Len3   : Byte;
  MsgBox : TAnsiMenuBox;
  NewStr : String;
Begin
  // 0 = prompt OK, restore
  // 1 = draw box and exit, no restore

  MsgBox := TAnsiMenuBox.Create;
  NewStr := Session.io.StrMCI(strStripPipe(Text));

  If Length(NewStr) > 70 Then NewStr[0] := #70;

  Len  := (80 - (Length(NewStr) + 3)) DIV 2;
  Len2 := (Length(NewStr) - 4) DIV 2;

  MsgBox.Header     := ' ' + Title + ' ';
  MsgBox.FrameType  := Theme.BoxFrame;
  MsgBox.Shadow     := Theme.BoxShadow;
  MsgBox.ShadowAttr := Theme.BoxShadowAttr;
  MsgBox.HeadAttr   := Theme.BoxHeadAttr;
  MsgBox.BoxAttr    := Theme.BoxAttr;
  MsgBox.BoxAttr2   := Theme.BoxAttr2;
  MsgBox.BoxAttr3   := Theme.BoxAttr3;
  MsgBox.BoxAttr4   := Theme.BoxAttr4;

  Case BoxType of
    0 : Len3 := 16;
    1 : Len3 := 14;
  End;

  MsgBox.Open (Len, 10, Len + Length(NewStr) + 3, Len3);
  WriteXYPipe (Len + 2,  12, Theme.BoxTextAttr, Length(NewStr), Session.io.strMCI(Text));

  Case BoxType of
    0 : Begin
          WriteXY (Len + Len2 + 2, 14, Theme.BoxOKAttr, ' OK ');
          Session.io.GetKey;
        End;
  End;

  If BoxType <> 1 Then
    MsgBox.Close;

  MsgBox.Free;
End;

Function ShowMsgBox (BoxType : Byte; Str : String) : Boolean;
Var
  Len    : Byte;
  Len2   : Byte;
  Pos    : Byte;
  MsgBox : TAnsiMenuBox;
  Ch     : Char;
Begin
  Result := True;

{ 0 = ok box }{ 1 = y/n box }{ 2 = just box }{ 3 = just box dont close }

  MsgBox := TAnsiMenuBox.Create;

  Len := (80 - (Length(Str) + 3)) DIV 2;
  Pos := 1;

  MsgBox.Header := ' Info ';

  If BoxType < 2 Then
    MsgBox.Open (Len, 10, Len + Length(Str) + 3, 15)
  Else
    MsgBox.Open (Len, 10, Len + Length(Str) + 3, 14);

  WriteXY (Len + 2,  12, 113, Str);

  Case BoxType of
    0 : Begin
          Len2 := (Length(Str) - 4) DIV 2;
          WriteXY (Len + Len2 + 2, 14, 30, ' OK ');
          Ch := Session.io.GetKey;
        End;
    1 : Repeat
          Len2 := (Length(Str) - 9) DIV 2;

          WriteXY (Len + Len2 + 2, 14, 113, ' YES ');
          WriteXY (Len + Len2 + 7, 14, 113, ' NO ');

          If Pos = 1 Then
            WriteXY (Len + Len2 + 2, 14, 30, ' YES ')
          Else
            WriteXY (Len + Len2 + 7, 14, 30, ' NO ');

          Ch := UpCase(Session.io.GetKey);

          If Session.io.IsArrow Then
            Case Ch of
              #75 : Pos := 1;
              #77 : Pos := 0;
            End
          Else
            Case Ch of
              #13 : Begin
                      Result := Boolean(Pos);
                      Break;
                    End;
              #32 : If Pos = 0 Then Inc(Pos) Else Pos := 0;
              'N' : Pos := 0;
              'Y' : Pos := 1;
            End;
        Until False;
  End;

  If BoxType < 2 Then MsgBox.Close;

  MsgBox.Free;
End;

Constructor TAnsiMenuBox.Create;
Begin
  Inherited Create;

  Shadow     := True;
  ShadowAttr := 0;
  Header     := '';
  FrameType  := 6;
  Box3D      := True;
  BoxAttr    := 15 + 7 * 16;
  BoxAttr2   := 8  + 7 * 16;
  BoxAttr3   := 15 + 7 * 16;
  BoxAttr4   := 8  + 7 * 16;
  HeadAttr   := 15  + 1 * 16;
  HeadType   := 0;
  HideImage  := NIL;
  WasOpened  := False;

  FillChar(Image, SizeOf(TConsoleImageRec), 0);

  Session.io.BufFlush;
End;

Destructor TAnsiMenuBox.Destroy;
Begin
  Inherited Destroy;
End;

Procedure TAnsiMenuBox.Open (X1, Y1, X2, Y2: Integer);
Var
  A  : Integer;
  B  : Integer;
  Ch : Char;
Begin
  If Not WasOpened Then
    If Shadow Then
      Console.GetScreenImage(X1, Y1, X2 + 2, Y2 + 1, Image)
    Else
      Console.GetScreenImage(X1, Y1, X2, Y2, Image);

  WasOpened := True;

  B := X2 - X1 - 1;

  If Not Box3D Then Begin
    BoxAttr2 := BoxAttr;
    BoxAttr3 := BoxAttr;
    BoxAttr4 := BoxAttr;
  End;

  WriteXY (X1, Y1, BoxAttr,  BoxFrameType[FrameType][1] + strRep(BoxFrameType[FrameType][2], B));
  WriteXY (X2, Y1, BoxAttr4, BoxFrameType[FrameType][3]);

  For A := Y1 + 1 To Y2 - 1 Do Begin
    WriteXY (X1, A, BoxAttr, BoxFrameType[FrameType][4] + strRep(' ', B));
    WriteXY (X2, A, BoxAttr2, BoxFrameType[FrameType][5]);
  End;

  WriteXY (X1,   Y2, BoxAttr3, BoxFrameType[FrameType][6]);
  WriteXY (X1+1, Y2, BoxAttr2, strRep(BoxFrameType[FrameType][7], B) + BoxFrameType[FrameType][8]);

  If Header <> '' Then
    Case HeadType of
      0 : WriteXY (X1 + 1 + (B - Length(Header)) DIV 2, Y1, HeadAttr, Header);
      1 : WriteXY (X1 + 1, Y1, HeadAttr, Header);
      2 : WriteXY (X2 - Length(Header), Y1, HeadAttr, Header);
    End;

  If Shadow Then Begin
    For A := Y1 + 1 to Y2 + 1 Do
      For B := X2 + 1 to X2 + 2 Do Begin
        Ch := Console.ReadCharXY(B, A);
        WriteXY (B, A, ShadowAttr, Ch);
      End;

    A := Y2 + 1;

    For B := (X1 + 2) To (X2 + 2) Do Begin
      Ch := Console.ReadCharXY(B, A);
      WriteXY (B, A, ShadowAttr, Ch);
    End;
  End;
End;

Procedure TAnsiMenuBox.Close;
Begin
  If WasOpened Then Session.io.RemoteRestore(Image);
End;

Procedure TAnsiMenuBox.Hide;
Begin
  If Assigned(HideImage) Then FreeMem(HideImage, SizeOf(TConsoleImageRec));

  GetMem (HideImage, SizeOf(TConsoleImageRec));

  Console.GetScreenImage (Image.X1, Image.Y1, Image.X2, Image.Y2, HideImage^);

  Session.io.RemoteRestore(Image);
End;

Procedure TAnsiMenuBox.Show;
Begin
  If Assigned (HideImage) Then Begin
    Session.io.RemoteRestore(HideImage^);
    FreeMem (HideImage, SizeOf(TConsoleImageRec));
    HideImage := NIL;
  End;
End;

Constructor TAnsiListBox.Create;
Begin
  Inherited Create;

  Box        := TAnsiMenuBox.Create;
  ListMax    := 0;
  HiAttr     := 15 + 1 * 16;
  LoAttr     := 1  + 7 * 16;

  Format     := 0;
  LoChars    := #13#27;
  HiChars    := '';
  NoWindow   := False;
  AllowTag   := False;
  TagChar    := '*';
  TagKey     := #09;
  TagPos     := 0;
  TagAttr    := 15 + 7 * 16;
  Marked     := 0;
  Picked     := 1;
  NoInput    := False;
  StatusProc := NIL;
  SearchProc := @DefListBoxSearch;
  UpdateProc := NIL;
  SearchX    := 0;
  SearchY    := 0;
  SearchA    := 0;
  TopPage    := 1;

  FillChar (SortDepth, SizeOf(SortDepth), 0);
  FillChar (PercentBar, SizeOf(PercentBar), 0);

  PercentBar.Active := True;
  PercentBar.Format := 1;
  PercentBar.LoChar := #176;
  PercentBar.HiChar := #178;

  SortDepth[1].Column := 1;
  SortDepth[1].Mode   := sortAscending;

  Session.io.BufFlush;
End;

Procedure TAnsiListBox.Clear;
Var
  Count : Word;
Begin
  For Count := 1 to ListMax Do
    Dispose(List[Count]);

  ListMax  := 0;
  Marked   := 0;
End;

Procedure TAnsiListBox.Insert (RecPos: Word; Str: String; B: Byte);
Var
  Count : LongInt;
Begin
  Inc (ListMax);

  For Count := ListMax DownTo RecPos Do
    List[Count] := List[Count - 1];

  New (List[RecPos]);

  List[RecPos]^.Name   := Str;
  List[RecPos]^.Tagged := B;
End;

Procedure TAnsiListBox.Delete (RecPos : Word);
Var
  Count : Word;
Begin
  If List[RecPos] <> NIL Then Begin
    Dispose (List[RecPos]);

    For Count := RecPos To ListMax - 1 Do
      List[Count] := List[Count + 1];

    Dec (ListMax);
  End;
End;

Destructor TAnsiListBox.Destroy;
Begin
  Box.Free;

  Clear;

  Inherited Destroy;
End;

Procedure TAnsiListBox.UpdateBar (X, Y: Byte; RecPos: Word; IsHi: Boolean);
Var
  Str  : String;
  Attr : Byte;
Begin
  If Assigned(UpdateProc) Then Begin
    If RecPos <= ListMax Then
      UpdateProc (X, Y, Width, IsHi, List[RecPos]^.Name, List[RecPos]^.Tagged)
    Else
      UpdateProc (X, Y, Width, IsHi, '', 0);
  End Else Begin
    If IsHi Then
      Attr := HiAttr
    Else
      Attr := LoAttr;

    If RecPos <= ListMax Then Begin
      Str := ' ' + List[RecPos]^.Name + ' ';

      Case Format of
        0 : Str := strPadR(Str, Width, ' ');
        1 : Str := strPadL(Str, Width, ' ');
        2 : Str := strPadC(Str, Width, ' ');
      End;
    End Else
      Str := strRep(' ', Width);

    WriteXY (X, Y, Attr, Str);

    If AllowTag Then
      If (RecPos <= ListMax) and (List[RecPos]^.Tagged = 1) Then
        WriteXY (TagPos, Y, TagAttr, TagChar)
      Else
        WriteXY (TagPos, Y, TagAttr, ' ');
  End;
End;

Procedure TAnsiListBox.UpdatePercent;
Var
  NewPos : Integer;
Begin
  If (Not PercentBar.Active) or (ListMax <= 0) or (PercentBar.BarLength <= 0) Then Exit;

  Case PercentBar.Format of
    0 : Begin
          Session.io.AnsiGotoXY(PercentBar.StartX, PercentBar.StartY);
          Session.io.OutRaw(Session.io.DrawPercent(PercentBar, Picked, ListMax, NewPos));
        End;
    1 : Begin
          NewPos := (Picked * PercentBar.BarLength) DIV ListMax;

          If Picked >= ListMax Then
            NewPos := Pred(PercentBar.BarLength);

          If (NewPos < 0) or (Picked = 1) or (HasMore(True) = -1) Then
            NewPos := 0;

          NewPos := PercentBar.StartY + NewPos;

          If PercentBar.LastPos <> NewPos Then Begin
            If PercentBar.LastPos > 0 Then
              WriteXY (PercentBar.StartX, PercentBar.LastPos, PercentBar.LoAttr, PercentBar.LoChar);

            PercentBar.LastPos := NewPos;

            WriteXY (PercentBar.StartX, NewPos, PercentBar.HiAttr, PercentBar.HiChar);

            Session.io.AnsiColor(7);
          End;
        End;
  End;
End;

Procedure TAnsiListBox.Update;
Var
  Loop   : LongInt;
  CurRec : Integer;
Begin
  For Loop := 0 to WinSize - 1 Do Begin
    CurRec := TopPage + Loop;

    UpdateBar (X1 + 1, Y1 + 1 + Loop, CurRec, CurRec = Picked);
  End;

  UpdatePercent;

  Session.io.BufFlush;
End;

Function TAnsiListBox.HasMore (Up: Boolean) : LongInt;
Var
  Count : LongInt;
Begin
  Count  := Picked;
  Result := -1;

  While (Up and (Count > 1)) or (Not Up and (Count < ListMax)) Do Begin
    If Up Then Dec(Count) Else Inc(Count);
    If List[Count]^.Name[1] <> #2 Then Begin
      Result := Count;
      Exit;
    End;
  End;
End;

Procedure TAnsiListBox.CalculateMove (Up, Refresh: Boolean);
Var
  StartPick : LongInt;
  StartTop  : LongInt;
Begin
  If Up Then Begin
    If (TopPage = 1) And (HasMore(Up) = -1) Then Exit;
  End Else
    If (TopPage + WinSize - 1 >= ListMax) And (HasMore(Up) = -1) Then Exit;

  StartPick := Picked;
  StartTop  := TopPage;

  Repeat
    If Up Then Begin
      If Picked <= TopPage Then Begin
        Dec (Picked);
        Dec (TopPage);
      End Else
        Dec (Picked);
    End Else Begin
      If Picked >= TopPage + WinSize - 1 Then Begin
        Inc (TopPage);
        Inc (Picked);
      End Else
        Inc (Picked);
    End;
  Until (List[Picked]^.Name[1] <> #2) or (Picked >= ListMax) or (Picked = 1);

  If Refresh Then
    If StartTop = TopPage Then Begin
      UpdateBar (X1 + 1, Y1 + StartPick - TopPage + 1, StartPick, False);
      UpdateBar (X1 + 1, Y1 + Picked - TopPage + 1, Picked, True);

      UpdatePercent;
    End Else
      Update;
End;

Procedure TAnsiListBox.Focus (RecPos: Word; Refresh: Boolean);
Var
  Up   : Boolean;
  Next : LongInt;
Begin
//  writexy (1,1,7,strrep(' ', 79));

//  While Picked > TopPage + WinSize - 1 Do
//    Inc (TopPage);

//  writexy (1,1,7,'recpos=' + stri2s(recpos) + 'toppage: ' + stri2s(toppage) + ' picked: ' + stri2s(picked));

//  session.io.bufflush;
//session.io.pausescreen;

  If (Picked <= TopPage + WinSize - 1) and (Picked >= TopPage) Then
    Up := Picked > RecPos
  Else Begin
    TopPage := 1;
    Picked  := 1;
    Up      := False;
  End;

  If Picked = RecPos Then Exit;

  Repeat
    Next := HasMore(Up);

    CalculateMove(Up, (Next = RecPos) and Refresh);
  Until (Next = -1) or (RecPos = Picked);
End;

Procedure TAnsiListBox.Open (BX1, BY1, BX2, BY2 : Byte);
Var
  Ch          : Char;
  Count       : Word;
  StartPos    : Word;
  EndPos      : Word;
  First       : Boolean;
  SavedRec    : Word;
  SavedTop    : Word;
  LastWasChar : Boolean;
Begin
  If Not NoWindow Then
    Box.Open (BX1, BY1, BX2, BY2);

  If SearchX = 0 Then SearchX := BX1 + 2;
  If SearchY = 0 Then SearchY := BY2;
  If SearchA = 0 Then SearchA := Box.BoxAttr4;

  X1 := BX1;
  Y1 := BY1;

//  If (Picked < 1) or (Picked > ListMax) Then Begin
//    Picked  := 1;
//    TopPage := 1;
//  End;

//  If (Picked < TopPage) or (Picked < 1) or (Picked > ListMax) or (TopPage < 1) or (TopPage > ListMax) Then Begin
//    Picked  := 1;
//    TopPage := 1;
//  End;

  Width   := BX2 - X1 - 1;
  WinSize := BY2 - Y1 - 1;
  TagPos  := X1 + 1;

  Focus(Picked, False);

  // Setup BAR stuff if needed

  If PercentBar.LoAttr    = 0 Then PercentBar.LoAttr := Box.BoxAttr2;
  If PercentBar.HiAttr    = 0 Then PercentBar.HiAttr := Box.BoxAttr2;
  If PercentBar.BarLength = 0 Then PercentBar.BarLength := WinSize;
  If PercentBar.StartX    = 0 Then PercentBar.StartX := X1 + Width + 1;
  If PercentBar.StartY    = 0 Then PercentBar.StartY := Y1 + 1;

  If PercentBar.Active And (PercentBar.Format = 1) Then Begin
    For Count := 1 to PercentBar.BarLength Do
      WriteXY (PercentBar.StartX, PercentBar.StartY + Count - 1, PercentBar.LoAttr, PercentBar.LoChar);

    Session.io.AnsiColor(7);
  End;

  If NoInput Then Exit;

  Update;

  LastWasChar := False;
  SearchStr   := '';

  If Assigned(SearchProc) Then
    SearchProc (Self, '');

  Repeat
    If Not LastWasChar Then Begin
      If Assigned(SearchProc) And (SearchStr <> '') Then
        SearchProc (Self, '');

      SearchStr := ''
    End Else
      LastWasChar := False;

    If List[Picked] <> NIL Then Begin
      If List[Picked]^.Name[1] = #2 Then
        CalculateMove(False, True);

      If List[Picked]^.Name[1] = #2 Then
        CalculateMove(True, True);
    End;

    If Assigned(StatusProc) Then
      If ListMax > 0 Then
        StatusProc(Picked, List[Picked]^.Name)
      Else
        StatusProc(Picked, '');

    Ch := Session.io.GetKey;

    If Session.io.IsArrow Then Begin
      Case Ch of
      #71 : If HasMore(True) <> - 1 Then Begin
                Picked  := 1;
                TopPage := 1;

                Update;
              End;
        #72 : CalculateMove(True, True);
        #73,
        #75 : If HasMore(True) <> - 1 Then Begin
                If Picked - WinSize > 1 Then Dec (Picked, WinSize) Else Picked := 1;
                If TopPage - WinSize < 1 Then TopPage := 1 Else Dec(TopPage, WinSize);

                Update;
              End;
        #79 : If HasMore(False) <> -1 Then Begin
                If ListMax > WinSize Then TopPage := ListMax - WinSize + 1;
                Picked := ListMax;

                Update;
              End;
        #80 : CalculateMove(False, True);
        #77,
        #81 : If HasMore(False) <> -1 Then Begin
                If ListMax > WinSize Then Begin
                  If Picked + WinSize > ListMax Then
                    Picked := ListMax
                  Else
                    Inc (Picked, WinSize);

                  Inc (TopPage, WinSize);

                  If TopPage + WinSize > ListMax Then TopPage := ListMax - WinSize + 1;
                End Else
                  Picked := ListMax;

                Update;
              End;
      Else
        If Pos(Ch, HiChars) > 0 Then Begin
          If SearchStr <> '' Then Begin
            SearchStr := '';

            If Assigned(SearchProc) Then
              SearchProc(Self, SearchStr);
          End;

          ExitCode := Ch;

          Exit;
        End;
      End;
    End Else
      If AllowTag and (Ch = TagKey) and (List[Picked]^.Tagged <> 2) Then Begin
        If (List[Picked]^.Tagged = 1) Then Begin
          Dec (List[Picked]^.Tagged);
          Dec (Marked);
        End Else Begin
          List[Picked]^.Tagged := 1;
          Inc (Marked);
        End;

        CalculateMove(False, True);
      End Else
      If Pos(Ch, LoChars) > 0 Then Begin
        If SearchStr <> '' Then Begin
          SearchStr := '';

          If Assigned(SearchProc) Then
            SearchProc(Self, SearchStr);
        End;

        ExitCode := Ch;

        Exit;
      End Else Begin
        If Ch <> #01 Then Begin
          If Ch = #25 Then Begin
            LastWasChar := False;
            Continue;
          End;

          If Ch = #8 Then Begin
            If Length(SearchStr) > 0 Then
              Dec(SearchStr[0])
            Else
              Continue;
          End Else
            If Ord(Ch) < 32 Then
              Continue
            Else
              SearchStr := SearchStr + UpCase(Ch);
        End;

        // Update dynamic search list otherwise do it this way

        SavedTop    := TopPage;
        SavedRec    := Picked;
        LastWasChar := True;
        First       := True;
        StartPos    := Picked + 1;
        EndPos      := ListMax;

        If Assigned(SearchProc) Then
          SearchProc(Self, SearchStr);

        If StartPos > ListMax Then StartPos := 1;

        Count := StartPos;

        While (Count <= EndPos) Do Begin
          If Pos(strUpper(SearchStr), strUpper(List[Count]^.Name)) > 0 Then Begin

            While Count <> Picked Do Begin
              If Picked < Count Then Begin
                If Picked < ListMax Then Inc (Picked);
                If Picked > TopPage + WinSize - 1 Then Inc (TopPage);
              End Else
              If Picked > Count Then Begin
                If Picked > 1 Then Dec (Picked);
                If Picked < TopPage Then Dec (TopPage);
              End;
            End;

            Break;
          End;

          If (Count = ListMax) and First Then Begin
            Count    := 0;
            StartPos := 1;
            EndPos   := Picked - 1;
            First    := False;
          End;

          Inc (Count);
        End;

        If TopPage <> SavedTop Then
          Update
        Else
        If Picked <> SavedRec Then Begin
          UpdateBar (X1 + 1, Y1 + SavedRec - SavedTop + 1, SavedRec, False);
          UpdateBar (X1 + 1, Y1 + Picked - TopPage + 1, Picked, True);

          UpdatePercent;
        End;
      End;
  Until False;
End;

Procedure TAnsiListBox.Close;
Begin
  If Not NoWindow Then Box.Close;
End;

Procedure TAnsiListBox.Add (Str : String; B : Byte);
Begin
  // exit if listmax=maxsize?

  Inc (ListMax);
  New (List[ListMax]);

  List[ListMax]^.Name    := Str;
  List[ListMax]^.Tagged  := B;

  If B = 1 Then Inc(Marked);
End;

Procedure TAnsiListBox.Get (Num : Word; Var Str : String; Var B : Boolean);
Begin
  Str := '';
  B   := False;

  If Num <= ListMax Then Begin
    Str := List[Num]^.Name;
    B   := List[Num]^.Tagged = 1;
  End;
End;

Procedure TAnsiListBox.SetSearchProc (P: TAnsiListBoxSearchProc);
Begin
  SearchProc := P;
End;

Procedure TAnsiListBox.SetStatusProc (P: TAnsiListBoxStatusProc);
Begin
  StatusProc := P;
End;

Procedure TAnsiListBox.SetUpdateProc (P: TAnsiListBoxUpdateProc);
Begin
  UpdateProc := P;
End;

Procedure TAnsiListBox.Sort (Left, Right: LongInt);

  Function Compare (ColDepth: Byte; Str1, Str2: String) : Boolean;
  Var
    Column1 : String;
    Column2 : String;
  Begin
    Column1 := strWordGet(SortDepth[ColDepth].Column, Str1, #0);
    Column2 := strWordGet(SortDepth[ColDepth].Column, Str2, #0);

    If Column1 = Column2 Then Begin
      If (ColDepth < 4) and (SortDepth[ColDepth + 1].Column <> 0) Then Begin
        Result := Compare(ColDepth + 1, Str1, Str2);

        Exit;
      End;
    End;

    Case SortDepth[ColDepth].Mode of
      sortAscending: Result := Column1 > Column2;
      sortDecending: Result := Column2 > Column1;
    End;
  End;

Var
  Temp   : TAnsiListBoxDataPTR;
  Pivot  : String;
  Lower  : LongInt;
  Upper  : LongInt;
Begin
  If ListMax = 0 Then Exit;

  Lower  := Left;
  Upper  := Right;
  Pivot  := List[(Left + Right) DIV 2]^.Name;

  Repeat
    While Compare(1, Pivot, List[Lower]^.Name) Do Inc (Lower);
    While Compare(1, List[Upper]^.Name, Pivot) Do Dec (Upper);

    If Lower <= Upper Then Begin
      Temp        := List[Lower];
      List[Lower] := List[Upper];
      List[Upper] := Temp;

      Inc (Lower);
      Dec (Upper);
    End;
  Until Lower > Upper;

  If Left  < Upper Then Sort(Left,  Upper);
  If Lower < Right Then Sort(Lower, Right);
End;












(************************************************)
(*

(*
Type
  TAnsiListBoxItemPTR = ^TAnsiListBoxItemRec;
  TAnsiListBoxItemRec = Record
    Name   : String[160];
    Tagged : Byte;
  End;

  TAnsiListBoxItems = Array[1..65000] of TAnsiListBoxItemPTR;

  TAnsiListBox = Class
    MaxListSize : LongInt;
    ListSize    : LongInt;
    FilterStr   : String;
    Data        : ^TAnsiListBoxItems;
    Box         : TAnsiMenuBox;
    Tagged      : LongInt;
    NoWindow    : Boolean;
    MaxPageSize : Byte;
    CurPageSize : Byte;
    CurPage     : Array[1..25] of LongInt;
    CurSelected : Byte;
    WinX1       : Byte;
    WinY1       : Byte;
    WinWidth    : Byte;
    PageFirst   : Boolean;
    PageLast    : Boolean;

    Constructor Create  (MaxSize: LongInt);
    Destructor  Destroy; Override;
    Procedure   AddItem (Str: String; Tag: Byte);
    Procedure   DeleteItem (RecPos: Cardinal);
    Procedure   ClearItems;
    Function    GetItemName (RecPos: LongInt) : String;
    Procedure   Open (X1, Y1, X2, Y2: Byte);
    Function    IsFirstPage : Boolean;
    Function    IsLastPage : Boolean;
    Procedure   ApplyFilter (Str: String);
    Procedure   BuildPage (PageStart: LongInt; Down: Boolean);
    Procedure   DrawPage;
    Procedure   DrawBar (X, Y: Byte; RecPos: LongInt; Selected: Boolean);
  End;

Constructor TAnsiListBox.Create (MaxSize: LongInt);
Begin
  FilterStr   := '';
  MaxListSize := MaxSize;
  ListSize    := 0;
  Tagged      := 0;
  NoWindow    := False;
  CurSelected := 1;
  Box         := TAnsiMenuBox.Create;

  If MaxListSize > 65000 Then MaxListSize := 65000;

  GetMem (Data, MaxListSize * SizeOf(Pointer));
End;

Destructor TAnsiListBox.Destroy;
Begin
  ClearItems;

  If Assigned(Data) Then FreeMem(Data);
  If Assigned(Box)  Then Box.Free;

  Inherited Destroy;
End;

Procedure TAnsiListBox.AddItem (Str: String; Tag: Byte);
Begin
  If ListSize = MaxListSize Then Exit;

  Inc (ListSize);

  New (Data[ListSize]);

  Data[ListSize]^.Name   := Str;
  Data[ListSize]^.Tagged := Tag;

  If Tag = 1 Then Inc(Tagged);
End;

Procedure TAnsiListBox.ClearItems;
Var
  Count : LongInt;
Begin
  For Count := ListSize DownTo 1 Do
    Dispose(Data[Count]);

  ListSize := 0;
  Tagged   := 0;
End;

Procedure TAnsiListBox.DeleteItem (RecPos: Cardinal);
Var
  Count : Cardinal;
Begin
  If RecPos > ListSize Then Exit;

  Dispose (Data[RecPos]);

  For Count := RecPos To ListSize - 1 Do
    Data[Count] := Data[Count + 1];

  Dec (ListSize);
End;

Function TAnsiListBox.GetItemName (RecPos: LongInt) : String;
Var
  CharPos : Byte;
Begin
  CharPos := Pos(#0, Data[RecPos]^.Name);

  If CharPos > 0 Then
    Result := Copy(Data[RecPos]^.Name, 1, CharPos - 1)
  Else
    Result := Data[RecPos]^.Name;
End;

Function  TAnsiListBox.IsFirstPage : Boolean;
Var
  Count : LongInt;
Begin
  Result := True;
  Count  := CurPage[1] - 1;

  While (Count >= 1) Do Begin
    If (FilterStr = '') or (Pos(FilterStr, GetItemName(Count)) > 0) Then Begin
      Result := False;

      Break;
    End;

    Dec (Count);
  End;
End;

Function  TAnsiListBox.IsLastPage : Boolean;
Var
  Count : LongInt;
Begin
  Result := True;
  Count  := CurPage[CurPageSize] + 1;

  If CurPageSize < MaxPageSize Then Exit;

  While (Count <= ListSize) Do Begin
    If (FilterStr = '') or (Pos(FilterStr, GetItemName(Count)) > 0) Then Begin
      Result := False;

      Break;
    End;

    Inc (Count);
  End;
End;

Procedure TAnsiListBox.BuildPage (PageStart: LongInt; Down: Boolean);
Var
  Count  : LongInt;
  Temp   : LongInt;
  Count2 : LongInt;
Begin
  Count       := PageStart;
  CurPageSize := 0;

  While (Count <= ListSize) and (Count >= 1) and (CurPageSize < MaxPageSize) Do Begin
    If (FilterStr = '') or (Pos(FilterStr, GetItemName(Count)) > 0) Then Begin
      Inc (CurPageSize);

      CurPage[CurPageSize] := Count;
    End;

    If Down Then
      Inc (Count)
    Else
      Dec (Count);
  End;

//  If (CurSelected > CurPageSize) or (CurSelected <= 0) Then
//    CurSelected := CurPageSize;

  If Not Down Then Begin
    Count2 := 1;

    For Count := CurPageSize DownTo 1 Do Begin
      Temp            := CurPage[Count2];
      CurPage[Count2] := CurPage[Count];
      CurPage[Count]  := Temp;

      Inc (Count2);

      If Count2 = Count Then Break;
    End;
  End;

  PageLast  := IsLastPage;
  PageFirst := IsFirstPage;
End;

Procedure TAnsiListBox.DrawBar (X, Y: Byte; RecPos: LongInt; Selected: Boolean);
Var
  Attr : Byte;
  Str  : String;
Begin
  If Selected Then
    Attr := 15 + 1 * 16
  Else
    Attr := 7;

  If RecPos <> -1 Then Begin
    Str := ' ' + GetItemName(RecPos) + ' ';
    Str := strPadR(Str, WinWidth, ' ');
  End Else
    Str := strRep(' ', WinWidth);

  WriteXY (X, Y, Attr, Str);
End;

Procedure TAnsiListBox.DrawPage;
Var
  Count  : Byte;
  CurRec : LongInt;
Begin
  If (CurSelected > CurPageSize) or (CurSelected <= 0) Then
    CurSelected := CurPageSize;

  For Count := 1 to MaxPageSize Do
    If Count <= CurPageSize Then
      DrawBar (WinX1, WinY1 + Count, CurPage[Count], Count = CurSelected)
    Else
      DrawBar (WinX1, WinY1 + Count, -1, False);
End;

Procedure TAnsiListBox.Open (X1, Y1, X2, Y2: Byte);
Var
  Ch : Char;
Begin
  If Not NoWindow Then
    Box.Open (X1, Y1, X2, Y2);

  WinX1       := X1 + 1;
  WinY1       := Y1;
  WinWidth    := X2 - X1 - 1;
  MaxPageSize := Y2 - Y1 - 1;

//  filterstr := '#8';
//filterstr := '8';
//filterstr :='asdfasdfas';
//filterstr := '#100';

  BuildPage(1, True);
  DrawPage;

  Repeat
    Ch := Session.io.GetKey;

    If Session.io.IsArrow Then Begin
      Case Ch of
        #71 : If PageFirst Then Begin
                If CurSelected > 1 Then Begin
                  DrawBar (WinX1, WinY1 + CurSelected, CurPage[CurSelected], False);

                  CurSelected := 1;

                  DrawBar (WinX1, WinY1 + CurSelected, CurPage[CurSelected], True);
                End;
              End Else Begin
                CurSelected := 1;
                BuildPage(1, True);
                DrawPage;
              End;
        #72 : If CurSelected > 1 Then Begin
                DrawBar (WinX1, WinY1 + CurSelected, CurPage[CurSelected], False);
                Dec     (CurSelected);
                DrawBar (WinX1, WinY1 + CurSelected, CurPage[CurSelected], True);
              End Else Begin
                If Not PageFirst Then Begin
                  BuildPage(CurPage[CurPageSize] - 1, False);

                  If CurPageSize <> MaxPageSize Then
                    BuildPage(1, True);

                  DrawPage;
                End;
              End;
        #73,
        #75 : If PageFirst Then Begin
                If CurSelected > 1 Then Begin
                  DrawBar (WinX1, WinY1 + CurSelected, CurPage[CurSelected], False);

                  CurSelected := 1;

                  DrawBar (WinX1, WinY1 + CurSelected, CurPage[CurSelected], True);
                End;
              End Else Begin
                BuildPage(CurPage[1] - 1, False);

                If CurPageSize < MaxPageSize Then
                  BuildPage(1, True);

                DrawPage;
              End;
        #77,
        #81 : If PageLast Then Begin
                If CurSelected < CurPageSize Then Begin
                  DrawBar (WinX1, WinY1 + CurSelected, CurPage[CurSelected], False);
                  CurSelected := CurPageSize;
                  DrawBar (WinX1, WinY1 + CurSelected, CurPage[CurSelected], True);
                End;
              End Else Begin
                BuildPage(CurPage[CurPageSize] + 1, True);

                If PageLast Then Begin
                  BuildPage (CurPage[CurPageSize], False);

                  CurSelected := CurPageSize;
                End;

                DrawPage;
              End;
        #79 : If PageLast Then Begin
                If CurSelected <> CurPageSize Then Begin
                  DrawBar (WinX1, WinY1 + CurSelected, CurPage[CurSelected], False);

                  CurSelected := CurPageSize;

                  DrawBar (WinX1, WinY1 + CurSelected, CurPage[CurSelected], True);
                End;
              End Else Begin
                While Not PageLast Do
                  BuildPage(CurPage[CurPageSize] + 1, True);

                BuildPage(CurPage[CurPageSize], False);

                CurSelected := CurPageSize;

                DrawPage;
              End;
        #80 : If CurSelected = CurPageSize Then Begin
                If Not PageLast Then Begin
                  BuildPage(CurPage[2], True);
                  DrawPage;
                End;
              End Else Begin
                DrawBar (WinX1, WinY1 + CurSelected, CurPage[CurSelected], False);
                Inc     (CurSelected);
                DrawBar (WinX1, WinY1 + CurSelected, CurPage[CurSelected], True);
              End;
      End;
    End Else
      Case Ch of
        #08 : If Length(FilterStr) > 0 Then Begin
                Dec(FilterStr[0]);
                ApplyFilter(FilterStr);
              End;
        #27 : Break;
        #32..
        #255 : Begin
                 FilterStr := FilterStr + UpCase(Ch);
                 ApplyFilter(FilterStr);
               End;
      End;
//    End;
   Until Session.Shutdown;
End;

Procedure TAnsiListBox.ApplyFilter (Str: String);
Begin
BuildPage(1, True);

//  BuildPage(CurPage[1], True);
//  If CurPageSize < MaxPageSize Then Begin
//    While Not PageFirst And (CurPageSize <> MaxPageSize) Do
//      BuildPage(CurPage[1] - 1, False);

//    If CurPageSize < MaxPageSize Then
//      BuildPage(1, True);
//  End;

  DrawPage;
End;
*)


End.
